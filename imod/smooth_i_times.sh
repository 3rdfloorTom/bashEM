#!/bin/bash
#
#
#############################################################################
#
# Author: "Thomas (Tom) G. Laughlin III"
# University of California-Berkeley 2018
#
#
# This program is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.
#
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
#
#     You should have received a copy of the GNU General Public License
#     along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
############################################################################

echo "***************************************************************************************************************"
echo "This script excutes IMOD's smoothing filter an user-defined number of iterations"
echo "It will output the smoothed image file from each iteration (e.g., tomoName_smoothed_#)"
echo ""
echo "Note: This script assumes assumes IMOD functions are in the PATH"
echo "Tom Lauglin, UC-Berkeley 2018"
echo "***************************************************************************************************************"

## inputs
imageFile=$1
iter=$2
outDir=$3

## Check inputs
if [[ -z $1 ]] || [[ -z $2 ]] || [[ -z $3 ]] ; then

	echo ""
	echo "Variable empty, usage is $(basename $0) (1) (2) (3)"
	echo "(1) = imagefile"
	echo "(2) = smoothing iterations"	
	echo "(3) = output/directory"
	echo ""
	
	exit

else

	#check if output directory exists and make if not present
	if [ -d "$outDir" ] ; then
		echo ${outDir} "exists. Continuing with smoothing"
	else 
		echo ${outDir} "did not exist. Made" ${outDir}
		mkdir ${outDir}
	fi

	#extract basename of image file and extension
	imageName=$(basename $imageFile)
	extension=${imageName##*.}
	imageName=${imageName%.*}

	
	#clip smoothing
	for (( i=1; i<=$iter; i++))
	do
		j=$(printf "%02d" $i)

		if [ $i -eq 1 ] ; then
			clip smooth $imageFile ${outDir}/${imageName}_smooth_${j}.${extension}  
		else
			k=$(printf "%02d" $((i - 1)))
			clip smooth ${outDir}/${imageName}_smooth_${k}.${extension} ${outDir}/${imageName}_smooth_${j}.${extension}
		fi

		echo "Iteration output:" ${outDir}"/"${imageName}"_smooth_"${j}"."${extension}
	done

	echo ""
	echo "*********************************************************************************************"
	echo "Done!!!"
	echo "*********************************************************************************************"
	echo ""

fi





