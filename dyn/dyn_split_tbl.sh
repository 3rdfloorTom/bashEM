#!/bin/bash
#
###############################################################################
#
# 	Thomas 'Tom' G. Laughlin
#	University of California, San Diego
#	 2020
#
# 	Probably a better way of doing this in matlab/pandas but I don't care!
#
###############################################################################

# Usage description
usage () 
{
	echo ""
	echo "This script uses shell commands to split a Dynamo table by a tomo/region into nearly equal "even-odd" half-sets"
	echo "The intent is to avoid splitting particles from the same densely-sampled model across the half-sets, which would inflate the FSC." 
	echo ""
	echo "Usage is:"
	echo ""
	echo "		$(basename $0) -i input.tbl [options]"
	echo ""
	echo "options list:"
	echo "		-i: Dynamo table for splitting							(required)"
	echo "	        -o: Output rootname (default, 'table_initial_ref')				(optional)"
	echo ""
	exit 0
}

# If no arguements, return usage
if [[ $# == 0 ]] ; then
	usage
fi

# Default output name
outNameRoot="table_initial_ref"

while getopts ":i:o:" options; do
    case "${options}" in
        i)
            if [[ -f ${OPTARG} ]] ; then
           		inTable=${OPTARG}
           		echo ""
           		echo "Found:	 ${inTable}"
                 	echo ""
           	else
           		echo ""
           		echo "Error: Cannot find file named:	 ${inTable}"
           		echo "exiting..."
           		echo ""
           		usage
           	fi
            ;;
        o)
	    outNameRoot=${OPTARG}

            ;;
        *)
            usage
            ;;
    esac
done
shift "$((OPTIND-1))"

# Check width of table, if it is of use later
tableWidth=$(awk '{print NF;exit}' ${inTable})

# Check for exisiting outputs and move to bak if necessary
outTableA=${outNameRoot}"_001.tbl"
outTableB=${outNameRoot}"_002.tbl"

if [[ -f ${outTableA} ]] ; then
	
	echo ""
	echo "Found pre-existing '${outTableA}'"
	echo "	Moving to '${outTableA}.bak'"
	echo ""
	
	mv ${outTableA} ${outTableA}".bak"	
fi

if [[ -f ${outTableB} ]] ; then
	
	echo ""
	echo "Found pre-existing '${outTableB}'"
	echo "	Moving to '${outTableB}.bak'"
	echo ""
	
	mv ${outTableB} ${outTableB}".bak"
fi

# Make a directory for intermediate files

dirName="splitTomoRegTbls"

echo ""
echo "Will write intermediate tbl files to ${dirName}"

if [[ ! -d ${dirName} ]] ; then

	echo ""
	echo "Making directory ${dirName} ..."
	echo ""	
	
	mkdir ${dirName}
fi



# Find all unique indices for specified column
cut -f20,21 -d" " ${inTable} | sort | uniq > "uniqueFieldsList.tmp"

# Remove old intermedite tables
if [[ -f  "${dirName}/"*.tbl ]] ; then
	rm "${dirName}/"*.tbl
fi

# Write out new intermediate tables, split by the tomo and region fields
# While loop reads file line by line storing first and second fields in tomo and region (buffer is to catch trailing formatting chars)
while read -r tomo region buffer
do
	awk -v tomo=${tomo} -v region=${region} '{if ($20 == tomo && $21 == region) {print $0}}' ${inTable} > "${dirName}/tomo_${tomo}_region_${region}.tbl"
	
done < "uniqueFieldsList.tmp"

# Get list of total tags in each intermediate table
wc -l "${dirName}/"*.tbl | sort -rk1 -n > "table_sizes.tmp"

# Save total tag count for later
totalTags=$(head -n 1 table_sizes.tmp | awk '{print $1}')

# Remove total count line from file
sed -i 1d "table_sizes.tmp"

# Store sorted file names for later
awk '{print $2}' "table_sizes.tmp"  > "sorted_table_names.tmp"

# Now to divy up the tables...

echo ""
echo "Now splitting original ${totalTags} into two tables"
echo "Splitting evenly as one can given column criterion."

# This is to just make terminal vomit prettier
for ((i = 0; i < 10; i++))
do
	echo "."
done

# Initialize table files
touch ${outTableA}
touch ${outTableB}

# Loop over sorted table file and always try to add to the smaller table
for i in $(cat sorted_table_names.tmp)
do
	# Get present sizes of tables
	sizeA=$(wc -l ${outTableA})
	sizeB=$(wc -l ${outTableB})

	# Determine which table is smaller and fill it by appending the table in this iteration
	if [[ ${sizeA} < ${sizeB} ]] ; then
		cat ${i} >> ${outTableA}
	else
		cat ${i} >> ${outTableB}
	fi
done

particlesA=$(wc -l ${outTableA})
particlesB=$(wc -l ${outTableB})

echo "............................................................................................."
echo "Finished writing out split tables."
echo ""
echo "Table ${outTableA} contains ${particlesA} particle tags."
echo ""
echo "Table ${outTableB} contains ${particlesB} particle tags"
echo ""
echo "Intermediate, individual tables per column specifier can be found in ${dirName}"
echo "............................................................................................."

# clean up tmp files
rm "uniqueFieldsList.tmp"
rm "table_sizes.tmp"
rm "sorted_table_names.tmp"

exit 1
