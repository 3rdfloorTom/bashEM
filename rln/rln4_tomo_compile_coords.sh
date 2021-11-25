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
	echo "Compile a collection of coordinate.star files for import into RELION-v4"
	echo "NOTE: coordinate files must take form {TomoName}_{coordinate_suffix}.star"
	echo ""
	echo ""
	echo "Usage is:"
	echo ""
	echo "$(basename $0) /path/to/files/relative/to/project-directory/*_{coordinate_suffix.star}.star"
	echo ""
	echo "execute within the RELION-v4 project directory"
	echo ""
	exit 0
}

# check for any arguements at all
if [[ $# == 0 ]] ; then
	usage
fi

# read in glob of star files as an array
coords_list=("$@")

# check that list array is not empty
if ((${#coords_list[@]})) && [[ ${coords_list[0]} == *.star ]] ; then
	echo ""
	echo "Found some star files!"
	echo ""
else
	echo ""
	echo "Error: Could not find the specified star files in this directory"
	echo ""
	usage
fi

# make output star file
out_file="rln4_compiled_coords.star"

if (true) ; then
	
	echo ""
	echo "data_"
	echo ""
	echo "loop_"
	echo "_rlnTomoName #1"
	echo "_rlnTomoImportParticleFile #2"
	
fi > $out_file


# get length of list
list_length=${#coords_list[@]}

for ((i=0; i<${list_length}; i++)); do

	# basename of coordinate file
	tomon=$(basename ${coords_list[$i]})
	
	# remove suffix from file basename to yield tomogram name
	# keep the specified pathname to the coordinate file
	echo "${tomon%_*}	${coords_list[$i]}"
	
# redirect to compiled file
done >> $out_file

echo ""
echo "Finished compiling the coordinate.star file!"
echo "Make sure to check the output in $out_file"
echo "Script done!"
echo ""


exit
