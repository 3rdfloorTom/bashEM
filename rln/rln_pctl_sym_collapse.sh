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
	echo "This scripts takes a particle.star file that has been fully symmetry expanded and collapses to a specified Cn symmetry"
	echo "The Cn symmetry-axis must also already be aligned to the Z-axis."
	echo ""
	echo ""
	echo "It will output:	{input}_C{c}.star"
	echo ""
	echo ""
	echo "Usage is:"
	echo ""
	echo "$(basename $0) -i particles_expanded.star -c #"
	echo ""
	echo "options list:"
	echo "	-i: .star generated from an extraction job			(required)"
	echo "	-c: 'n' of the target Cn sym for the output .star file		(required)"
	echo ""
	exit 0
}

# check for any arguements at all
if [[ $# == 0 ]] ; then
	usage
fi

#grab command-line arguements
while getopts ":i:c:" options; do
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

	c)
	    if	[[ ${OPTARG} =~ ^[0-9]+$ ]] ; then
		
			cyc_sym=${OPTARG}
			echo ""
			echo "Target cyclic symmetry is: C${cyc_sym}"
			echo ""	
	    else
			echo ""
			echo "Error: target cyclic symmetry must be a positive integer."
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

# Check for target symmetry input
if [[ -z ${cyc_sym} ]] ; then

	echo ""
	echo "Error: target cyclic symmetry must be specified."
	echo ""
	usage
fi

# Check the input star file is not empty and matches expected size
pctlCount=$(awk '{ if ($0 ~ /.mrc/)  {print $0}}' ${inStar}| wc -l) 
remainder=$(($pctlCount % $cyc_sym))

if [[ $pctlCount -eq 0 ]] || [[ $remainder -ne 0 ]] ; then

	echo ""
	echo "Error: input .star file does not contain in interger multiple of the target cyclic symmetry."
	echo "Input particle count: $pctlCount"
	echo "Target symmetry: C$cyc_sym"
	echo ""
	usage
fi 

# State input particle count for sanity checks
echo ""
echo "Input particle count is: $pctlCount"
echo ""

# Generate output file name
outFile="${inStar%.*}_C$cyc_sym.star"

# Find requisite data field numbers
tiltField=$(grep "_rlnAngleTilt" ${inStar} | awk '{print $2}' | sed 's|#||')
psiField=$(grep "_rlnAnglePsi" ${inStar} | awk '{print $2}' | sed 's|#||')
imField=$(grep "_rlnImageName" ${inStar} | awk '{print $2}' | sed 's|#||')

if [[ -z $tiltField ]] || [[ -z $psiField ]] || [[ -z $imField ]] ; then
	echo ""
	echo "Error: input .star file is missing one or more of the following fields: _rlnAngleTilt, _rlnAnglePsi, _rlnImageName"
	echo ""
	usage
fi

# Prepare header by grabbing all lines missing a reference to an image
awk '{if ($0 !~ /.mrc/) {print $0}}' ${inStar} > ${outFile}

# remove empty last line
sed -i '$ d' ${outFile}

echo ""
echo "Collapsing symmetry (this can take a minute for large files)..."
echo ""

# Here comes the wild part...strap-in!!!!
# mapfile an array containing 'n' number of lines
while mapfile -t -n $cyc_sym starLines && ((${#starLines[@]})) ;
do
	randIdx=$(($RANDOM % $cyc_sym))
	echo "${starLines[$randIdx]}"

done < <(awk '{if ($0 ~ /.mrc/) {print $0}}' ${inStar} | sort -k${tiltField},${tiltField}g -k${psiField},${psiField}g -k${imField},${imField}) >> ${outFile}  

# sort lines by last 2 Euler angles and image name.
# inside the while loop, send a random pick from the groups of 'n'  particle replicates (the 'n' replicates share the same last 2 Euler angles)
# the redirect is to prevent writing an intermediate file to disk and the fact that it is not possible to pipe into mapfile.


# Get final particle count for sanity check
finalCount=$(awk '{if ($0 ~ /.mrc/) {print $0}}' ${outFile} | wc -l)

echo ""
echo "Finished writing symmetry collapsed file:		${outFile}"
echo "Particle count after symmetry collapse is:		${finalCount}"
echo ""
echo "Script done!"
echo ""

exit 1
