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
echo "This script extracts tilt-series information from a SerialEM .mdoc file to use with externally aligned frames "
echo "It will output a .st from newstack with tilt-angles and tilt axis rotation in the extended header"
echo ""
echo "Note: This script assumes assumes IMOD functions are in the PATH and aligned frames use .mrc extension"
echo "Tom Lauglin, UC-Berkeley 2018"
echo "***************************************************************************************************************"

## inputs
mdoc=$1
alignaver=$2
tiltSeries=$3

## Check inputs
if [[ -z $1 ]] || [[ -z $2 ]] || [[ -z $3 ]]; then

	echo ""
	echo "Variable empty, usage is $(basename $0) (1) (2) (3)"
	echo "(1) = serialEMoutput.mdoc"
	echo "(2) = path/to/aligned/frames"	
	echo "(3) = rootname for output"
	echo ""
	
	exit

else



grep TiltAngle $mdoc | awk '{print $3}' > $tiltSeries.rawtlt

grep SubFramePath $mdoc | awk '{print $3}' | awk -F '\' '{print $NF}' > tmpNames.txt			

wc -l tmpNames.txt | awk '{print $1}' > $tiltSeries.txt 						


#for loop to prepare image names the way newstack likes them
for i in `cat tmpNames.txt`; do 
	echo ${i%.*}.mrc
	echo ${i%.*}.mrc >> $tiltSeries.txt
    echo / >> $tiltSeries.txt
done

#extracts tilt-axis rotation, but unsure how to place in extended header of newstack output...
rotation=$(grep "Tilt axis angle" $mdoc | awk '{print $7}' | sed 's/,//')
oriDir=$(pwd)

#change to directory with aligned frames
cd ${alignaver}

#run newstack to reconstruct tilt-series and store tilt-angles in extended header
newstack -fileinlist ${oriDir}/$tiltSeries.txt -tilt ${oriDir}/$tiltSeries.rawtlt -output ${oriDir}/$tiltSeries.st


echo ""
echo "*********************************************************************************************"
echo "Number of images:" $(wc -l tmpNames.txt | awk '{print $1}')
echo "Wrote out image name file for newstack as:" $tiltSeries.txt 
echo "Wrote out tilt-angles for etomo as:" $tiltSeries.rawtlt
echo "Wrote out reconstructed tilt-series file for IMOD:" $tiltSeries.st
echo "Tilt-Axis Rotation from mdoc file was" $rotation
echo "*********************************************************************************************"
echo ""


#tidy up
rm tmpNames.txt

fi





