#!/bin/bash
#
#
##########################################################################################################
#
# Author(s): Tom Laughlin University of California-San Diego 2020
#
# 
#
###########################################################################################################

#usage description
usage () 
{
	echo ""
	echo "This script takes a directory of SerialEM mdoc files, a directory of Warp's tomostar files and a flux in e/A^2/s or directory of _DoseRate.txt files."
	echo ""
	echo "A _DoseRate.txt file must just contain one line that is the flux for the corresponding tilt-series and possess the same basename as cognate tilt-series."
	echo ""
	echo "It outputs the tomostar (.baks the original)  with an adjusted  _wrpDose for each tilt based on the mdoc metadata and input flux."
	echo ""
	echo ""
	echo "Usage is:"
	echo ""
	echo "$(basename $0) -i /path/to/mdoc's -t /path/to/.tomostar's {(-e flux) or (-d /path/to/_DoseRate.txt's)}"
	echo ""
	echo "options list:"
	echo "	-i: mdoc/file/directory						(required)"
	echo "	-t: tomostar/file/directory					(required)"
	echo "	-e: Corresponding flux for .mdoc in e/A^2/s			(optional)"
	echo "	-d: Directory of _DoseRate.txt files with flux for each mdoc	(optional)"	
	echo ""
	exit 0
}

# check for any arguements at all
if [[ $# == 0 ]] ; then
	usage
fi

#grab command-line arguements
while getopts ":i:t:e:d:" options; do
    case "${options}" in
	
	i)  if [[ -d ${OPTARG} ]] ; then
			mdocDir=${OPTARG}
	    else
			echo ""
			echo "Cannot find the specified mdoc directory."
			echo ""
			usage
	    fi
	    ;;

  	 t)  if [[ -d ${OPTARG} ]] ; then
			starDir=${OPTARG}
	    else
			echo ""
			echo "Cannot find the specified tomostar directory."
			echo ""
			usage
	    fi
	    ;;


        e)
            if [[ ${OPTARG} =~ ^[0-9]+([.][0-9]+)?$ ]] ; then
           		flux=${OPTARG}
            else
           		echo ""
           		echo "Error: flux must be a positive number."
           		echo ""
           		usage
            fi
            ;;
	d)
	    if [[ -d ${OPTARG} ]] ; then
		doseDir=${OPTARG}
	    else
		echo ""
		echo "Cannot find the specified doserate directory."
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

## Check for required arguements
if [[ -z $mdocDir ]] ; then
	echo ""
	echo "Error: A SerialEM .mdoc file must be provided."
	echo ""
	usage
fi

if [[ -z $starDir ]] ; then
	echo ""
	echo "Error: A SerialEM .mdoc file must be provided."
	echo ""
	usage
fi

if [[ -z $flux ]] && [[ -z $doseDir ]] ; then
	echo ""
	echo "Error: Either a flux or a directory with the _DoseRate.txt files must be provided."
	echo ""
	usage
fi

# Loop over tomostars and edit if corresponding mdoc is located
for i in  ${starDir}/*.tomostar; 
do

	starFile=$i
	
	echo "Working on $starFile"

	# Get rootname
	tomoName=$(basename $starFile .tomostar)

	# Get flux from a _DoseRate.txt file	
	if [[ $doseDir ]] ; then

		if [[ -f ${doseDir}/${tomoName%.mrc}_DoseRate.txt ]] ; then
		
			flux=$(head -n 1 ${doseDir}/${tomoName%.mrc}_DoseRate.txt)
		
			echo ""
			echo "Using a flux of $flux for $tomoName"
			echo ""
		else
			echo ""
			echo "Error: Could not find ${tomoName}_DoseRate.txt"
			echo "Using previously set flux of $flux for $tomoName"
			echo ""
		fi
	fi 

	# Check for corresponding mdoc or else skip
	if [[ -z ${mdocDir}/${tomoName}.mdoc ]] ; then
		echo ""
		echo "Could not locate corresponding mdoc for $starFile"
		echo "Skipping..."
		continue
	fi
	
	mdocFile=${mdocDir}/${tomoName}.mdoc
	echo "Found corresponding mdoc files at $mdocFile"	
	
	# Sanitize mdoc (remove windows formatting chars)
	echo "Sanitizing mdoc file to prepare parsing"
	dos2unix ${mdocFile}
	
	# Get tilt angles, exposure time per frame, subframes, and time-stamps (this gets hairy)
	
	grep SubFramePath ${mdocFile} | awk -F "\\" '{print $NF}' > "tiltNames.tmp"
	grep TiltAngle ${mdocFile} | awk '{print $3}' > "tiltAngles.tmp"
	grep ExposureTime ${mdocFile} | awk '{print $3}' > "exposureTimes.tmp" 
	grep DateTime ${mdocFile} | awk '{print $3}' > "dateStamp.tmp"
	grep DateTime ${mdocFile} | awk '{print $4}' > "timeStamp.tmp"

	# jenk way to prepare timestamps for odering to avoid a midnight error
	ind=1
	declare -a arr=("Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec")

	for i in "${arr[@]}";
	do
		sed -i "s|$i|$ind|g" "dateStamp.tmp"

	((ind++))
	done

	# Remove other things from date and timestamp files
	sed -i 's|-| |g' "dateStamp.tmp"
	sed -i 's|:| |g' "timeStamp.tmp"

	# Combine in a files with 11 columns (some are carry-over from re-use of another script below...)
	paste "tiltAngles.tmp" "exposureTimes.tmp" "dateStamp.tmp" "timeStamp.tmp" "tiltNames.tmp" > "combined.tmp"

	# shenanigans time
	# sort by all the date and time stamps
	# set per tilt-dose column
	sort -k3,3n -k4,4n -k5,5n -k6,6n -k7,7n -k8,8n "combined.tmp" | awk -v flux=$flux '{print $9,$2*flux}' > "combined_Timesorted.tmp"
	rm "combined.tmp"
	
	#Grab header and body of tomostar file
	awk 'NF < 3 {print $0}' $starFile > ${starFile}.tmp
	awk 'NF > 3 {print $0}' $starFile > "tomostarBody.tmp"
	
	# Apply cumulative exposure at each tilt
	cmExp=0
	while read -r tiltName tiltExp remainder
	do
		cmExp=$(echo "scale = 5; ${tiltExp} + ${cmExp}" | bc)  
		awk -v tiltName=$tiltName -v cmExp=$cmExp '{if ($1 == tiltName) {printf "%s %6s %10s %10s %10s %6.1f\n",$1,$2,$3,$4,$5,cmExp}}' "tomostarBody.tmp"
	
	done < "combined_Timesorted.tmp" > "tomostarHold.tmp"
	rm "combined_Timesorted.tmp"

	# Order everything from positive to negative tilt-angle
	sort -grk 2,2 "tomostarHold.tmp" >> ${starFile}.tmp
	
	# Back up previous tomostar
	cp $starFile ${starFile}.bak	

	# Move new tomostar to old tomostar name
	mv ${starFile}.tmp ${starFile}
	chmod 775 ${starFile}

	echo ""
	echo "Finished updating ${starFile}"
	echo ""
done

# Tidy-up
rm "tiltNames.tmp"
rm "tiltAngles.tmp"
rm "exposureTimes.tmp"
rm "dateStamp.tmp"
rm "timeStamp.tmp"

rm "tomostarBody.tmp"
rm "tomostarHold.tmp"

echo "Script done!"
echo ""


exit 1


