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
	echo "This takes an flux in e/A^2/s and a SerialEM .mdoc files to make the corresponds Relion .order file."
	echo ""
	echo "Usage is:"
	echo ""
	echo "$(basename $0) -i myFile.mdoc -e myNumber"
	echo ""
	echo "options list:"
	echo "	-i: A serialEM .mdoc file					(required)"
	echo "	-e: Corresponding flux for .mdoc in e/A^2/s			(required)"
	echo ""
	exit 0
}

# check for any arguements at all
if [[ $# == 0 ]] ; then
	usage
fi

#grab command-line arguements
while getopts ":i:e:" options; do
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

if [[ -z $flux ]] ; then
	echo ""
	echo "Error: No flux was provided."
	echo ""
	usage

fi

# Sanitize mdoc
echo ""
echo "Sanitizing input file..."
echo ""
dos2unix ${mdocFile}

# Get rootname for output
orderFile="$(basename $mdocFile .mrc.mdoc).order"

# Get pixel size from mdoc
pixelSize=$(head -n 1 ${mdocFile} | awk '{print $3}')

echo ""
echo ""
echo "Found pixel size from mdoc in a/px: ${pixelSize}"
echo "This is not used in calculations at all...just thought you would like to know. :)"
echo ""

#flox=$(echo "scale = 5; ${flux} / ${pixelSize} / ${pixelSize}" | bc)

echo ""
echo "Flux given in e/A^2/s is: ${flux}"
echo ""

echo ""
echo "Now preparing order file..."
echo ""

# Get tilt angles, exposure time per frame, subframes, and time-stamps (this gets hairy)

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

# Combine in a files with 11 columns 
paste "tiltAngles.tmp" "exposureTimes.tmp" "dateStamp.tmp" "timeStamp.tmp" > "combined.tmp"

rm "tiltAngles.tmp"
rm "exposureTimes.tmp"
rm "dateStamp.tmp"
rm "timeStamp.tmp"

# shenanigans time
# sort by all the date and time stamps
# set per tilt-dose column
sort -k3,3n -k4,4n -k5,5n -k6,6n -k7,7n -k8,8n "combined.tmp" | awk -v flux=$flux '{print $1,$2*flux}' > "combined_sorted.tmp"
rm "combined.tmp"

# Apply cumulative exposure at each tilt
cmExp=0
while read -r angle tiltExp
do
	cmExp=$(echo "scale = 5; ${tiltExp} + ${cmExp}" | bc)  

	echo "${angle}	${cmExp}"

done < "combined_sorted.tmp" > "outOfOrder.tmp"
rm "combined_sorted.tmp"

# Order by tilt angle
sort -k1,1n "outOfOrder.tmp" > ${orderFile}
rm "outOfOrder.tmp"

echo ""
echo "Generated order file:	${orderFile}"
echo "Script done!"
echo ""

exit 1


