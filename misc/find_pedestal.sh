#!/bin/bash
#
#
##########################################################################################################
#
# Author(s): Tom Laughlin Altos Labs 2026
#
# 
#
###########################################################################################################

#usage description
usage () 
{
	echo ""
	echo "Use the IMOD clip stats function to find the minimum value in a glob of .mrc images to suggest a suitable pedestal value"
	echo "Note: this script requires IMOD functions to be on the PATH."
	echo "Usage is:"
	echo ""
	echo "$(basename $0) *.mrc"
	echo ""
	echo ""
	exit 0
}

# check for any arguements at all
if [[ $# == 0 ]] ; then
	usage
fi

# array of images to consider
image_list=("$@")

# check that list array is not empty
if ((${#image_list[@]})); then
	echo ""
	echo "Found ${#image_list[@]} images!"
	echo ""
else
	echo ""
	echo "Error: Could not find images in this directory"
	echo ""
	usage
fi

echo "Now doing some calculations..."

# initialize current minimum outside of loop
curr_min=0

# loop through and update the current minimum if a new minimum is found
for ((i=0; i<${#image_list[@]}; i++)); do
	tmp=$(clip stats ${image_list[$i]} | tail -n 1 | awk '{print $2}')

	if (( ${tmp%.*} < $curr_min )) ; then
		curr_min=${tmp%.*}
	fi
done

echo ""		
echo "Minimum value from input of images: ${curr_min}"
echo "Suggested pedestal value for images: ${curr_min#-}"
echo ""
echo "Done!"

