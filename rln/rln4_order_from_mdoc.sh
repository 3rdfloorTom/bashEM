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
	echo "This a SerialEM .mdoc file to make the order_list.csv for RELION-v4"
	echo "Note: This script requries dos2unix for mdoc sanitation"
	echo ""
	echo "Usage is:"
	echo ""
	echo "$(basename $0) -i myFile.mdoc"
	echo ""
	echo "options list:"
	echo "	-i: A serialEM .mdoc file					(required)"
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
	
	i)  if [[ -f ${OPTARG} ]] ; then
			mdocFile=${OPTARG}
	    else
			echo ""
			echo "Cannot find the specified mdoc file."
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
if [[ -z $mdocFile ]] ; then
	echo ""
	echo "Error: A SerialEM .mdoc file must be provided."
	echo ""
	usage
fi

echo ""
echo "Sanitizing input file..."
echo ""
dos2unix ${mdocFile}

# Get rootname for output
orderFile="$(basename $mdocFile .mdoc).csv"

# Get tilt angles and time-stamps (this gets hairy)
grep TiltAngle ${mdocFile} | awk '{print $3}' > "tiltAngles.tmp" 
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

# Combine files for sorting by time stamp 
paste "tiltAngles.tmp" "dateStamp.tmp" "timeStamp.tmp" > "combined.tmp"

# shenanigans time
# sort by all the date and time stamps
counter=1
while read -r angle stamp remainder
do
	rounded_angle=$(printf "%0.1f" $angle)
	echo "$counter,$rounded_angle"
	((counter++))
	
done < <(sort -k2,2n -k3,3n -k4,4n -k5,5n -k6,6n -k7,7n "combined.tmp") > ${orderFile}

# clean up
rm "tiltAngles.tmp" 
rm "dateStamp.tmp"
rm "timeStamp.tmp"
rm "combined.tmp"

echo ""
echo "Generated order file:	${orderFile}"
echo "Script done!"
echo ""

exit 1


