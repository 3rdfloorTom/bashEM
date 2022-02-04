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
	echo "This scripts assigns the half-sets for a RELION starfile by micrograph/tomogram and tries to make them as even as possible given this constraint"
	echo "Important for when working with closely-packed/crystalline assemblies"
	echo ""
	echo "It will output input_split.star"
	echo ""
	echo "This script will not operate on files with a _rlnRandomSubset field already present."
	echo "Use the relion_star_handler to remove a _rlnRandomSubset field is present and still desiring to use this script."
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
	echo "Please remove it using the relion_star_handler if wishing to utilize this script."
	echo ""
	usage
fi


# Give output a name
outFile="${inStar%.*}_split.star"

# Make the new column at the end of the data_particles table loop
fieldNum=$(grep "_rln" ${inStar} | tail -n 1 | awk '{print $2}' | sed 's|#||')
((fieldNum++))

micField=$(grep "_rlnMicrographName" ${inStar} | awk '{print $2}' | sed 's|#||')

# use TomoName if micrograph name is not present
if [[ -z $micField ]] ; then
	micField=$(grep "_rlnTomoName" ${inStar} | awk '{print $2}' | sed 's|#||')
fi

# Prepare header by grabbing all lines missing a reference to an image
awk '{if ($0 !~ /.mrc/) {print $0}}' ${inStar} > ${outFile}
# remove empty last line
sed -i '$ d' ${outFile}
# add randomSubset column
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

printf "%s %65s %20s\n" "ImageName:" "Pctls:" "Halfset:"

# Get sorted file names
while IFS=" " read -r pctlCount tomoName remainder
do
	# Get present sizes of half-sets
	sizeA=$(wc -l $starA | awk '{print $1}')
	sizeB=$(wc -l $starB | awk '{print $1}')	


	# Determine which halfset is presently smaller and then fill it
	if [ $sizeA -lt $sizeB ] ; then
		awk '{print $0,1}' ${tomoName} >> ${starA} 
		halfSet=1	
	else
		awk '{print $0,2}' ${tomoName} >> ${starB}
		halfSet=2
	fi

	printf "%60s %15s %15s\n" $(basename $tomoName .star) $pctlCount $halfSet

done < "tmpDir/star_sizes.txt"

sizeA=$(wc -l ${starA})
sizeB=$(wc -l ${starB})
cat ${starA} >> ${outFile}
cat ${starB} >> ${outFile}

# Tidy-up
#rm -rf tmpDir

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
