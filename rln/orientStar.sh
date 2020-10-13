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
	echo "This scripts applies orientations a Relion prepare_subtomo.star based on a star file converted from Dynamo"
	echo ""
	echo "The relion star file is expected to have the order MicName,X,Y,Z,ImageName,CtfImage,Mag,Dpix"
	echo "The Dynamo generated star files is expected to have the column order X,Y,Z,Rot,Tilt,Psi,MicName"
	echo "Usage is:"
	echo ""
	echo "$(basename $0) -i extract.star -t table.star"
	echo ""
	echo "options list:"
	echo "	-i: .star generated from a Relion extraction job			(required)"
	echo "	-t: .star file generated by converion from a Dynamo table		(required)"
	echo ""
	exit 0
}

# check for any arguements at all
if [[ $# == 0 ]] ; then
	usage
fi

#grab command-line arguements
while getopts ":i:t:" options; do
    case "${options}" in
        i)
            if [[ -f ${OPTARG} ]] ; then
           		eStar=${OPTARG}
			echo ""
			echo "Found prepare_subtomo.star starfile: ${eStar}"
			echo ""
            else
           		echo ""
           		echo "Error: could not find prepare_subtomo.star starfile: ${eStar}"
           		echo ""
           		usage
            fi
            ;;
         t)
            if [[ -f ${OPTARG} ]] ; then
           		tStar=${OPTARG}
			echo "Found Dynamo table starfile: ${tStar}"
			echo ""
            else
           		echo ""
           		echo "Error: could not find Dynamo table starfile: ${tStar}"
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

# Give output a name
outFile="${eStar%.*}_oriented.star"

# Make header for output file (header lines don't contain image file extensions)
awk '{if ($0 !~ /.mrc/) {print $0}}' ${eStar} > ${outFile}
echo "_rlnAngleRot #9" >> ${outFile}
echo "_rlnAngleTilt #10" >> ${outFile}
echo "_rlnAnglePsi #11" >> ${outFile}

# Get the bodies of both files based on lines containing image file extensions (i.e., not header lines)
awk '{if ($0 ~ /.mrc/) {print $0}}' ${eStar} > "eStarHeadless.tmp"
awk '{if ($0 ~ /.rec/) {print $0}}' ${tStar} > "tStarHeadless.tmp"

particleCount=$(wc -l "eStarHeadless.tmp" | awk '{print $1}')


echo "The prepare_subtomo.star starfile ${eStar} contains ${particleCount} particle"
echo "Now performing Euler angle assignment this can take a minute, implementation is not the most optimal..."
echo "...just want to point out that it gets the job done nonetheless!"
echo ""

# While loop to read the relion starfile line by line and store the columns are variables
# Set a counter to know that everything went as planned

loopCount=0
while read -r starTomo starX starY starZ starImage starCtf starMag starPx remainder
do
	# The names may differ by the extension and the relion star will likely have the least amount of stuff on the end (i.e., no _DW_3Dctf_full.rec

	tomoRootName=$(basename $starTomo .mrc)
	
	# a mess off an awk script to match things based on tomo name and XYZ, then assign the Eulers
	awk 	-v tomo=$tomoRootName \
		-v starX=$starX \
		-v starY=$starY \
		-v starZ=$starZ \
      		-v starImage=$starImage \
		-v starCtf=$starCtf \
		-v starMag=$starMag \
		-v starPx=$starPx \
		'{if (($7 ~ tomo) && ($1 == starX) && ($2 == starY) && ($3 == starZ)) {print tomo,starX,starY,starZ,starImage,starCtf,starMag,starPx,$4,$5,$6;exit}}' "tStarHeadless.tmp" &
((loopCount++))
done < "eStarHeadless.tmp" >> ${outFile}
# all output appended to output starfile

# tidy-yp
rm "eStarHeadless.tmp"
rm "tStarHeadless.tmp"

echo "Finished assigning Euler angles."
echo "The oriented starfile has been written out as ${outFile} and contained ${loopCount} particles."
echo "Script done!"
echo ""