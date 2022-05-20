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

#usage description
usage () 
{
	echo ""
	echo "This script takes a RELION-4 star file and RELION-3'ish' star file for import into Warp-v1.09 and/or M"
	echo "That is, it removes the optics table and converts the shifts from Angstroms to pixels."
	echo ""
	echo "NOTE: It assumes all the data is of the same pixel size and the coordinates are unbinned."
	echo ""
	echo "It will output input_rln3ish_data.star"
	echo ""
	echo "Usage is:"
	echo ""
	echo "$(basename $0) -i input.star -p pixelSize"
	echo ""
	echo "options list:"
	echo "	-i: RELION-4 .star file generated from a refinement job			(required)"
	echo "	-p: Pixel size of data in Angstroms					(required)"
	echo ""
	exit 0
}

# check for any arguements at all
if [[ $# == 0 ]] ; then
	usage
fi

#grab command-line arguements
while getopts ":i:p:" options; do
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

	 p)
	    if	[[ ${OPTARG} =~ ^[0-9]+([.][0-9]+)?$ ]] ; then
			pxSize=${OPTARG}
			echo ""
			echo "Using input pixel size of: $pxSize"
			echo ""
	    else
			echo ""
			echo "Error: Input pixel size must be a postive value!"
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

if [[ -z $(grep "data_optics" ${inStar}) ]] ; then

	echo ""
	echo "Input file does not contain an RELION-v4-style optics table."
	echo "I can't work with this!"
	echo "Exiting..."
	echo ""
	exit 0
fi

if [[ -z ${pxSize} ]] ; then
	echo ""
	echo "Error: a pixel size has not be provided!"
	echo "Exiting..."
	echo ""
	exit 0
fi

# Give output a name
outFile="${inStar%.*}_rln3ish_${pxSize}Apx_data.star"

# Get field numbers for shifts
oriX_ang=$(grep "_rlnOriginXAngst" ${inStar} | awk '{print $2}' | sed 's|#||')
oriY_ang=$(grep "_rlnOriginYAngst" ${inStar} | awk '{print $2}' | sed 's|#||')
oriZ_ang=$(grep "_rlnOriginZAngst" ${inStar} | awk '{print $2}' | sed 's|#||')

oriX=$(grep "_rlnOriginX " ${inStar} | awk '{print $2}' | sed 's|#||')
oriY=$(grep "_rlnOriginY " ${inStar} | awk '{print $2}' | sed 's|#||')
oriZ=$(grep "_rlnOriginZ " ${inStar} | awk '{print $2}' | sed 's|#||')

tomo=$(grep "_rlnTomoName" ${inStar} | awk '{print $2}' | sed 's|#||')

# Take all lines after match and divide angstrom shifts by pixel size before printing to new file
sed -n '/^data_particles$/,$p' ${inStar} | awk 	 -v oriX_ang=$oriX_ang \
						 -v oriY_ang=$oriY_ang \
						 -v oriZ_ang=$oriZ_ang \
						 -v oriX=$oriX \
						 -v oriY=$oriY \
						 -v oriZ=$oriZ \
						 -v pxSize=$pxSize \
						 -v tomo=$tomo \
						 '{if ($0 ~ /.mrc/) {$oriX=$oriX_ang/pxSize ; $oriY=$oriY_ang/pxSize ; $oriZ=$oriZ_ang/pxSize; $tomo=$tomo".tomostar"; print $0} else print $0}' > ${outFile}
				
# Edit some data loop and field names
sed -i 's|data_particles|data_|' ${outFile}
sed -i 's|_rlnTomoName|_rlnMicrographName|' ${outFile}

echo ""
echo "Finished writing out: ${outFile}"
echo "Ready for extraction in Warp-v1.09/import into M!"
echo ""
echo "Script done!"
echo ""

exit 1
