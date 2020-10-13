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
	echo "This script estimates the target sampling-rate for reference projections using shell commands"
	echo ""
	echo "Usage is:"
	echo ""
	echo "$(basename $0) -a someNumber -r someBiggerNumber"
	echo ""
	echo "options list:"
	echo "	-a: nominal resolution (same units as particle radius)		(required)"
	echo "	-r: particle radius (same units as nominal resolution)		(required)"
	echo ""
	exit 0
}

# check for any arguements at all
if [[ $# == 0 ]] ; then
	usage
fi

#grab command-line arguements
while getopts ":a:r:" options; do
    case "${options}" in
        a)
            if [[ ${OPTARG} =~ ^[0-9]+([.][0-9]+)?$ ]] ; then
           		nomRes=${OPTARG}
            else
           		echo ""
           		echo "Error: Nominal resolution must be a positive number."
           		echo ""
           		usage
            fi
            ;;
        r)
            if [[ ${OPTARG} =~ ^[0-9]+([.][0-9]+)?$ ]] ; then
           		partRad=${OPTARG}
            else
           		echo ""
           		echo "Error: Particle radius must be a positive number."
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

## Check for required arguements
if [[ -z $nomRes ]] || [[ -z $partRad ]] ; then
	echo ""
	echo "Error: Nominal resolution and particle radius must be set!"
	echo ""
	usage
else
	# Compute ratio of nominal res and particle radius (arcLength/radius) and convert from radians to degrees
	samplingRate=$(echo "scale = 2; $nomRes/$partRad*57.3" | bc)  

	echo ""
	echo "At a resolution of ${nomRes} Ang, a particle with a radius of ${partRad} Ang requires an angular sampling-rate of at least ${samplingRate} degrees."
	echo ""
	echo "Script done!"

fi

exit
