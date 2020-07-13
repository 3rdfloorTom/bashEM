#!/bin/bash
#
#
#####################################################################################
#
# Author(s): Tom Laughlin, Digvjay Singh, Vinson Lam
# TL expanding upon etomo scripts and accessory files previously written by DS and VL
# University of California-San Diego 2020
#
#
#####################################################################################

echo "***************************************************************************************************************"
echo ""
echo "This script automatically aligns tilt-series frames generated by Warp using IMOD's etomo patch tracking routine"
echo "This script assumes IMOD is in the user's PATH"
echo "Default file locations are set based on Villa lab's workstations, these can be changed with appropriate flags"
echo ""
echo "Tom Lauglin, UC-San Diego 2020"
echo "***************************************************************************************************************"

# Default file locations
accessories_path="/data/Users/share/shell_scripts/automatic_reconstruction_DS_edit"
adocTemplate="DS_directive_Robust.adoc"

# Default for bad tilt exclusion threshold
exclusionThresh=7

# Defaults for automated patch-tracking for etomo
target_resid=0.5
min_points=7

# Usage description
usage () 
{
	echo ""
	echo "Usage is $(basename $0) -i <imod directory> [optional arguments]"
	echo ""
	echo "-i: Path to Warp's imod directory 				(required)"
	echo ""
	echo "-a: Path to accessories files 					(optional)"
	echo "-d: Name of .adoc template file in accessories	(optional)"
	echo "-t: Excluded-view mean-intensity threshold 		(optional, default=7)"
	echo "-r: Target residual for alignment					(optional, default=0.5)"
	echo "-m: Minimum number of tracked points 				(optional, default=7)"
	exit 0
}

#grab command-line arguements
while getopts ":i:a::d::t::r::m::" options; do
    case "${options}" in
        i)
			if [[ -d ${OPTARG} ]]
           		imodDirectory=${OPTARG}
           	else
           		echo ""
           		echo "Fatal Error: Cannot find Warp's imod directory at specified location."
           		echo "Please check the specified path is correct!"
           		echo ""
           		usage
           	fi
            ;;
        a)
            if [[ -d ${OPTARG} ]]
           		accessories_path=${OPTARG}
           	else
           		echo ""
           		echo "Error: Cannot find accessories directory at specified location."
           		echo "defaulting to use of ${accessories_path}"
           		echo ""
           	fi
            ;;
        d)
            if [[ -f ${accessories_path}/${OPTARG} ]]
           		adocTemplate=${OPTARG}
           	else
           		echo ""
           		echo "Error: Cannot find .adoc template at specified location."
           		echo "defaulting to use of ${accessories_path}/${adocTemplate}"
           		echo ""
           	fi
            ;;
        t)
            if [[ ${OPTARG} =~ ^[0-9]+([.][0-9]+)?$ ]]
           		exclusionThresh=${OPTARG}
           	else
           		echo ""
           		echo "Error: the excluded-view mean-intensity must be a number."
           		echo "defaulting to use of ${exclusionThresh}"
           		echo ""
           	fi
            ;;
        r)
            if [[ ${OPTARG} =~ ^[0-9]+([.][0-9]+)?$ ]]
           		target_resid=${OPTARG}
           	else
           		echo ""
           		echo "Error: the target alignment residual must be a number."
           		echo "defaulting to use of ${target_resid}"
           		echo ""
           	fi
            ;;
        m)
            if [[ ${OPTARG} =~ ^[0-9]+$ ]]
           		min_points=${OPTARG}
           	else
           		echo ""
           		echo "Error: the minimum number of points must be an integer."
           		echo "defaulting to use of ${min_points}"
           		echo ""
           	fi
			;;
        *)
            usage
            ;;
    esac
done
shift "$((OPTIND-1))"


# Check that imod directory is not empty
if [[ -z "$(ls -A ${imodDirectory})" ]]; then
	echo ""
	echo "Specified imod directory is empty"
	echo "exiting..."
	echo ""
	exit
