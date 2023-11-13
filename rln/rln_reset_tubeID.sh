#!/bin/bash
#
#
##########################################################################################################
#
# Author(s): Tom Laughlin 2023
#
# 
#
###########################################################################################################

#usage description
usage () 
{
	echo ""
	echo "This scripts takes a particle.star with the _rlnMicrographName and _rlnHelicalTubeID fields."
	echo "It renumbers the HelicalTubeIDs to be from 1-N within a micrograph"
	echo ""
	echo "NOTE: useful for TubeIDs originating from cryoSPARC which are too long for RELION to handle"
	echo ""
	echo "It will output:	{input}_resetTubeIDs.star"
	echo ""
	echo ""
	echo "Usage is:"
	echo ""
	echo "$(basename $0) -i particles.star"
	echo ""
	echo "options list:"
	echo "	-i: particle.star containing _rlnMicrographName and _rlnHelicalTubeID fields			(required)"
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

# Generate output file name
outStar="${inStar%.*}_resetTubeIDs.star"

# Find requisite data field numbers
micField=$(grep "_rlnMicrographName" ${inStar} | awk '{print $2}' | sed 's|#||')
tubeField=$(grep "_rlnHelicalTubeID" ${inStar} | tail -n -1 | awk '{print $2}' | sed 's|#||')


# check for micrograph field
if [[ -z $micField ]] ; then
	echo ""
	echo "Error: input .star file is missing the _rlnMicrographName field"
	echo ""
	usage
fi

# check for tubeID field
if [[ -z $tubeField ]] ; then
	echo ""
	echo "Error: input .star file is missing the _rlnHelicalTube field"
	echo ""
	usage
fi


# Time to get goofy :P
awk -v tubeField=$tubeField -v micField=$micField'
BEGIN {
	# initializing variables
	micname_prev='None'
	micname_current='None'
	tubeID_prev='None'
	tubeID_current='None'
	counter=1
} # close begin

# file operation
{
	if ($0 ~/.mrc/)	# operate only on lines with references to micrographs
	{
		micname_current=$micField
		tubeID_current=$tubeField

		if (micname_current == micname_prev)
		{
			if (tubeID_current != tubeID_prev)
			{
				counter++	# increment counter for new tube
			}
		}

		else
		{
			counter=1 	# reset counter for new micrographs
		}

	} # close if
	
	$tubeField=counter
	micname_prev=micname_current
	tubeID_prev=tubeID_current

	print $0
	
} # close file operation

END {
} # close end

' ${inStar} >> ${outStar}

echo ""
echo "Finished reseting the tubeIDs to file:	${outStar}"
echo ""
echo ""
echo "Script done!"
echo ""

exit 1
