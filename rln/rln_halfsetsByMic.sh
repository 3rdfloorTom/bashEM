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
	echo "This scripts assigns the half-sets for a RELION-3.0 starfile by micrograph/tomogram and tries to make them as even as possible given this constraint"
	echo "Important for when working with closely-packed/crystalline assemblies"
	echo ""
	echo "This script is not too smart and just assigns rlnRandomSubset to the last field."
	echo "It will get very upset if there is already a rlnRandomSubset field in the file."
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

if [[ ! -z $(grep "_rlnRandomSubset" ${inStar}) ]] ; then

	echo ""
	echo "Input file already contains a rlnRandomSubset field!"
	echo "Use a starfile where this parameter has not yet been assigned or risk biasing your future reconstructions!"
	echo ""
	usage
fi


# Give output a name
outFile="${inStar%.*}_split.star"

# Make the new column at the end
fieldNum=$(grep "_rln" ${inStar} | wc -l)
((fieldNum++))

micField=$(grep "_rlnMicrographName" | awk '{print $2}' | sed 's|#||')

# Prepare header
awk '{if ($0 !~ /.mrc/) {print $0}}' ${inStar} > ${outFile}
echo "_rlnRandomSubset #${fieldNum}" >> ${outFile} 

if [[ ! -d tmpDir ]] ; then
   echo ""
   echo "Creating tmpDir to write intermediate files to"
   echo ""
   mkdir tmpDir
else
	# Clear previous intermediate files if present
	rm "tmpDir/"*.txt
	rm "tmpDir/"*.star
fi

echo ""
echo "Writing intermediate files to tmpDir"
echo ""

awk '{if ($0 ~ /.mrc/) {print $0}}' ${inStar} > "tmpDir/inStarBody.txt"

# Find all unique micrograph names
awk -v micField=$micField '{print $micField}' "tmpDir/inStarBody.txt" | sort | uniq > "tmpDir/uniqTomos.txt"

# Split the original starfile body by tomogram (better way to do this with arrays probabl
while IFS=" " read -r tomo remainder
do
	awk -v tomo=${tomo} -v micField=$micField '{if ($micField == tomo) {print $0}}' "tmpDir/inStarBody.txt" > "tmpDir/$(basename $tomo .mrc*).star" 

done < "tmpDir/uniqTomos.txt"

# Get list of total particles in each tomo and sort the list
wc -l "tmpDir/"*.star | sort -rk1 -n > "tmpDir/star_sizes.txt"

# Get total particles
totalPctls=$(head -n 1 "tmpDir/star_sizes.txt" | awk '{print $1}')

# Remove first line from sizes file
sed -i 1d "tmpDir/star_sizes.txt"

# Make intermediate starfile bodies
starA="tmpDir/halfSetA.star"
starB="tmpDir/halfSetB.star"

touch ${starA}
touch ${starB}

# Get sorted file names
while IFS=" " read -r pctlCount tomoName remainder
do
	# Get present sizes of half-sets
	sizeA=$(wc -l ${starA})
	sizeB=$(wc -l ${starB})

	# Determine which halfset is presently smaller and then fill it
	if [[ ${sizeA} < ${sizeB} ]] ; then
		awk '{print $0,1}' ${tomoName} >> ${starA} 	
	else
		awk '{print $0,2}' ${tomoName} >> ${starB}
	fi

done < "tmpDir/star_sizes.txt"

sizeA=$(wc -l ${starA})
sizeB=$(wc -l ${starB})
cat ${starA} >> ${outFile}
cat ${starB} >> ${outFile}

echo ""
echo "Finished writing out ${outFile} which contains ${totalPctls} particles."
echo ""
echo "RandomSubset 1 contains ${sizeA} particles."
echo "RandomSubset 2 contains ${sizeB} particles."
echo ""
echo "Intermediate files can be found in tmpDir"
echo "Script done!"
echo ""

exit 1
