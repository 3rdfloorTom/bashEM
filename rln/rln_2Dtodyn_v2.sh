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
:
#usage description
usage () 
{
	echo ""
	echo "This scripts parses a Dynamo .tbl based on a RELION particle.star generated from the same data."
	echo "It takes a particle.star, a .tbl, and a .doc."
	echo ""
	echo "The expectation is the particle.star is from a Select job after Class2D RELION."
	echo ""
	echo "NOTE: the columns 17-19 in the .tbl should be 60 0 0, respectively. This allows reliable use of grep, which makes 'v2' slightly faster..."
	echo "Usage is:"
	echo ""
	echo "$(basename $0) -i particle.star -t original.tbl -d originalColumn20.doc"
	echo ""
	echo "options list:"
	echo "	-i: particle.star generated from a Relion Select job on Class2D output      (required)"
	echo "	-t: .tbl used in generating the .star used for Class2D                      (required)"
	echo "	-d: indiciesColumn20.doc, the tomogram index for the Dynamo .tbl            (required)"
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
	
	# Remove trailing 0's on RELION particle positions
	starX=${starX%.*}
	starY=${starY%.*}
	starZ=${starZ%.*}
	
	# Add the leading '60 0 0' for a cheat to use grep, which is faster than conditional matching with AWK
	grep "60 0 0 $Idx.*$starX.*$starY.*$starZ.*" ${inTbl} &

done < "starBody.tmp" > ${outTbl}

wait

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
