#!/bin/bash
#
#
#############################################################################
#
# Author: "Thomas (Tom) G. Laughlin III"
# University of California-Berkeley 2019
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
echo "This script excutes IMOD's clip on a file to rescale intensities to yield a minimum density = 0"
echo "It will output a file of the same name as the original and move the original to a .bak"
echo ""
echo "Note: This script assumes assumes IMOD functions are in the PATH"
echo "Tom Lauglin, UC-Berkeley 2019"
echo "***************************************************************************************************************"

## inputs
imageFile=$1

## Check inputs
if [[ -z $1 ]] ; then

	echo ""
	echo "Variable empty, usage is $(basename $0) (1)"
	echo "(1) = imagefile"
	echo ""
	
	exit

else

	#extract basename of image file and extension
	imageName=$(basename $imageFile)
	extension=${imageName##*.}
	imageName=${imageName%.*}

	echo "checking minimum value for " ${imageName}

	minDen=$(header -minimum ${imageFile})

	echo "Minimum density is" ${minDen}

	clip divide ${imageFile} ${imageFile} tmp.${extension}

	newstack -fill ${minDen} tmp.${extension} tmp.${extension}

	cp ${imageFile} ${imageFile}.bak

	echo "Copied original file " ${imageFile} " to " ${imageFile}.bak

	clip normalize -n ${minDen} tmp.${extension} minimumDensity.${extension}
	
	clip subtract ${imageFile}.bak minimumDensity.${extension} ${imageFile}

	echo "Subtracted minimum density of" ${minDen} " from " ${imageFile}

	echo "Cleaning up intermediate files"

	rm tmp.${extension}
	rm minimumDensity.${extension}

	echo ""
	echo "*********************************************************************************************"
	echo "Done!!!"
	echo "*********************************************************************************************"
	echo ""

fi
