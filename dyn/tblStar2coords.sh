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
	echo "This scripts breaks up a star file generated from Dynamo table into seperate .coord files"
	echo ""
	echo "Usage is:"
	echo ""
	echo "$(basename $0) -i inputTable.star [options]"
	echo ""
	echo "options list:"
	echo "	-i: .star file generated from dynamo table			(required)"
	echo "	-o: output directory for .coord files				(optional, default is subtomoCoords)"
	echo "	-e: extension to remove from tomogram name			(optional, default is .rec)"
	echo ""
	exit 0
}

# check for any arguements at all
if [[ $# == 0 ]] ; then
	usage
fi

#grab command-line arguements
while getopts ":i:o:e:" options; do
    case "${options}" in
        i)
            if [[ -f ${OPTARG} ]] ; then
           		inStar=${OPTARG}
			echo ""
			echo "Found input:	${inStar}"
			echo ""
            else
           		echo ""
           		echo "Error: could not find ${inStar}"
           		echo ""
           		usage
            fi
            ;;
        o)
            outDir=${OPTARG}
            ;;

	e)  extension=${OPTARG}
	    ;;
        *)
	            usage
            ;;
    esac
done
shift "$((OPTIND-1))"

# If create output directory if necessary (there is likely a better way to do this...)
if [[ -z ${outDir} ]] ; then

	echo ""
	echo "Output directory is not specified."
	echo ""	

	if [[ -d "subtomoCoords" ]] ; then
	
		echo ""
		echo "A pre-existing subtomoCoords directory was found and will be used to store output."
		echo ""
		outDir="subtomoCoords"	
	else
		outDir="subtomoCoords"
		echo ""
		echo "Creating default output directory ${outDir}"
		echo ""

		mkdir ${outDir}
	fi

elif [[ -d ${outDir} ]] ; then
	
	echo ""
	echo "A pre-existing ${outDir} directory was found and will be used to store output."
	echo ""
else
	echo ""
	echo "Creating output directory ${outDir}"
	echo ""
	
	mkdir ${outDir}
fi


if [[ -z ${extension} ]] ; then

	echo ""
	echo "No extension specified, assuming it is simply .rec"
	
	extension=".rec"
else
	echo ""
	echo "The specified tomogram name extension is ${extension}"
fi	
	echo "This will be removed from the .coords file name."
	echo ""

# Remove the file header
awk -v ext=${extension} '{if ($7 ~ext) {print $0}}' ${inStar} > "${outDir}/starBody.tmp"

# Get list of unique tomogram names

awk '{print $7}' "${outDir}/starBody.tmp" | uniq | sed "s|${extension}||g" > "${outDir}/tomoNames.tmp"
# Get number of unique tomogram names
count=$(wc -l "${outDir}/tomoNames.tmp" | awk '{print $1}')

# Loop over names and print out coordinate files
for i in $(cat ${outDir}/tomoNames.tmp) ;
do
	tomoRoot=$(basename $i)

	# if a line contains the tomo name, print the coordinates to a coords file for that tomo
	awk -v tomo=${i} '{if ($7 ~tomo) {print $1,$2,$3}}' ${inStar} > "${outDir}/${tomoRoot}.coords"
	echo ""
	echo "Printed coordinates for ${i} to ${outDir}/${i}.coords"
	echo ""
done

# Tidy-up
rm "${outDir}/starBody.tmp"
rm "${outDir}/tomoNames.tmp"


echo ""
echo "Finished printing coordinate files for ${count} tomograms to ${outDir}/"
echo "Script done!"
echo ""

exit 1
