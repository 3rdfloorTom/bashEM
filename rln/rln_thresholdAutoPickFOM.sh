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
	echo "This script thresholds a RELION style autopick star file by the Figure of Merit (FOM)."
	echo "It will out put a thresholded star file named input_thresh.star"
	echo ""
	echo "Usage is:"
	echo ""
	echo "$(basename $0) -i input.star -l minimumFOM -h maximumFOM"
	echo ""
	echo "options list:"
	echo "	-i: .star generated from a RELION/Warp template matching run			(required)"
	echo "	-l: lowest value (inclusive) of FOM allowed to be included in output starfile	(required)"
	echo "	-h: high value (exclusive) of FOM allowed to be included in output starfile	(required)"
	echo ""
	exit 0
}

# check for any arguements at all
if [[ $# == 0 ]] ; then
	usage
fi

#grab command-line arguements
while getopts ":i:l:h:" options; do
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

	 l)
	    if [[ ${OPTARG} =~ ^[0-9]+([.][0-9]+)?$ ]] ; then
			threshLow=${OPTARG}
	    else
			echo ""
			echo "Error: Threshold must be a postive value."
			echo "Exiting..."
			echo ""
			usage
	    fi
	    ;;

	 h)
	    if [[ ${OPTARG} =~ ^[0-9]+([.][0-9]+)?$ ]] ; then
			threshHigh=${OPTARG}
	    else
			echo ""
			echo "Error: Threshold must be a postive value."
			echo "Exiting..."
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

# Check inputs
if [[ -z $inStar ]] ; then

	echo ""
	echo "Error: No star file provided!"
	echo "Exiting..."
	echo ""
	usage	
	
fi

if [[ -z $threshLow ]] || [[ -z $threshHigh ]] ; then
	echo ""
	echo "Error: Threshold not set!"
	echo "Exiting..."
	echo ""
	usage
fi

if [[ -z $(grep "_rlnAutopickFigureOfMerit" ${inStar}) ]] ; then

	echo ""
	echo "Error: Input file does not contain a _rlnAutopickFigureOfMerit column...not much to do here."
	echo "Exiting..."
	echo ""
	usage
fi

# Give output a name
outFile="${inStar%.*}_thresh.star"

# Get FOM field
fomField=$(grep "_rlnAutopickFigureOfMerit" ${inStar} | awk '{print $2}' | sed 's|#||')

# Grab header (lines without .mrc in them)
awk '{if ($0 !~ /.mrc/) {print $0}}' ${inStar} > ${outFile}

# Threshold FOM field and output to new file (sort so it is ease to tell the thresholding later by top and bottom values)
awk -v fom=$fomField -v threshL=$threshLow -v threshH=$threshHigh '{if ($0 ~ /.mrc/ && ($fom >= threshL && $fom < threshH)) {print $0}}' ${inStar} | sort -nr -k$fomField >> ${outFile}

# Determine the pre/post thresholding particle counts
preCount=$(grep ".mrc" $inStar | wc -l | awk '{print $1}')
postCount=$(grep ".mrc" $outFile | wc -l | awk '{print $1}')

echo "Selected particles with FOMs between: $threshLow $threshHigh"
echo ""
echo "Pre-threshold count of particles:	${preCount}"
echo "Post-threshold count of particles: 	${postCount}"
echo ""
echo "A star file sorted by the AutopickFOM has been written out as:" 
echo "${outFile}"
echo ""
echo "Script done!"
echo ""

exit 1