else

	# Make a logfile in the imod directory if it doesn't already exist
	if ! [[ -f "${imodDirectory}"/imodAlign4warp ]]
		echo "tilt-series	excluded-views	mean-residual	contour-count	outcome" > "${imodDirectory}"/batch4warp.log
	fi

	# Iterate through imod directory to perform automated patch tracking alignment
	for i in `ls -A "${imodDirectory}"`; do
		
		cd "${i}"

		# If a SUCCESS.log exists, skip this tilt-series
		if [[ -f SUCCESS.log ]]
			echo ""
			echo "SUCCESS.log exists! Skipping..."
			echo "Remove SUCCESS.log if you wish to reprocess this tilt-series"
			echo ""
			cd "${imodDirectory}"
			continue
		fi

		# Get tilt-series name and meta-data using IMOD function
		ts_name=${i}
		pixelSize=$(header -pixel ${ts_name}.st | awk '{print $1}')
		#dimX=$(header -size ${ts_name}.st | awk '{print $1}')
		#dimY=$(header -size ${ts_name}.st | awk '{print $2}')

		echo ""
		echo "Read in ${ts_name}"
		echo "Proceeding to run patch tracking alignment"
		echo ""

	 	# Get image stats for determing bad views using IMOD function
	 	clip stats ${ts_name}.st >> stats.log 
	 	sed -i -e '1,2d' \				# remove header lines
	 		-e '$d' \					# remove bottom line
	 		-e 's|)|    |g' \
	 		-e 's|(|    |g' \
			-e 's|,|    |g' "stats.log"
		
		# Remove bad views based on mean intensity threshold (field 7)
		 awk -v thresh=$exclusionThresh '{if($8 <= thresh) {print $1+1}}' stats.log > ExcludedViews.tmp

		# Check if any bad views were found
		 viewCount=$(wc -l ExcludedViews.tmp | awk '{print $1}')

		 if [[ viewCount -gt 0 ]]
			
			counter=0
			# If bad views found, reorder vertical file into horizontal csv
			for i in `cat ExcludedViews.txt`; do

				if (counter == 0)
					viewString=$(echo $i)
				else
					viewString=$(echo $viewString,$i)
				fi
			((counter++))

			done
			
			# Record excluded views and tidy-up
			echo ${ts_name} $viewString > ${ts_name}_excludedViews.log
			rm ExcludedViews.tmp || true
	        rm stats.log || true

	        # Generate stack with excluded views using IMOD function
			excludeviews -stack ${ts_name}.st -delete -views ${viewString}
			
	 	 fi


		# Hide pre-existing session if it exists
		if [[  -f "${i}.edf" ]]
			mv "${i}.edf" "${i}.edf.bak"
		fi
		# Determine binning for coarse alignment (typically ~10 A/px is good)
		# 	bash doesn't handle floating-point and rounding well..."bc" enables floating-point arithmetic, 
		# 	"scale" tells bc to return that many digits past the decimal place
		#	then round
		binBy=$(echo "scale = 1; 10 / $pixelSize" | bc | awk '{print int($1+0.5)}')

		# Make adoc file for this tilt-series from template file by changing first line
		cp "${accessories_path}/${adocTemplate}" >> "${i}_directive.adoc"
		sed -i '1c\setupset.copyarg.name=${ts_name}' "${i}_directive.adoc"
		
		# Change patch size for tracking if binning differs from default
		if [[ binBy != 2 ]]
			# Patch sizes for Patch-tracking routine (based on ~4k x 4k)
			patchX=$(( 680 / binBy ))
			patchY=$(( 680 / binBy ))

			sed -i -e 's|BinByFactor=2|BinByFactor=${binBy}|g' \
			    -e 's|ImagesAreBinned=2|ImagesAreBinned=${binBy}|g' \
	    		-e 's|SizeOfPatchesXandY=340,340|SizeOfPatchesXandY=${patchX},${patchY}' "${i}_directive.adoc"
	    fi

	    # Det directive
		etomo --directive "${i}_directive.adoc"

		# Run automated patch-tracking alignment based on Vinson and Digvjay's script

		# Remove pre-existing logs
		rm ${ts_name}_taError.log || true
		rm ${ts_name}_taCoordinates.log || true
		rm ${ts_name}_taRobust.log || true
		rm ${ts_name}_taSolution.log || true
		rm ${ts_name}_edit_fiducial.log || true

		# Pre-processing
		if [ ! -f ${ts_name}_orig.st ] && [ ! -f ${ts_name}_xray.st.gz ]; then
		submfg eraser.com
		mv ${ts_name}.st ${ts_name}_orig.st
		mv ${ts_name}_fixed.st ${ts_name}.st
		fi

		# Coarse alignment
		submfg xcorr.com
		submfg prenewst.com

		# Fiducial Model Generation (patch tracking)
		makecomfile -root ${ts_name} -input xcorr.com -binning 2 -ou xcorr_pt.com -change ./DS_directive.adoc
		submfg xcorr_pt.com

		# Fine alignment (edit fiducial model)
		line_number=$(grep -n "xfproduct" align.com|cut -d : -f 1)
		sed -i "$[${line_number} + 4]i ScaleShifts 1.0,2.0" align.com #scaleshifts matches coarse aligned binning. here bin 2
		sed -i '/SeparateGroup/c\' align.com
		submfg align.com

		alignlog -e > ${ts_name}_taError.log
		alignlog -c > ${ts_name}_taCoordinates.log
		alignlog -w > ${ts_name}_taRobust.log
		alignlog -s > ${ts_name}_taSolution.log

		model2point -c -ob -fl -i ${ts_name}.fid -ou ${ts_name}_fid.pt #convert imod model to a points list for easy editing
		mv ${ts_name}.fid ${ts_name}.fid.orig #archive original fiducial model
		cp ${ts_name}_fid.pt ${ts_name}_fid.pt.orig #archive initial points list model

		num=$(grep 'weighted mean' ${ts_name}_taRobust.log|tr -s ' '|cut -d ' ' -f 6) #check the log for the residual error
		echo "Initial fiducial error: ${num}" >> ${ts_name}_edit_fiducial.log
		while [ $(echo "$num > $target_resid" | bc) -eq 1 ]; do #iteratively remove contours until the target is reached. bc needed because bash does not handle floats.
		 remain_pts=$(sort ${ts_name}_fid.pt -k 5 -n | tr -s ' ' | cut -d ' ' -f 6 | uniq -c | tr -s ' ' |cut -d ' ' -f 2 | sort -n | head -n 1) #count number of remaining points per tilt image. The initial sort is because uniq needs a sorted list.
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
		    break
		 fi
		 point2model -op -ci 5 -w 2 -im ${ts_name}.preali -in ${ts_name}_fid.pt -ou ${ts_name}.fid
		 dd if=${accessories_path}/fid_header.bin of=${ts_name}.fid bs=1 count=136 conv=notrunc #change if= to point to fid_header.bin where ever it is. This is some voodoo hex magic because the header contains contour information.
		 submfg align.com #re-compute alignment
		 alignlog -e > ${ts_name}_taError.log
		 alignlog -c > ${ts_name}_taCoordinates.log
		 alignlog -w > ${ts_name}_taRobust.log
		 alignlog -s > ${ts_name}_taSolution.log
		 num=$(grep 'weighted mean' ${ts_name}_taRobust.log|tr -s ' '|cut -d ' ' -f 6)
		 echo "Current fiducial error: ${num}" >> ${ts_name}_edit_fiducial.log
		done
		echo "Final fiducial error: ${num}" >> ${ts_name}_edit_fiducial.log

		#write to logs
		if (($remain_pts > $min_points))
			echo "Alignment criterion: Residuals<${target_resid} Contours>${min_points} achieved!" > SUCCESS.log
			echo "${ts_name}	${viewString}	${num}	${remain_pts}	SUCCESS" >>  "${imodDirectory}/imodAlign4warp.log"
		else
			echo "${ts_name}	${viewString}	${num}	${remain_pts}	FAIL" >>  "${imodDirectory}/imodAlign4warp.log"
		fi

		echo ""
		echo "Finished patch tracking for ${ts_name}"
		echo "Proceeding to next"
		echo ""

		#return to imod directory and proceed to the next tilt-series
		cd "${imodDirectory}"
	done

	 echo ""
	 echo "The logfile for this run can be found here ${imodDirectory}/imodAlign4warp.log"
	 echo ""
fi

exit 0