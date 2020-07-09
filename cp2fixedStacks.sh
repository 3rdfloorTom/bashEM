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
echo "This script copyings IMOD tilt-series alignment data to the fixedStacks directory for emClarity"
echo "It will rename the output to emClarity convention as well"
echo ""
echo "Note: This script assumes you are in the IMOD tilt-series alignment dir"
echo "Tom Lauglin, UC-Berkeley 2018"
echo "***************************************************************************************************************"

## inputs
i=$1

## Check inputs
if [[ -z $1 ]] ; then

	echo ""
	echo "Variable empty, usage is $(basename $0)"
	echo "(1)= tilt number"
	echo ""
	
	exit

else
	#make fixedStacks if it doesn't already exist
	mkdir -p ../../fixedStacks	
	
	cp tilt${i}_fid.xf ../../fixedStacks/tilt${i}.xf
	echo "Copied" tilt${i}_fid.xf "as" ../../fixedStacks/tilt${i}.xf "to fixedStacks"

	cp tilt${i}_fid.tlt ../../fixedStacks/tilt${i}.tlt
	echo "Copied" tilt${i}_fid.tlt ../../fixedStacks/tilt${i}.tlt "to fixedStacks"

	cp tilt${i}_erase.fid ../../fixedStacks/tilt${i}.erase
	echo "Copied" tilt${i}_erase.fid ../../fixedStacks/tilt${i}.erase "to fixedStacks"

	cp tilt${i}local.xf ../../fixedStacks/tilt${i}.local
	echo "Copied" tilt${i}local.xf ../../fixedStacks/tilt${i}.local "to fixedStacks"


	echo ""
	echo "*********************************************************************************************"
	echo "Done!!!"
	echo "Remember to soft-link the fixed stack as tilt"${i}".fixed to fixedStacks!!!"
	echo "*********************************************************************************************"
	echo ""

fi





