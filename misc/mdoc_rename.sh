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
	echo "Renumber mdoc files with 0-padded numbering with a given offset."
	echo "also, write out a list file with key mapping of old names to new numbers"
	echo ""
	echo "All output is written to separate directory: renumbered_mdocs"
	echo ""
	echo "Usage is:"
	echo ""
	echo "$(basename $0) [-o numerical_offset] *.mdoc"
	echo ""
	echo "executed within directory containing the mdocs"
	echo "options list:"
	echo "	-o: offset to apply in renumbering files			(optional, default 0)"
	echo ""
	exit 0
}

# check for any arguements at all
if [[ $# == 0 ]] ; then
	usage
fi

# defaults
offset=0
out_dir="renumbered_mdocs"
key_list="mdoc_index_key.txt"

#grab command-line arguements
while getopts "o:" options; do
    case "${options}" in
        o)
            if [[ ${OPTARG} =~ ^[0-9]+$ ]] ; then
           		offset=${OPTARG}
            else
           		echo ""
           		echo "Error: offset must be a positive integer."
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
mdoc_list=("$@")

# check that list array is not empty
if ((${#mdoc_list[@]})); then
	echo ""
	echo "Found some mdocs!"
	echo ""
else
	echo ""
	echo "Error: Could not find mdocs in this directory"
	echo ""
	usage
fi

# create output directory
if [[ ! -d $out_dir ]] ; then
	echo ""
	echo "Creating directory $out_dir for output mdocs"
	echo ""
	mkdir $out_dir
else
	echo ""
	echo "Clearing previous entries in $out_dir"
	echo ""
	rm $out_dir/*
fi

# get length of list
list_length=${#mdoc_list[@]}

for ((i=0; i<${list_length}; i++)); do
			
	# prepare index
	ts_index=$(printf "%03d" $offset)

	# copy mdoc to new name in the output directory 
	cp ${mdoc_list[$i]} $out_dir/"TS_${ts_index}.mdoc"
	
	# store name mapping
	echo "TS_${ts_index}.mdoc	${mdoc_list[$i]}"
	
	# increment offset
	((offset++))
	
# redirect mapping to file
done > $out_dir/$key_list

echo ""
echo "Finished renaming!"
echo "Make sure to check the output in $out_dir"
echo "Script done!"
echo ""


exit