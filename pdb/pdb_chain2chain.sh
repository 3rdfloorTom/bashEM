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
:
#usage description
usage () 
{
	echo ""
	echo "This script takes a .pdb format coordinate file which has continous residue indices and lacks chain IDs,"
	echo "a cognate .pdb format file with per chain residue indices and chain IDs,"
	echo "and a list of resn + indices for the continous scheme that one wishes to map to the per chain scheme based in identical XYZ positions."
	echo ""
	echo "This script was written with a specific use case in mind, but might be generally useful (?, sorry if that is indeed your case)."
	echo ""
	echo "NOTE: this script is not very robust and can fail spectacularly if the formatting of the .pdb is corrupted."
	echo ""
	echo "Usage is:"
	echo ""
	echo "$(basename $0) -i continous_indices.pdb -m not_continous_indices.pdb -l list_of_resn_indices_to_map.txt"
	echo ""
	echo "options list:"
	echo "	-i: input .pdb following the continous residue indexing scheme."
	echo "	-m: input .pdb following a per-chain residue indexing scheme."
	echo "	-l: a list of resn + index of the continous scheme to map to the per chain scheme."
	echo ""
	exit 0
}

# check for any arguements at all
if [[ $# == 0 ]] ; then
	usage
fi

#grab command-line arguements
while getopts ":i:m:l:" options; do
    case "${options}" in
        i)
            if [[ -f ${OPTARG} ]] ; then
           		conPDB=${OPTARG}
			echo ""
			echo "Found specified coordinate file: ${conPDB}"
			echo ""
            else
           		echo ""
           		echo "Error: could not find specified coordinate file: ${conPDB}"
           		echo ""
           		usage
            fi
            ;;
         m)
            if [[ -f ${OPTARG} ]] ; then
           		notConPDB=${OPTARG}
			echo ""
			echo "Found specified coordinate file: ${notConPDB}"
			echo ""
            else
              		echo ""
           		echo "Error: could not find specified coordinate file: ${notConPDB}"
           		echo ""
           		usage
            fi
            ;;
         l)
            if [[ -f ${OPTARG} ]] ; then
           		inResIdx=${OPTARG}
			echo "Found list of residue indices: ${inResIdx}"
			echo ""
            else
           		echo ""
           		echo "Error: could not find list of residue indices: ${inResIdx}"
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

if [[ -z ${conPDB} ]] || [[ -z ${notConPDB} ]] || [[ -z ${inResIdx} ]] ; then

	echo ""
	echo "One of the input files is not set!"
	echo "All 3 are required for the script to run."
	echo "Exiting..."
	usage

fi

# Give output a name
outResIdx="${inResIdx%.*}_reIndex.txt"

if [[ -f ${outResIdx} ]] ; then
	echo ""
	echo "A ${outResIdx} already exists!"
	echo "Renaming as ${outResIdx}.bak"
	echo ""

	mv ${outResIdx} "${outResIdx}.bak"
fi

# For sanity check later
inResCount=$(wc -l ${inResIdx} | awk '{print $1}')

echo ""
echo "Input residue indices to map: ${inResCount}"
echo "running..."
echo ""

# Loop over indices
while read -r resi idx remainder
do
	# pull XYZ coordinates from concatenated file
	coords=$(awk -v res=$resi -v idx=$idx '{if ( ($5 == idx) && ($4 == res) ) {print $6,$7,$8}}' ${conPDB} | head -n 1)
	
	# use XYZ coordinates from above to pull relevant line from non-concatenated pdb
	# I hate doing this, but be damned it is convenient in this context	
	resn=$(grep "${coords}" ${notConPDB} | awk '{print $4}')
	chain=$(grep "${coords}" ${notConPDB} | awk '{print $5}')
	reIdx=$(grep "${coords}" ${notConPDB} | awk '{print $6}')

	echo "(chain ${chain} and resi ${reIdx} and resn ${resn})"

done < ${inResIdx} > ${outResIdx} 

wait

# the sanity check that all residues were mapped
outResCount=$(wc -l ${outResIdx} | awk '{print $1}')
echo "Output residue indices mapped: ${outResCount}"

echo ""
echo "Make sure to check whether the number of input and mapped indices mapped"
echo ""
echo "Script done!"
echo ""
