#!/bin/bash
#
#
##########################################################################################################
#
# Author(s): Tom Laughlin 2023
#
#
###########################################################################################################
# defaults
default_extend=0
default_threshold=0.01
default_softedge=5
default_threads=4
masks_out_dir=rln_masks
postprocess_out_dir=rln_masks_postprocess

## functions
# usage description
usage ()
{
	echo ""
	echo "This script prepares and applies mask files over a range of parameters specified using relion functions."
	echo ""
	echo "Note:"
	echo "The script will write out all masks to the same direction 'rln_masks'"
	echo "and write out all postprocess jobs to 'rln_masks_postprocess'"
	echo ""
	echo ""
	echo "Usage is:"
	echo ""
	echo "$(basename $0) -i mask_template.mrc -h half1.mrc,half2.mrc -t 0.1,..,N -e 0,.., -s 0,..,N -j N "
	echo ""
	echo "options list:"
	echo "	-i: path to mask template							(required)"
	echo "	-h: comma-separated paths to unfiltered half-maps				(required)"
	echo "	-t: comma-separated list of binarization thresholds 				(optional, default=0.01)"
	echo "	-e: comma-separated list of pixels to extend the binarized map			(optional, default=0)"
	echo "	-s: comma-separated list of soft-edge pixels					(optional, default=5)"
	echo "	-j: number of CPU threads to use for relion_mask_create				(optional, default=4)"
	echo ""
	exit 0

} # usage close

# relion check
rln_check()
{
	if ! [[ $(command -v relion_mask_create) || $(command -v relion_postprocess) ]] ; then
	echo ""
	echo "Error: Could not find relion executables"
	echo "Load relion and re-run the script."
	echo "Exiting..."
	echo ""

	exit 0
	fi

} # close relion check

# relion_mask_create run
rln_mask_create()
{
	local threshold=$1
	local extend=$2
	local softedge=$3
	local outname=$4

	relion_mask_create --i $mask_template --ini_threshold $threshold --extend_inimask $extend --width_soft_edge $softedge --j $threads --o ${outname}

} # close rln_mask_create

# relion_postprocess
rln_postprocess()
{
	local mask=$1
	local outname=$2

	relion_postprocess --i $half1 --i2 $half2 --mask $mask --o $outname

} #close rln_postprocess

# print contents of an array in a line
print_array()
{
	arr=("$@")

        echo -n "  "
	for i in "${arr[@]}"
	do
		echo -n "${i} "
	done	
	
	printf "\n"
} # close print_array

########## Main script ################
# check for any arguements at all
if [[ $# == 0 ]] ; then
	usage
fi

# check whether relion functions are on the path
rln_check

#grab command-line arguements
while getopts ":i:h:t:e:s:j:" options; do
    case "${options}" in
	
	i)  if [[ -f ${OPTARG} ]] ; then
		mask_template=${OPTARG}
	    else
		echo ""
		echo "Error: cannot find the specified mask template. Check specified path."
		echo ""
		exit 0
	    fi
	    ;;
	
	h)  set -f
	    IFS=,
	    halfmap_array=($OPTARG)
	   
	    if [[ ${#halfmap_array[@]} -ne 2 ]] ; then
		echo ""
		echo "Error: half-maps arguement takes exactly 2 paths."
		echo ""
		exit 0
	    fi
		
	    half1=${halfmap_array[0]}
	    half2=${halfmap_array[1]}	
		
	    if ! [[ -f $half1 && -f $half2 ]] ; then
	    	echo ""
		echo "Error: could not find at least one of the specified half-maps. Check specified path"
		echo ""
		exit 0
	    fi
		
	    ;;

	e)  set -f
	    IFS=,
	    extend_array=($OPTARG)
	    ;;

	t)  set -f
	    IFS=,
	    threshold_array=($OPTARG)
	    ;;

	s)  set -f
	    IFS=,
	    softedge_array=($OPTARG)
	    ;;
	
	j) if [[ ${OPTARG} =~ ^[0-9]+$ ]] ; then
		threads=${OPTARG}
	   else
		threads=$default_threads
           fi
	   ;;
	
        *)
            usage
            ;;
    esac
done
shift "$((OPTIND-1))"

echo ""
echo "Running $(basename $0)..."
echo ""

# Check inputs are set
if [[ -z $mask_template ]] ; then
	echo ""
	echo "Error: Mask template has not been provided. Exiting..."
	echo ""
fi

if [[ -z $half1 ]] || [[ -z $half2 ]] ; then
	echo ""
	echo "Error: Both half-maps have not been provided. Exiting..."
	echo ""
	exit 0
fi

if [[ -z $threads ]] ; then
	threads=$default_threads
fi

if [[ ${#extend_array[@]} -eq 0 ]] ; then
	extend_array=($default_extend)
fi

if [[ ${#threshold_array[@]} -eq 0 ]] ; then
	threshold_array=($default_threshold)
fi

if [[ ${#softedge_array[@]} -eq 0 ]] ; then
	softedge_array=($default_softedge)
fi

# make output directories
mkdir -p "$masks_out_dir"
mkdir -p "$postprocess_out_dir"

echo "Iterating over:"
echo ""
echo -n "Thresholds:"
print_array "${threshold_array[@]}"
echo -n "Edge extensions:"
print_array "${extend_array[@]}"
echo -n "Soft-edge extensions:"
print_array "${softedge_array[@]}"
echo ""
echo "Making masks and applying them..."
# perform actual mask making
for threshold in "${threshold_array[@]}"
do
	for extend in "${extend_array[@]}"
	do
		for softedge in "${softedge_array}"
		do
			mask_name=$masks_out_dir/$(basename $mask_template .mrc)_i${threshold#0.}e${extend}s${softedge}.mrc
			echo ""
			echo "Making $mask_name"
			rln_mask_create $threshold $extend $softedge $mask_name 1> /dev/null 2> /dev/null

			pp_dir1=$postprocess_out_dir/$(basename $mask_name .mrc)
			mkdir -p $pp_dir1

			pp_dir2=$pp_dir1/$(basename $mask_name .mrc)_postprocess
			echo "Applying $mask_name"
			rln_postprocess $mask_name $pp_dir2 1> /dev/null 2>/dev/null

		echo "Finished $mask_name"
		done # softedge loop
	done # extend for-loop
done # threshold for-loop

echo ""
echo "Wrote out all masks to $masks_out_dir"
echo "Wrote out postprocess jobs to sub-directories within $postprocess_out_dir containing the cognate mask name."
echo "Check out the logfile.pdf (with something like evince) in each postprocess job to assess the bias of each mask."
echo "Done!"
echo ""
