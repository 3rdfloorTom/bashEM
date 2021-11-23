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
	echo "This scripts counts and reports the number of particles per halfset  for a given .star file."
	echo ""
	echo ""
	echo "Usage is:"
	echo ""
	echo "$(basename $0) -i input.star"
	echo ""
	echo "options list:"
	echo "	-i: .star following the RELION convention for particle metadata			(required)"
	echo ""
	exit 0
}

# check for any arguements at all
if [[ $# == 0 ]] ; then
	usage
fi

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

# Get halfset field number
subsetField=$(grep "_rlnRandomSubset" ${inStar} | awk '{print $2}' | sed 's|#||')


# Count halfset 1
halfset_A=$(awk -v set=$subsetField '{if ($0 ~ /.mrc/ && $set == "1") {print $0}}' ${inStar} | wc -l)
halfset_B=$(awk -v set=$subsetField '{if ($0 ~ /.mrc/ && $set == "2") {print $0}}' ${inStar} | wc -l)


# print count to terminal
echo ""
echo "Halfset-1 particle count:	${halfset_A}"
echo "Halfset-2 particle count:	${halfset_B}"
echo ""
echo "done!"
echo ""

exit 1
