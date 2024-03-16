#!/bin/bash
#
#  WORK-IN-PROGRESS
#####################################################################################
#
# Author(s): Tom Laughlin
# Altos Labs 2023
#
#####################################################################################

echo "***************************************************************************************************************"
echo ""
echo "This script automatically aligns tilt-series frames generated by Warp using IMOD's etomo patch tracking routine"
echo "This script assumes IMOD is in the user's PATH"
echo ""
echo "Dependencies: IMOD,dos2unix"
echo ""
echo "***************************************************************************************************************"

# Default file locations
script_dir=$(dirname $0)
accessories_path=${script_dir%/wrp}/misc
adoc_template="patch_tracking.adoc"
	
	# align.com generated from default directive
	# 	Solves for single tilt-axis rotation (it should be measured accurately enough to remain fixed...)
	# 	Fixed magnification
	# 	Fixed tilt-angles	
	# 	No fitting of beamtilt
	# 	No fitting of stretching/distortion

# Default coarse binning
binBy=2

# Heuristically seems to work well when data binned to 8-12 A/px
patch_size_X=340
patch_size_Y=340

# Defaults for automated patch-tracking for etomo
<<<<<<< HEAD:wrp/wrp_batchPatch_imod_v2.sh
target_residual=2
=======
target_residual=0.5	# in nm
>>>>>>> f4ba299 (minor changes):wrp/wrp_batchPatch_imod_v2
min_points=7

# log file location
#log_file=${imod_dir}/batch_patch.log

## functions
prepare_etomo_dir()
{
	local ts_name=$1

	# Hide pre-existing session if it exists
	if [[  -f "${ts_name}.edf" ]] ; then
		mv "${ts_name}.edf" "${ts_name}.edf.bak"
	fi
	
	dim_X=$(header -size ${ts_name}.st | awk '{print $1}')
	dim_Y=$(header -size ${ts_name}.st | awk '{print $2}')

	# Make adoc file for this tilt-series then add the defaults from the template adoc file
	echo "setupset.copyarg.name=${ts_name}" > "${ts_name}_directive.adoc"
	cat "${accessories_path}/${adoc_template}" >> "${ts_name}_directive.adoc"	

	# Change patch size for tracking if binning differs from default
	if [[ ${binBy} -ne 2 ]]  ; then
		sed -i "s|BinByFactor=2|BinByFactor=${binBy}|g" "${ts_name}_directive.adoc"
		sed -i "s|ImagesAreBinned=2|ImagesAreBinned=${binBy}|g" "${ts_name}_directive.adoc"
	fi
	
	# Default patches for K2 binned to 7-12 A/px seems to work well	
	sed -i "s|SizeOfPatchesXandY=340,340|SizeOfPatchesXandY=${patch_size_X},${patch_size_Y}|" "${ts_name}_directive.adoc"	    

	# Set directive	
	etomo --directive "${ts_name}_directive.adoc" --namingstyle 0

	# adjust newstack for the current image dimensions
		sed -i "s|SizeToOutputInXandY.*|SizeToOutputInXandY	${dim_Y},${dim_X}|" newst.com	

		# Run automated patch-tracking alignment based on Vinson and Digvjay's script

		# Remove pre-existing logs
		if [[ -f ${ts_name}_taError.log ]] ; then
			rm ${ts_name}_taError.log
		fi

		if [[ -f ${ts_name}_taCoordinates.log ]] ; then	
			rm ${ts_name}_taCoordinates.log 
		fi
		
		if [[ -f ${ts_name}_taRobust.log ]] ; then
			rm ${ts_name}_taRobust.log 
		fi

		if [[ -f ${ts_name}_taSolution.log ]] ; then
			rm ${ts_name}_taSolution.log 
		fi
	
		if [[ -f ${ts_name}_edit_fiducial.log ]] ; then
			rm ${ts_name}_edit_fiducial.log 
		fi

} # close prepare_etomo_dir

