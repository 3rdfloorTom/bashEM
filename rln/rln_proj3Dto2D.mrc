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
	echo "This script takes a RELION-v3.1+ version sub-tomogram particle.star file and uses IMOD's clip to generate 2D projection images."
	echo "The semi-height is IN PIXELS NOT ANGSTROMS!"
	echo ""
	echo "This script will output a new {input}_2Dproj.star file that can be used for Class2D runs in RELION with CTF-correction disabled."
	echo ""
	echo "NOTE:	This script should to be run from the RELION project directory"
	echo ""
	echo "Usage is:"
	echo ""
	echo "$(basename $0) -i input_subtomogram.star -s semi-height "
	echo ""
	echo "options list:"
	echo "	-i: input particle.star						(required)"
	echo "	-s: semi-height to define the central sections to be projected  (required, in pixels)"
	echo ""
	exit 0
}

# check for any arguements at all
if [[ $# == 0 ]] ; then
	usage
fi

#grab command-line arguements
#grab command-line arguements
while getopts ":i:s:" options; do
    case "${options}" in
        i)
            if [[ -f ${OPTARG} ]] ; then
          
	 		inStar=${OPTARG}
			echo ""
			echo "Found input starfile: ${inStar}"
			echo ""
            else
           		echo ""
           		echo "Error: could not input starfile: ${inStar}"
           		echo ""
           		usage
            fi
            ;;

	s)
	    if	[[ ${OPTARG} =~ ^[0-9]+$ ]] ; then
		
			semiHeight=${OPTARG}
			echo ""
			echo "Semi-height in pixels:	${semiHeight}"
			echo ""	
	    else
			echo ""
			echo "Error: The semi-height must be a positive integer."
			echo ""	
			usage
	    fi

	    ;;
	
        *)
	   	        usage
            ;;
    esac
done
shift "$((OPTIND-1))"

echo ""
echo "Running $(basename $0)..."
echo ""

# Check inputs
if [[ -z ${semiHeight} ]] ; then

	echo ""
	echo "Error: A semi-height (in pixels) must be specified."
	echo ""
	exit
fi

if [[ -z ${inStar} ]] ; then
	echo ""
	echo "Error: A particle.star must be provided!"
	echo ""
	exit
fi


# Generate output file name
outStar="${inStar%.*}_2Dproj.star"

# Find the image field number
imField=$(grep "_rlnImageName" ${inStar} | awk '{print $2}' | sed 's|#||')
dimField=$(grep "_rlnImageDimensionality" ${inStar} | awk '{print $2}' | sed 's|#||')

if [[ -z $imField ]] || [[ -z $dimField ]]; then
	echo ""
	echo "Error: input .star file is missing one or more of the following fields: _rlnImageName, _rlnImageDimensionality"
	echo ""
	exit
fi

# Get image size
imSize=$(header $(awk -v imField=$imField '{if ($0 ~ /.mrc/) {print $imField}}' ${inStar} | head -n 1) -size | awk '{print $1}')

# Prepare header by grabbing all lines missing a reference to an image and switch dimensionality from 3 to 2
awk '{if ($0 !~ /.mrc/) {print $0}}' ${inStar} | awk -v dim=$dimField '{if (NF < 4) {print $0} else {$dim=2; print $0}}' > ${outStar}

# remove empty last line
sed -i '$ d' ${outStar}

# add _proj.mrc suffix to the image field and write to the output.star file
awk -v imField=$imField '{if ($0 ~/.mrc/) {$imField=$imField"_2Dproj.mrc"; print $0}}' ${inStar} >> ${outStar}

# Set bounds based on image size and semi-height
imMid=$((imSize/2))
high=$((imMid+semiHeight))
low=$((imMid-semiHeight))

# Project sub-tomograms
echo ""
echo "Projecting sub-tomograms from slices $low to $high using IMOD's clip function"
echo ""
while read subVol;
do
	echo "Working on:	$subVol"
	clip avg -2d -iz $low-$high $subVol ${subVol}_2Dproj.mrc 

done < <(awk -v imField=$imField '{if ($0 ~ /.mrc/) {print $imField}}' ${inStar})

echo ""
echo "Finished projecting sub-tomograms!"
echo ""
echo "Wrote out a new particle.star for the projections: ${outStar}"
echo ""
echo "Script done!"
echo ""


exit 1


