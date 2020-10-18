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
	echo "This scripts parses a Dynamo .tbl based on a RELION .star of the same data."
	echo "It takes a .star, a .tbl, and a .doc."
	echo ""
	echo "The expectation is the .star is from a Select job after Class2D Relion."
	echo "Usage is:"
	echo ""
	echo "$(basename $0) -i select.star -t original.tbl -d originalColumn20.doc"
	echo ""
	echo "options list:"
	echo "	-i: .star generated from a Relion Select job on Class2D output		(required)"
	echo "	-t: .tbl used in generating the .star used for Class2D			(required)"
	echo "	-d: indiciesColumn20.doc, the tomogram index for the Dynamo .tbl	(required)"
	echo ""
	exit 0
}

# check for any arguements at all
if [[ $# == 0 ]] ; then
	usage
fi

#grab command-line arguements
while getopts ":i:t:d:" options; do
    case "${options}" in
        i)
            if [[ -f ${OPTARG} ]] ; then
           		inStar=${OPTARG}
			echo ""
			echo "Found select.star starfile: ${inStar}"
			echo ""
            else
           		echo ""
           		echo "Error: could not find select.star starfile: ${inStar}"
           		echo ""
           		usage
            fi
            ;;
         t)
            if [[ -f ${OPTARG} ]] ; then
           		inTbl=${OPTARG}
			echo "Found Dynamo table: ${inTbl}"
			echo ""
            else
           		echo ""
           		echo "Error: could not find Dynamo table: ${inTbl}"
           		echo ""
           		usage
            fi
            ;;
         d)
            if [[ -f ${OPTARG} ]] ; then
           		tomoIdx=${OPTARG}
			echo "Found tomogram index file: ${tomoIdx}"
			echo ""
            else
           		echo ""
           		echo "Error: could not find tomogram index file: ${tomoIdx}"
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

if [[ -z ${inStar} ]] || [[ -z ${inTbl} ]] || [[ -z ${tomoIdx} ]] ; then

	echo ""
	echo "One of the input files is not set!"
	echo "All 3 are required for the script to run."
	echo "Exiting..."
	usage

fi

# Give output a name
outTbl="${inTbl%.*}_select.tbl"

if [[ -f ${outTbl} ]] ; then
	echo ""
	echo "A ${outTbl} already exists!"
	echo "Renaming as ${outTbl}.bak"
	echo ""

	mv ${outTbl} "${outTbl}.bak"
fi

# Get starfile body
awk '{if ($0 ~ /mrc/) {print $0}}' ${inStar} > "starBody.tmp"

starCount=$(wc -l "starBody.tmp" | awk '{print $1}')

echo ""
echo "Looping through star and table files for ${starCount} particle positions, this can take a while..."
echo "Output supressed from the loop to speed-up things up a bit."
echo "Check (h)top in another tab if you are concerned that the script may have frozen."
echo ""

while read -r starX starY starZ starImage starMic remainder
do
	tomoRootName=$(basename $starMic .mrc)
	
	# Get index from .doc
	Idx=$(grep ${tomoRootName} ${tomoIdx} | awk '{print $1}')	
		
	# Match up coordinates and tomograms between table and starfile
	# Dynamo uses center of voxel coordinates, so need to add the 0.5 to each XYZ coord

	awk 	-v Idx=$Idx \
		-v starX=$starX \
		-v starY=$starY \
		-v starZ=$starZ \
		'{if ( ($20 == Idx) && ($24 == (starX+0.5) ) && ($25 == (starY+0.5) ) && ($26 == (starZ+0.5)) ) {print $0; exit}}' ${inTbl} & 

done < "starBody.tmp" > ${outTbl}

tblCount=$(wc -l ${outTbl} | awk '{print $1}')

# Tidy-up
rm "starBody.tmp"

echo ""
echo "Finished selecting particles from the input Dynamo table based on the input starfile."
echo ""
echo "The output Dynamo table has been written out as ${outTbl} containing ${tblCount} particles positions."
echo ""
echo "Script done!"
echo ""
