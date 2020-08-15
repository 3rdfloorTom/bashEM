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
	echo "This script acts on a Dynamo .tbl file to apply the shifts to the particle positions"
	echo "and optionally upsampling/unbin the particle positions"
	echo "Usage is:"
	echo ""
	echo "$(basename $0) -i inputTable.tbl -s number"
	echo ""
	echo "options list:"
	echo "	-i: input table				(required)"
	echo "	-s: scaling factor for up-sampling	(optional)"
	echo ""
	exit 0
}

# check for any arguements at all
if [[ $# == 0 ]] ; then
	usage
fi

#grab command-line arguements
while getopts ":i:s:" options; do
    case "${options}" in
        i)
            if [[ -f ${OPTARG} ]] ; then
           		inTbl=${OPTARG}
            else
           		echo ""
           		echo "Error: could not find ${inTbl}"
           		echo ""
           		usage
            fi
            ;;
        s)
            if [[ ${OPTARG} =~ ^[0-9]+$ ]] ; then
           		scaleFactor=${OPTARG}
            else
           		echo ""
           		echo "Error: factor for rescaling must be a positive integer."
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

# Get file rootname and make outfile
rootName=${inTbl%.tbl}

if [[ -z scaleFactor ]] ; then
	outTbl=${rootName}"_shifted.tbl"
	scaleFactor=1
else
	outTbl=${rootName}"_shifted_rescaled.tbl"
fi

# Likely much easier in matlab, but what ever
# AWK's gonna AWK
awk -v scale=${scaleFactor} '{print $1,$2,$3,0,0,0,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,($24+$4)*scale,($25+$5)*scale,($26+$6)*scale,$27,$28,$29,$30,$31,$32,$33,$34,$35}' ${inTbl} > ${outTbl}

echo ""
echo "Finished shifting (& maybe rescaling) the input table."
echo ""
echo "Wrote out the new table file as:	${outTbl}"
echo ""
echo "That's it, script's done."
echo ""
exit 1
