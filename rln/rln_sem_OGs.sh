#!/bin/bash
#
#
##########################################################################################################
#
# Author(s): Tom Laughlin University of California-San Diego 2022
#
# 
#
###########################################################################################################

#usage description
usage () 
{
	echo ""
	echo "This scripts takes a particle.star with micrograph names following the SerialEM image-shift naming convention"
	echo "It will output a particle.star assigning optics groups based on the unique image-shift groups."
	echo ""
	echo "NOTE: Assumes 1) SerialEM _X#+Y#-#-#.mrc file endings"
	echo "		    2) Only one optics group named opticsGroup1 in the optics table"
	echo ""
	echo "It will output:	{input}_sem_OGs.star"
	echo ""
	echo ""
	echo "Usage is:"
	echo ""
	echo "$(basename $0) -i particles_expanded.star"
	echo ""
	echo "options list:"
	echo "	-i: particle.star containing SerialEM convention rlnMicrographName			(required)"
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

# Generate output file name
outStar="${inStar%.*}_sem_OGs.star"

# Find requisite data field numbers
micField=$(grep "_rlnMicrographName" ${inStar} | awk '{print $2}' | sed 's|#||')
ogField=$(grep "_rlnOpticsGroup" ${inStar} | tail -n -1 | awk '{print $2}' | sed 's|#||')


# check for micrograph field
if [[ -z $micField ]] ; then
	echo ""
	echo "Error: input .star file is missing the _rlnMicrographName field"
	echo ""
	usage
fi

# Send header to output file
awk '{if ($0 !~ /.mrc/) {print $0}}' ${inStar} > ${outStar}
# remove empty last line
sed -i '$ d' ${outStar}

# Assign _rlnOptics group field if it is not already present
if [[ -z $ogField ]] ; then
	echo ""
	echo "Warning: input .star file is missing the _rlnOpticsGroup field"
	echo "Will append the field to the end of the input data_particle table"
	echo ""

	ogField=$(grep "_rln" ${inStar} | tail -n 1 | awk '{print $2}' | sed 's|#||')

	((ogField++))

	echo "_rlnOpticsGroup #${ogField}" >> ${outStar}
fi



echo ""
echo "Determining number of unique optics groups..."
echo ""

# Determine optics groups
ogArr=($(awk -v mic=$micField '($0 ~ /.mrc/) {n=split($mic,a,"_"); print a[n]}' ${inStar} | sort | uniq))


echo ""
echo "Counted ${#ogArr[@]} unique optics groups"
echo "Updating optics table entries based on parameters from opticsGroup1"
echo ""

# hard-check for first optics group line
optics_line=$(grep opticsGroup1 ${outStar} | head -n 1)

if [[ -z ${optics_line} ]] ; then

	echo ""
	echo "Error: opticsGroup1 was not found in the optics table!"
	echo ""
	usage

fi

# loop through and append new optics groups to table
for (( i=2 ; i <= ${#ogArr[@]} ; i++)) 
do
	previous_group="opticsGroup"$((i-1))
	next_line=$(echo $optics_line | awk -v i=$i '{ $1=i; $2=substr($2,0,length($2)-1)i; print $0}')

	sed -i "/$previous_group/a $next_line" ${outStar}

done

echo ""
echo "Optics table has been updated"
echo "Proceeding to assigning optics groups"
echo ""
echo ""


# Time to get goofy :P
awk -v outfile=${outStar} -v og=$ogField -v mic=$micField -v OGs="${ogArr[*]}"	'
BEGIN {

	# split bash array into an array that awk can use
	entries=split(OGs,tmp_arr," ")

	# make the array index the optics group matching string and the corresponding entry the intended optics group number
	for (i = 1 ; i <= entries; i++)
		{
			optics_arr[tmp_arr[i]] = i 
		} # close for loop

} # close begin


# file operation
{
	if ($0 ~/.mrc/)	# operate only on lines with references to micrographs
	{
		num=split($mic,mic_nam_arr,"_")	# parse the optics string from the micrograph name
		
		# assign optics group based on entry matching parsed index (nesting the arrays does not work for some reason, hence two-liner)
		optics_string=mic_nam_arr[num]
		$og=optics_arr[optics_string]

		print $0 >> outfile	

	} # close if
	
} # close file operation


END {

} # close end

' ${inStar}

echo ""
echo "Finished assigning optics group to file:	${outStar}"
echo ""
echo ""
echo "NOTE: Make sure to check that the new optics table is correct."
echo ""
echo "Script done!"
echo ""

exit 1