patch_track()
{
	local ts_name=$1

	# Coarse alignment
	echo "Now performing coarse alignment of $ts_name"
	submfg xcorr.com 
	submfg prenewst.com 

	# Fiducial Model Generation (patch tracking)
	echo "Preparing for fidicual model for fine alignment by patch-tracking"

	makecomfile -root ${ts_name} -input xcorr.com -binning ${binBy} -ou xcorr_pt.com -change ./"${ts_name}_directive.adoc" > /dev/null
	submfg xcorr_pt.com 

	# Fine alignment (edit fiducial model)
	echo "Performing fine alignment via patch-tracking..."

	line_number=$(grep -n "xfproduct" align.com|cut -d : -f 1)
	sed -i "$[${line_number} + 4]i ScaleShifts 1.0,${binBy}" align.com #scaleshifts matches coarse aligned binning.
	sed -i '/SeparateGroup/c\' align.com
	submfg align.com 

	alignlog -e > ${ts_name}_taError.log
	alignlog -c > ${ts_name}_taCoordinates.log
	alignlog -w > ${ts_name}_taRobust.log
	alignlog -s > ${ts_name}_taSolution.log

	model2point -c -ob -inp ${ts_name}.fid -ou ${ts_name}_fid.pt	 #convert imod model to a points list for easy editing
	mv ${ts_name}.fid ${ts_name}.fid.orig #archive original fiducial model
	cp ${ts_name}_fid.pt ${ts_name}_fid.pt.orig #archive initial points list model

	num=$(grep 'weighted mean' ${ts_name}_taRobust.log | awk '{print $5}') #check the log for the residual error
	echo "Initial fiducial error: ${num}" >> ${ts_name}_edit_fiducial.log

	# Initialize remain_points outside of while loop scope for logs later
  	remain_pts=$(sort ${ts_name}_fid.pt -k 5 -n | tr -s ' ' | cut -d ' ' -f 6 | uniq -c | tr -s ' ' |cut -d ' ' -f 2 | sort -n | head -n 1) #count number of remaining points per tilt image. 
	
	while [ $(echo "$num > $target_residual" | bc) -eq 1 ]; do #iteratively remove contours until the target is reached. bc needed because bash does not handle floats.
		 remain_pts=$(sort ${ts_name}_fid.pt -k 5 -n | tr -s ' ' | cut -d ' ' -f 6 | uniq -c | tr -s ' ' |cut -d ' ' -f 2 | sort -n | head -n 1) #count number of remaining points per tilt image. 
	 if (($remain_pts > $min_points))
	    then
		    worst_resid=$(sort ${ts_name}_taCoordinates.log -k 7 -nr | head -n 1 | tr -s ' ' | cut -d ' ' -f 7,8)
		    rm_contour=${worst_resid%% *} #find the contour with the largest residual
		    cont_resid=${worst_resid##* } #contour residual value
		
		    if [ $rm_contour -eq 1 ] #needed due to presence of object number
		    then
		       rm_contour="1     1"
		    fi

	    grep -v " $rm_contour " ${ts_name}_fid.pt > ${ts_name}_temp_fid.pt #the magic rm is to find only contour labels.
	    mv ${ts_name}_temp_fid.pt ${ts_name}_fid.pt
	    echo "Removing contour #${rm_contour} with residual: ${cont_resid}" >> ${ts_name}_edit_fiducial.log
	 else
	    echo "Insufficient remaining points: FAIL" >> ${ts_name}_edit_fiducial.log
	    echo "Insufficient remaining points" > FAIL.log
	    break	# end loop upon failure
	 fi
		 point2model -op -ci 5 -w 2 -im ${ts_name}.preali -in ${ts_name}_fid.pt -ou ${ts_name}.fid
		 dd if=${accessories_path}/fid_header.bin of=${ts_name}.fid bs=1 count=136 conv=notrunc #change if= to point to fid_header.bin where ever it is. This is some voodoo hex magic because the header contains contour information.
		 submfg align.com  # re-compute alignment
		 alignlog -e > ${ts_name}_taError.log
		 alignlog -c > ${ts_name}_taCoordinates.log
		 alignlog -w > ${ts_name}_taRobust.log
		 alignlog -s > ${ts_name}_taSolution.log
		 num=$(grep 'weighted mean' ${ts_name}_taRobust.log | awk '{print $5}')
		 echo "Current fiducial error: ${num}" >> "${ts_name}_edit_fiducial.log"
	done

	echo "Final fiducial error: ${num}" >> "${ts_name}_edit_fiducial.log"

	if [[ -f "FAIL.log" ]] ; then
		return 0
	else
		submfg newst.com
		touch "SUCCESS.log"
		return 1
	fi

} # close patch_track()

reconstruct_tomo()
{
	# indexed starting at 1
	local tomo_name=$(grep "OutputFile" | awk '{print $2}')

	submfg tilt.com
	trimvol -rx ${tomo_name} ${tomo_name%_full_rec.mrc}_rec.mrc # rotate about X

} # close reconstruct_tomo()

print_to_log()
{
	local ts_name=$1

	if [[ -f "SUCCESS.log" ]] ; then
		alignment_status='success'
		mean_residual=$(grep 'weighted mean' ${ts_name}_taRobust.log | awk '{print $5}')
	else
		alignment_status='failed'
		mean_residual='N/A'
	fi

	printf "%-s %-s %-s\n" ${ts_name} ${alignment_status} ${mean_residual} >> ${log_file}

} # close print_to_log()

align_tiltseries()
{
	local ts_name=$(basename $1)
	local ts_dir=$1
	local ts_mdoc=$2
	
	
	cd ${ts_dir}
	
	if [[ -f SUCCESS.log ]] ; then
		echo "This tilt-series is already aligned. Skipping...."
		return
	fi
		
	# sanitize mdoc
	dos2unix ${ts_mdoc}
	
	# check for tilt-axis rotation in the extended header
	# and add it to the header if not present
	if [[ -z $(header ${ts_name}.st | grep "Tilt axis angle") ]] ; then

		alterheader -title "$(grep "Tilt axis angle" ${ts_mdoc})" ${ts_name}.st
	
	fi

	# write directive and com script
	prepare_etomo_dir ${ts_name}

	# perform iterative patch-tracking routine to achieve residual threshold
	patch_track ${ts_name}
	#alignment_successful=$?

	# If alignment was successful, then reconstruct tomogram at bin 8 by WBP
	#if [[ ${alignment_successful} -eq 1 ]]; then
	#	reconstruct_tomo ${gpu_id}
	#fi

	print_to_log() ${ts_name}

	return

} # close align_tiltseries


# Usage description
usage () 
{
	echo ""
	echo "Usage is:"
	echo ""
	echo "	 $(basename $0) -i <imod directory> -m <mdoc directory> [optional arguments]"
	echo ""
	echo "	-i: Path to Warp's imod directory				(required)"
	echo "	-m: Path to directory containing cognate .mdoc files		(required)"
	echo ""
	echo "	-a: Path to accessories files					(optional)"
	echo "	-d: Name of .adoc template file in accessories			(optional)"
	echo "	-r: Target residual for alignment (in nm)			(optional, default=0.5)"
	echo "	-n: Minimum number of tracked points				(optional, default=7)"
	echo "	-b: Binning for coarse alignment				(optional, default=2)"
	echo "	-x: Patch size in X for patch-tracking				(optional, default=340)"
	echo "	-y: Patch size in Y for patch-tracking				(optional, default=340)"
	exit 0

} ## close usage


############### Main script ###############



# If ran without arguements, display usage
if [[ $# == 0 ]] ; then
	usage
fi

# get command-line arguements
while getopts ":i:m:a:d:r:n:b:x:y:" options; do

    case "${options}" in

        i)
	    if [[ -d ${OPTARG} ]] ; then
           		imod_dir=$( realpath ${OPTARG} )
            else
           		echo ""
           		echo "Fatal Error: Cannot find Warp's imod directory at specified location."
           		echo "Please check the specified path is correct!"
           		echo ""
           		usage
            fi
            ;;
	m)
	    if [[ -d ${OPTARG} ]] ; then
           		mdoc_dir=$(realpath ${OPTARG} )
            else
           		echo ""
           		echo "Fatal Error: Cannot find mdoc directory at specified location."
           		echo "Please check the specified path is correct!"
           		echo ""
           		usage
            fi
            ;;       

        a)
            if [[ -d ${OPTARG} ]] ; then
           		accessories_path=${OPTARG}
            else
           		echo ""
           		echo "Error: Cannot find accessories directory at specified location."
           		echo "defaulting to use of ${accessories_path}"
           		echo ""
            fi
            ;;
        d)
            if [[ -f ${accessories_path}/${OPTARG} ]] ; then
           		adoc_template=${OPTARG}
            else
           		echo ""
           		echo "Error: Cannot find .adoc template at specified location."
           		echo "defaulting to use of ${accessories_path}/${adoc_template}"
           		echo ""
	    fi
            ;;

        r)
            if [[ ${OPTARG} =~ ^[0-9]+([.][0-9]+)?$ ]] ; then
           		target_residual=${OPTARG}
            else
           		echo ""
           		echo "Error: the target alignment residual must be a number."
           		echo "defaulting to use of ${target_resid}"
           		echo ""
            fi
            ;;
        n)
            if [[ ${OPTARG} =~ ^[0-9]+$ ]] ; then
           		min_points=${OPTARG}
            else
           		echo ""
           		echo "Error: the minimum number of points must be an integer."
           		echo "defaulting to use of ${min_points}"
           		echo ""
            fi
            ;;
		b)
            if [[ ${OPTARG} =~ ^[0-9]+$ ]] ; then
           		binBy=${OPTARG}
            else
           		echo ""
           		echo "Error: the binning for coase alignment must be an positive integer."
           		echo "defaulting to use of ${binBy}"
           		echo ""
            fi
            ;;
      	x)
            if [[ ${OPTARG} =~ ^[0-9]+$ ]] ; then
           		patch_size_X=${OPTARG}
            else
           		echo ""
           		echo "Error: patch size for X must be a positive value."
           		echo "defaulting to use of ${patch_size_X}"
           		echo ""
            fi
            ;;
	
      	y)
            if [[ ${OPTARG} =~ ^[0-9]+$ ]] ; then
           		patch_size_Y=${OPTARG}
            else
           		echo ""
           		echo "Error: patch size for Y must be a positive value."
           		echo "defaulting to use of ${patch_size_Y}"
           		echo ""
            fi
            ;;
 
        *)
            usage
            ;;
    esac
