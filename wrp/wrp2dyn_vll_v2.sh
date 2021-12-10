#!/bin/bash
#
#
##########################################################################################################
#
# Author(s): Tom Laughlin University of California-San Diego 2021
#
# 
#
###########################################################################################################

# usage description
usage () 
{
	echo ""
	echo "This script takes a Warp directory containing reconstructions (regular and deconvolved) and their tomostars and makes a .vll for use in Dynamo"
	echo "If deconvolved tomograms are to be included, the .vll will be as such that cropping will be from the non-deconvoled tomograms (i.e., deconvolved are just for visualization in Dynamo catalogue)"
	echo ""
	echo "Note: the expectation is that tomogram names take the form {something}_###_##.##Apx.mrc, where ### is the index and ##.## the reconstructed pixel size."
	echo "Also, assume tilt-axis is y"
	echo ""
	echo "Usage is:"
	echo ""
	echo "$(basename $0) -i <path/to/warp/dir> -p <pixel_size> -o <output rootname> "
	echo ""
	echo "options list:"
	echo "	-i: /path/to/warp/dir						(required)"
	echo "	-p: pixel size in target tomogram names	(include trailing 0's)	(required)"
	echo "	-o: rootname for output.vll					(required)"
	echo "	-d: invoke to include deconvolved reconstruction in .vll	(optional)"
	echo ""
	exit 0
}

# check for any arguements at all
if [[ $# == 0 ]] ; then
	usage
fi

#grab command-line arguements
while getopts ":i:p:o:d" options; do
    case "${options}" in
	
	i)  if [[ -d ${OPTARG} ]] ; then
			wrpDir=${OPTARG}
	    else
			echo ""
			echo "Cannot find the specified Warp directory."
			echo ""
			usage
	    fi
	    ;;

	p)  if [[ ${OPTARG} =~ ^[0-9]+([.][0-9]+)?$ ]] ; then
			apix=${OPTARG}

	    else 
			echo ""
			echo "Pixel size must be a postive number."
			echo ""
			usage
	    fi
	
	    ;;

  	o) rootname=${OPTARG}
	    ;;


        d) useDecon=true
            ;;
        *)
            usage
            ;;
    esac
done
shift "$((OPTIND-1))"

echo ""
echo "Running $(basename $0).."
echo ""

## Check for required arguements
if [[ -z $wrpDir ]] ; then
	echo ""
	echo "Error: A Warp directory must be provided."
	echo "Exiting..."
	usage
fi

if [[ -z $apix ]] ; then
	echo ""
	echo "Error: A pixel size must be provdied."
	echo "Exiting..."
	echo ""
fi

# Set reconstruction directory
reconDir=${wrpDir}"/reconstruction"

## Check for reconstruction folder
if [[ ! -d $reconDir ]] || [[ -z "$(ls -A $reconDir)" ]] ; then
	echo ""
	echo "Error could not locate reconstruction directory or it is empty."
	echo "Exiting..."
	usage
fi

## Check for deconvolution usage setting, if not set make it false. Else, check for directories
if [[ -z $useDecon ]] ; then
	useDecon=false
else
	# Set deconvolution directory
	deconDir=${reconDir}"/deconv"
	useDecon=true
	if [[ ! -d $deconDir ]] || [[ -z "$(ls -A $deconDir)" ]] ; then
		echo ""
		echo "Error: Deconvolution directory was not found or is empty."
		echo "Proceeding without."
		useDecon=false
	fi
fi

## Check for rootname for output volume list
if [[ -z $rootname ]] ; then
	echo ""
	echo "Error: no rootname as provided."
	echo "Setting rootname name to wrpCat."
	rootname="wrpCat"
fi

outputList=$rootname".vll"
outputDoc=$rootname"_indices_column20.doc"

# remove existing list if present
if [[ -f $outputList ]] ; then
	rm $outputList
fi

if [[ -f $outputDoc ]] ; then
	rm $outputDoc
fi

# Loop over tomostars to get a list of tomograms
for i in  ${wrpDir}/*.tomostar; 
do

	starFile=$i
	
	#Get rootname of tomogram
	tomoRootName=$(basename $starFile .tomostar)
	tomoFullName=$reconDir/$tomoRootName"_"${apix}Apx.mrc
	
	index=$(echo ${tomoRootName##*_} | sed 's|^0*||') 	
	
	# check for tomogram
	if [ -f $tomoFullName ] ; then	
		echo ""
		echo "Working on adding ${tomoFullName} to the volume list."
	else
		echo ""
		echo "Could not locate ${tomoFullName}, skipping..."
		continue
	fi
	
	
	# Get tilt extents
	posExt=$(awk '{if (NF > 2) {print $2}}' $starFile | head -n 1)
	negExt=$(awk '{if (NF > 2) {print $2}}' $starFile | tail -n 1)
	
	if [ $useDecon == "true" ] ; then 
 		deconFullName=$deconDir/${tomoRootName}_${apix}Apx.mrc
	        echo $(realpath $deconFullName)
		echo "* cropFromFile = "$(realpath $tomoFullName)
		echo "* cropFromElsewhere = 1"
		echo "* index = ${index}"
		echo "* label = ${tomoRootName}"
		echo "* apix = $apix"
		echo "* ytilt = $negExt $posExt"
		echo "* ftype = 1"
		echo ""
	else
		echo $(realpath $tomoFullName)
		echo "* index = ${index}"
		echo "* label = $tomoRootName"
		echo "* apix = $apix"
		echo "* ytilt = $negExt $posExt"
		echo "* ftype = 1"
		echo ""
	fi >> $outputList

	echo "$index	$(realpath $tomoFullName)" >> $outputDoc
		
done

echo ""
echo "Wrote out the volume list: ${outputList}"
echo "Wrote volume index Col-20: ${outputDoc}"
echo "Ready for import into a Dynamo catalogue for particle picking and cropping"
echo ""
echo "Just use: dcm -create name_of_catalogue -fromvll ${outputList}"
echo ""
echo "Script done!"
echo ""


exit 1


