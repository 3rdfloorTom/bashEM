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
	echo "This scripts thresholds a particles.star file based on the GroupScaleCorrection from a model.star file"
	echo ""
	echo "NOTE: Script assumes that the group names match the names of the micrographs"
	echo ""
	echo "Usage is:"
	echo ""
	echo "$(basename $0) -i particle.star -m model.star -l lower_threshold -h higher_threshold"
	echo ""
	echo "options list:"
	echo "	-i: RELION-style particle.star file			(required)"
	echo "	-m: RELION-style model.star file 			(required)"
	echo "	-l: lower GroupScaleCorrection threshold    (optional, default=0)"
	echo "	-h: higher GroupScaleCorrection threshold 	(optional, default=2)"
	echo ""
	exit 0
}

# check for any arguements at all
if [[ $# == 0 ]] ; then
	usage
fi

#grab command-line arguements
while getopts ":i:m:l:h:" options; do
    case "${options}" in
        i)
            if [[ -f ${OPTARG} ]] ; then
           		in_pctlStar=${OPTARG}
			    echo ""
			    echo "Found input starfile: ${in_pctlStar}"
			    echo ""
            else
           		echo ""
           		echo "Error: could not input starfile: ${in_pctlStar}"
           		echo ""
           		usage
            fi
            ;;

        m)
            if [[ -f ${OPTARG} ]] ; then
           		in_modelStar=${OPTARG}
			    echo ""
			    echo "Found input starfile: ${in_modelStar}"
			    echo ""
            else
           		echo ""
           		echo "Error: could not input starfile: ${in_modelStar}"
           		echo ""
           		usage
            fi
            ;;


		l)
	    	if [[ ${OPTARG} =~ ^[0-9]+([.][0-9]+)?$ ]] ; then
				threshold_low=${OPTARG}
	    	else
				echo ""
				echo "Error: The lower threshold must be a postive value."
				echo "Exiting..."
				echo ""
				usage
	    	fi
	    	;;

	 	h)
	    	if [[ ${OPTARG} =~ ^[0-9]+([.][0-9]+)?$ ]] ; then
				threshold_high=${OPTARG}
	    	else
				echo ""
				echo "Error: The higher threshold must be a postive value."
				echo "Exiting..."
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

# Check inputs
if [[ -z $in_pctlStar ]] ; then

	echo ""
	echo "Error: No particle.star file provided!"
	echo ""
	usage	
	
fi

if [[ -z $in_modelStar ]] ; then

	echo ""
	echo "Error: No model.star file provided!"
	echo ""
	usage	
	
fi

if [[ -z $threshold_low ]] ; then

	echo ""
	echo "Warning: The lower threshold is not set!"
	echo "Assuming that it is 0"
	echo ""
	threshold_low=0
fi

if [[ -z $threshold_high ]] ; then

	echo ""
	echo "Warning: No higher threshold is set!"
	echo "Assuming that it is 2"
	threshold_high=2
	
fi

# Check for appropriate metadata field
if [[ -z $(grep "_rlnGroupScaleCorrection" ${in_modelStar}) ]] ; then

	echo ""
	echo "Error: Input model.star file does not contain a _rlnGroupScaleCorrection column...are you sure this in a run_model.star?"
	echo "Exiting..."
	echo ""
	usage
fi

# Get fields of interest
grpField=$(grep "_rlnGroupName" ${in_modelStar} | awk '{print $2}' | sed 's|#||')
gscField=$(grep "_rlnGroupScaleCorrection" ${in_modelStar} | awk '{print $2}' | sed 's|#||')


# Make array of groups to be removed
removal_Arr=($(awk -v low=${threshold_low} -v high=${threshold_high} -v grp=${grpField} -v gsc=${gscField} '{if ($0 ~ /.mrc/ && ($4 < low || $4 > high)) {print $2}}' ${in_modelStar} | sed '1d' | sed '/^$/d' ))

echo ""
echo "There are ${#removal_Arr[@]} micrographs marked for removal."
echo ""
echo "Now performing removal"
echo ""

# copy input particle.star to output particle.star
out_pctlStar=${in_pctlStar%.star}_gsc_thresh.star
cp ${in_pctlStar} ${out_pctlStar}


# remove lines containing group name
for (( i = 1; i < ${#removal_Arr[@]} ; i++))
do
	echo "Removing: ${removal_Arr[$i]}"	
	grep -Fv ${removal_Arr[$i]} ${out_pctlStar} > tmp.star
	mv tmp.star ${out_pctlStar}

done

in_count=$(grep .mrc ${in_pctlStar} | wc -l | awk '{print $1}')
out_count=$(grep .mrc ${out_pctlStar} | wc -l | awk '{print $1}')

echo ""
echo "Input particle.star file contained $in_count particles."
echo "Output particle.star file contains $out_count particles."
echo ""
echo "Script done!"
echo ""

exit 1
