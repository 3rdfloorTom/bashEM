#!/bin/bash
#
#
##########################################################################################################
#
# Author(s): Tom Laughlin University of California-San Diego 2020
#
# 
#
###########################################################################################################

#usage description
usage () 
{
	echo ""
	echo "This script generates a directory 'relion2D' for running Class2D in RELION-3.0 of template-matched data from Warp-v1.09"
	echo "It takes a reconstruction directory, matching directory, and coordinate suffix."
	echo ""
	echo "NOTE: The assumption is that only one set of binned tomograms has been generated in the reconstruction directory."
	echo ""
	echo "Usage is:"
	echo ""
	echo "	$(basename $0) -r /path/to/reconstruction -m /path/to/matching/ -s coordinate_suffix.star"
	echo ""
	echo "options list:"
	echo "	-r: Warp reconstruction directory containing tomograms					(required)"
	echo "	-m: Warp matching directory containing the coordinate.star files			(required)"
	echo "	-s: Suffix of the coordinate files (include the ending '.star')				(required)"
	exit 0
}

# check for any arguements at all
if [[ $# == 0 ]] ; then
	usage
fi

#grab command-line arguements
while getopts ":r:m:s:" options; do
    case "${options}" in
        r)
            if [[ -d ${OPTARG} ]] ; then
           		reconDir=${OPTARG}
				
			echo ""
			echo "Found reconstruction directory:	${reconDir}"
			echo ""
				
            else
           		echo ""
           		echo "Error: could not find specified reconstruction directory!"
           		echo ""
           		usage
            fi
            ;;
        m)
            if [[ -d ${OPTARG} ]] ; then
           		matchDir=${OPTARG}
			
			echo ""
			echo "Found input matching directory:	${matchDir}"
			echo ""
				
            else
           		echo ""
           		echo "Error: could not find specified matching directory!"
           		echo ""
           		usage
            fi
            ;;
		 
	s)
	    coordSuffix=${OPTARG}
	    ;;

        *)
	            usage
            ;;
    esac
done
shift "$((OPTIND-1))"

# Check for set inputs
if [[ -z ${reconDir} ]] || [[ -z ${matchDir} ]] ; then
	
	echo ""
	echo "One of the input directories is not set!"
	echo "Both the directories are required inputs"
	echo "Exiting..."

	usage
	
fi

# Check if tomograms exist
tomoList=$(ls $reconDir/*.mrc)
if [[ -z $tomoList ]] ; then
	echo ""
	echo "Error: $reconDir does not contain any tomograms in .mrc format!"
	echo "Exiting.."
	echo ""
fi

# Check if coordinate files exist
if [[ -z $(ls $matchDir/*$coordSuffix) ]] ; then
	echo ""
	echo "Error: $matchDir does not contain any coordinates with suffix $coordSuffix!"
	echo "Exiting.."
	echo ""
fi

# Output directories
outDir="relion2D"

# Output tomo list
tomoStar="${outDir}/rln_tomos_${coordSuffix%.*}.star"

# Make output directory
if [[ -d ${outDir} ]] ; then
	
	echo ""
	echo "A pre-existing ${outDir} has been found."
	echo "Output will be written there"
	echo ""
else
	mkdir ${outDir}
fi

# Get the tomogram dimensions from representative tomo for scaling Warp coordinates
checkTomo=$(echo $tomoList | awk '{print $1}' )
dimX=$(header -s ${checkTomo} | awk '{print $1}')
dimY=$(header -s ${checkTomo} | awk '{print $2}')
dimZ=$(header -s ${checkTomo} | awk '{print $3}')

# Make an output directory for tomogram links
for i in $tomoList; do

	# Parse tomogram name 
	tomoName=$(basename ${i})
	
	# Make tomogram specific directory
	mkdir -p "${outDir}/Tomograms/${tomoName%.mrc}"
	
	# Soft-link to tomograms
	ln -s $(realpath $i) "${outDir}/Tomograms/${tomoName%.mrc}/$tomoName"
	
	awk -v dimX=$dimX \
		-v dimY=$dimY \
		-v dimZ=$dimZ \
		'{if ($0 ~/mrc/) {print $1*dimX,$2*dimY,$3*dimZ} } ' $matchDir/${tomoName%.mrc}_$coordSuffix > "${outDir}/Tomograms/${tomoName%.mrc}/${tomoName%.mrc}_ASCII.coords"

	# Coordinate count
	count=$(wc -l "${outDir}/Tomograms/${tomoName%.mrc}/${tomoName%.mrc}_${coordSuffix%.star}.coords" | awk '{print $1}')	

	echo "Wrote out ${count} coordinates for ${tomoName}"

done

# Make the tomogram star file
echo "data_" > ${tomoStar}
echo "loop_" >> ${tomoStar}
echo "_rlnMicrographName" >> ${tomoStar}
ls "${outDir}/Tomograms/"*"/"*.mrc | sed -r "s:\x1B\[[0-9;]*[mK]]::g" | sed "s|${outDir}/||g" >> ${tomoStar}

echo ""
echo "Finished writing coordinate files and linking all tomograms to ${outDir}/ for use in RELION"
echo ""
echo "Also wrote out ${tomoStar} for use in RELION-3.0"
echo ""
echo ""
echo "Import Tomograms/*/*_${coordSuffix%.star}.coords as a particle coordinates Node-type"
echo ""
echo "Extract Z-projections using the ${tomoStar} and the imported coordinates."
echo "		* Manually set the pixel size."
echo "		* Note that contrast may already be invert."
echo "		* Make sure to ddd the additional arguement --project3d in the Running tab."
echo ""
echo "Perform Class2D with CTF-correction disabled."
echo "Extract sub-tomograms of selected classes in Warp."
echo ""
echo "Script done!"
echo ""

exit 1
