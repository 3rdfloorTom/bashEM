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

echo "**********************************************************************************************"
echo "This script extracts tilt image names and corresponding tilt-anlges from a SerialEM .mdoc file"
echo "It will output a .txt of image names for newstack and a .rawtlt file for etomo"
echo ""
echo "Note: There should be a way to directly output a .st file from newstack...suggestions welcome"
echo "Tom Lauglin, UC-Berkeley 2018"
echo "**********************************************************************************************"

## inputs
mdoc=$1
tiltSeries=$2

## Check inputs
if [[ -z $1 ]] || [[ -z $2 ]] ; then

	echo ""
	echo "Variable empty, usage is $(basename $0) (1) (2)"
	echo "(1) = serialEMoutput.mdoc"
	echo "(2) = rootname for output"
	echo ""
	
	exit

else


grep TiltAngle $mdoc | awk '{print $3}' > $tiltSeries.rawtlt

grep SubFramePath $mdoc | awk '{print $3}' | awk -F '\' '{print $NF}' > tmpNames.txt			

wc -l tmpNames.txt | awk '{print $1}' > $tiltSeries.txt 						

echo ""
echo "*********************************************************************************************"
echo "Image names:"
echo "*********************************************************************************************"


#for loop to prepare image names the way newstack likes them
for i in `cat tmpNames.txt`; do 
	echo ${i%.*}.mrc
	echo ${i%.*}.mrc >> $tiltSeries.txt
    echo / >> $tiltSeries.txt
done

echo ""
echo "*********************************************************************************************"
echo "Number of images:" $(wc -l tmpNames.txt | awk '{print $1}')
echo "Wrote out image name file for newstack as:" $tiltSeries.txt 
echo "Wrote out tilt-angles for etomo as:" $tiltSeries.rawtlt
echo "*********************************************************************************************"
echo ""

#tidy up
rm tmpNames.txt

fi





