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
	echo "This script takes a RELION-v3.1+ version particle.star referencing sub-tomogram projection images and reverts back to referencing the particle volumes."
	echo ""
	echo "This script will output a new {input}_revertTo3D.star file that references the original sub-tomogram volumes."
	echo ""
	echo ""
	echo "Usage is:"
	echo ""
	echo "$(basename $0) -i input_2Dproj.star "
	echo ""
	echo "options list:"
	echo "	-i: input particle.star						(required)"
	echo ""
	exit 0
}

# check for any arguements at all
if [[ $# == 0 ]] ; then
	usage
fi

#grab command-line arguements
#grab command-line arguements
while getopts ":i:" options; do
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
if [[ -z ${inStar} ]] ; then
	echo ""
	echo "Error: A particle.star must be provided!"
	echo ""
	exit
fi


# Generate output file name
outStar="${inStar%.*}_revertTo3D.star"

# Find the image field number
imField=$(grep "_rlnImageName" ${inStar} | awk '{print $2}' | sed 's|#||')
dimField=$(grep "_rlnImageDimensionality" ${inStar} | awk '{print $2}' | sed 's|#||')

if [[ -z $imField ]] || [[ -z $dimField ]]; then
	echo ""
	echo "Error: input .star file is missing one or more of the following fields: _rlnImageName, _rlnImageDimensionality"
	echo ""
	exit
fi

# Prepare header by grabbing all lines missing a reference to an image and switch dimensionality from 2 to 3
awk '{if ($0 !~ /.mrc/) {print $0}}' ${inStar} | awk -v dim=$dimField '{if (NF < 4) {print $0} else {$dim=3; print $0}}' > ${outStar}

# remove empty last line
sed -i '$ d' ${outStar}

# remove _2Dproj.mrc suffix and write to the output.star file
awk '{if ($0 ~/.mrc/) {print $0}}' ${inStar} | sed 's|_2Dproj.mrc||g' >> ${outStar}

echo ""
echo "Finished reverting input.star file."
echo ""
echo "Wrote out a new particle.star referencing the particle volumes: ${outStar}"
echo ""
echo "Script done!"
echo ""


exit 1


