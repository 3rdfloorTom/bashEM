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
	echo "Creates a list tilt-movie names from a glob of mdocs"
	echo "Note: this script require dos2unix to be installed for mdoc sanitation."
	echo "Usage is:"
	echo ""
	echo "$(basename $0) *.mdoc"
	echo ""
	echo "executed within directory containing the mdocs"
	echo ""
	exit 0
}

# check for any arguements at all
if [[ $# == 0 ]] ; then
	usage
fi

# defaults
frames_list="movie_list.txt"

# array of mdocs
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

# get length of list
list_length=${#mdoc_list[@]}

for ((i=0; i<${list_length}; i++)); do
			 
	dos2unix ${mdoc_list[$i]}
	grep SubFramePath ${mdoc_list[$i]} | awk '{print $3}' | awk -F '\' '{print $NF}'	

# redirect mapping to file
done > $frames_list

echo ""
echo "Movie list compiled!"
echo "Written out as $frames_list"
echo "Script done!"
echo ""


exit
