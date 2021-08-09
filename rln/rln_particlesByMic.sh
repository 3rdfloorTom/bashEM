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
	echo "This scripts counts and reports the number of particles per-micrograph/tomogram for a given .star file."
	echo ""
	echo "It will output a text file with the counts"
	echo ""
	echo "Usage is:"
	echo ""
	echo "$(basename $0) -i input.star"
	echo ""
	echo "options list:"
	echo "	-i: .star generated from an extraction job			(required)"
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

# Get micrograph field number
micField=$(grep "_rlnMicrographName" ${inStar} | awk '{print $2}' | sed 's|#||')

# Split the original starfile body by tomogram (better way to do this with arrays probably)
while IFS=" " read -r tomo remainder
do
	# count the number of lines containing the tomogram name
	pctl_count=$(awk -v tomo=${tomo} -v micField=$micField '{if ($0 ~/.mrc/ && $micField == tomo) {print $0}}' ${inStar} | wc -l)
	echo "$tomo 		$pctl_count"	

done < <(awk '{if ($0 ~ /.mrc/) {print $0}}' ${inStar} | awk -v micField=$micField '{print $micField}' | sort | uniq) > "${inStar%.star}_particlesPerMic.txt"
# a nasty awk redirect

# print count to terminal
echo ""
cat "${inStar%.star}_particlesPerMic.txt"
echo ""
echo "Output count file: " "${inStar%.star}_particlesPerMic.txt"
echo ""
echo "done!"

exit 1