done
shift "$((OPTIND-1))"
# check that the specified imod directory exits
if [[ -z "$(ls -A ${imod_dir})" ]]; then
	echo ""
	echo "Specified imod directory is empty."
	echo "exiting..."
	echo ""
	exit 0

# check that the mdoc directory exists
elif [[ -z "$(ls -A ${mdoc_dir})" ]] ; then
	echo ""
	echo "Specified imod directory is empty."
	echo "exiting..."
	echo ""
	exit 0

else

<<<<<<< HEAD:wrp/wrp_batchPatch_imod_v2.sh
=======
	# prepare log file header
	if ! [[ -f "${log_file}" ]] ; then
		printf "%-s %-s %s\n" 'tilt-series' 'Status' 'Mean residual (nm)'
	fi
>>>>>>> f4ba299 (minor changes):wrp/wrp_batchPatch_imod_v2

	declare -a tiltseries_array
	declare -a mdoc_array


	# compose arrays for TS which are to be aligned
	for TS in "${imod_dir}"/* 
	do
		if ! [[ -d $TS ]] ; then
			continue 
		fi
	
		ts_name=$(basename $TS)
		ts_mdoc="${mdoc_dir}/${ts_name}.mdoc"

		# check that an mdoc file exists
		if ! [[ -f ${ts_mdoc} ]] ; then
			echo ""
			echo "Could not find an mdoc for: $ts_mdoc "
			echo "Skipping..."
			echo ""

			continue
		fi

		# add TS to array for alignment
		tiltseries_array+=(${TS});
		mdoc_array+=(${ts_mdoc})
	done



	# crude batch
	for (( TS=0 ; TS < "${#tiltseries_array[@]}" ; TS++ ))
	do

		ts_name=${tiltseries_array[$TS]}
		ts_mdoc=${mdoc_array[$TS]}
   		
   		echo ""
		echo "Aligning $(basename $ts_name)"
		echo ""

		align_tiltseries ${ts_name} ${ts_mdoc}

	done
	
	log_file=${imod_dir}/batchpatch.log

	printf "%-s	%s	%s\n" "Tilt-series" "Status" "Residual (nm)" > ${log_file}
	
	for (( TS=0 ; TS < "${#tiltseries_array[@]}" ; TS++ ))
	do
		ts_dir=${tiltseries_array[$TS]}
		ts_name=$(basename ${ts_dir})

		if [[ -f ${ts_dir}/SUCCESS.log ]] ;then
			alignment="success"
			residual=$(grep "weighted mean" ${ts_dir}/*_taRobust.log | awk '{print $5}')
		else
			alignment="fail"
			residual="N/A"
		fi
		
		printf "%-s     %s      %s\n" $ts_name $alignment $residual >> ${log_file}
	done

fi

echo ""
echo "Script done!"
echo ""
echo "Results have been written out to ${log_file}"
echo ""

