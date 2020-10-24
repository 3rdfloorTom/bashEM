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
	echo "This script takes a RELION-3.1 star file and RELION-3'ish' star file for import into Warp-v1.09"
	echo "That is, it removes the optics table and converts the shifts from Angstroms to pixels."
	echo ""
	echo "NOTE: It assumes all the data is of the same pixel size."
	echo ""
	echo "It will output input_rln3ish.star"
	echo ""
	echo "Usage is:"
	echo ""
	echo "$(basename $0) -i input.star -p pixelSize"
	echo ""
	echo "options list:"
	echo "	-i: RELION-3.1 .star file generated from a refinement job			(required)"
	echo "	-p: Pixel size of data in Angstroms						(required)"
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
	echo "Input file does not contain an RELION-3.1-style optics table."
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
outFile="${inStar%.*}_rln3ish.star"

# Get field numbers for shifts
oriX=$(grep "_rlnOriginXAngst" ${inStar} | awk '{print $2}' | sed 's|#||')
oriY=$(grep "_rlnOriginYAngst" ${inStar} | awk '{print $2}' | sed 's|#||')
oriZ=$(grep "_rlnOriginZAngst" ${inStar} | awk '{print $2}' | sed 's|#||')

# Take all lines after match and divide angstrom shifts by pixel size before printing to new file
sed -n '/^data_particles$/,$p' ${inStar} | awk -v oriX=$oriX -v oriY=$oriY -v oriZ=$oriZ -v pxSize=$pxSize '{if ($0 ~ /.mrc/) {$oriX=$oriX/pxSize ; $oriY=$oriY/pxSize ; $oriZ=$oriZ/pxSize; print $0} else print $0}' > ${outFile}

# Edit some data loop and field names
sed -i 's|data_particles|data_|' ${outFile}
sed -i 's|_rlnOriginXAngst|_rlnOriginX|' ${outFile}
sed -i 's|_rlnOriginYAngst|_rlnOriginY|' ${outFile}
sed -i 's|_rlnOriginZAngst|_rlnOriginZ|' ${outFile}

echo ""
echo "Finished writing out ${outFile} ready for extraction in Warp-v1.09."
echo ""
echo "Script done!"
echo ""

exit 1
