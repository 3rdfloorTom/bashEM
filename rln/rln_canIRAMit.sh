#!/bin/bash
#
#
##########################################################################################################
#
# Author(s): Tom Laughlin University of California-San Diego 2020
#
# This script coverts between Fourier pixels and real-space resolution (in Angstroms) using shell commands.
#
#
###########################################################################################################

#usage description
usage () 
{
	echo ""
	echo "This script converts tells you whether you should load all particles into  RAM or onto SCRATCH."
	echo ""
	echo "Usage is:"
	echo ""
	echo "$(basename $0) [options]"
	echo ""
	echo "options list:"
	echo "	-p: particle star file			(required)"
	echo "	-b: box size in pixels			(required)"
	echo "	-m: number of MPI processes		(required)"
	echo ""
	exit 0
}

# check for any arguements at all
if [[ $# == 0 ]] ; then
	usage
fi

#grab command-line arguements
while getopts ":p:b:m:" options; do
    case "${options}" in
        p)
            if [[ -f ${OPTARG} ]] ; then
           		particleStar=${OPTARG}
           	else
           		echo ""
           		echo "Error: Could not find ${OPTARG}."
           		echo ""
           		usage
           	fi
            ;;
        b)
            if [[ ${OPTARG} =~ ^[0-9]+$ ]] ; then
           		boxSize=${OPTARG}
           	else
           		echo ""
           		echo "Error: box size must be a positive integer."
           		echo ""
           		usage
           	fi
            ;;
        m)
            if [[ ${OPTARG} =~ ^[0-9]+$ ]] ; then
           		numMPIs=${OPTARG}
           	else
           		echo ""
           		echo "Error: the number of MPI processes must be a postive integer."
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

# Check for required arguements

if [[ -z $particleStar ]] ; then
	echo ""
	echo "Error: the particle star file in question must be provided!"
	echo "Exiting..."
 	echo ""
	usage

fi

if [[ -z $numMPIs ]] || [[ -z $boxSize ]] ; then
	echo ""
	echo "Error: Both the number of MPI processes and the box size must be set!"
	echo ""
	usage
fi

# Check the total system RAM
sysRAM=$(free -g | awk '{if ($0 ~ /Mem:/) print $2}')

# Get particle count
particleCount=$( awk '{if ($0 ~/.mrc/) print $0}' $particleStar | wc -l)

# Calculate memory requirement
reqRAM=$(echo "4*$particleCount*$boxSize*$boxSize*$boxSize*$numMPIs/1024/1024/1024" | bc)

# Moment of truth
if [[ "$reqRAM" -lt "$sysRAM" ]] ; then
	echo ""
	echo "You could RAM it! (^.^)/ YAH!!"
	echo ""
else
	echo ""
	echo "You should probably SCRATCH it ... (-_-) *sigh*"
	echo ""
fi


exit 1
