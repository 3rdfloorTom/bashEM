#!/bin/bash
#
#
#############################################################################
#
# Author(s): "Thomas (Tom) G. Laughlin III"
# University of California-San Diego 2020
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
echo "Note: This script assumes auto_ET.py has created a project directory containing directories F1 to Fn and .st's"
echo "Tom Lauglin, UC-San Diego 2020"
echo "***************************************************************************************************************"

## inputs
dirF=$1
numF=$2
fStacks=$3
useNoDW=$4


##hard-codings
logFile="$(basename $0 .sh).log"

## Check inputs
if [[ -z $1 ]] || [[ -z $2 ]] || [[ -z $3 ]]; then

	echo ""
	echo "Arguements empty, usage is $(basename $0) (1) (2) (3) (4)" 
	echo "(1) = path to directory containing 'F' directories and .st's from auto_ET.py"
	echo "(2) = highest number of the 'F' directories"
	echo "(3) = path to parent directory of 'fixedStacks'"
	echo "(4) = use the non-DW .st for 'fixedStacks'"
	echo ""
	
	exit

elif [[ ! -d "${dirF}" ]]; then

	echo ""
	echo "${dirF} does not exist!"
	echo "Check that the given path is correct"
	exit 


else
	

	#check if cp2fixedStacks2.log exists and if not make it




	#check if fixedStacks exists and if not make it
	if [[ -d "${fStacks}/fixedStacks" ]]; then

	echo ""
    	echo "The directory ${fStacks}/fixedStacks already exists on your filesystem."
    	echo "Checking for how many tilts are already in the directory"
    	echo ""
    	
		offset=$(ls -l ${fStacks}/fixedStacks/*.xf | wc -l)

    	echo ""
    	echo "There are presently ${offset} tilts already in ${fStacks}/fixedStacks"
		
	

    	else

    	echo ""
    	echo "The directory ${fStacks}/fixedStacks does not already exist on you filesystem"
    	echo "Making ${fStacks}/fixedStacks directory now"
    	echo ""

    	mkdir -p "${fStacks}/fixedStacks"
	
	offset=0

	fi

	#check if a log file already exists in fixedstacks and if not make it.
	if [[ -f "${fStacks}/fixedStacks/${logFile}" ]]; then

		echo ""
		echo "${fStacks}/fixedStacks/${logFile} already exists!"
		echo "This script is just going to append some lines to it."
		echo ""
	
	else

		echo ""
		echo "${fStacks}/fixedStacks/${logFile} does not already exists!"
		echo "That's totally fine. This script will make one."
		echo ""

		touch "${fStacks}/fixedStacks/${logFile}"

	fi
	
	sleep 5

	echo ""
	echo "Starting to loop through F directories"
	echo "Hope we make it!!"
	echo ""

	sleep 5
	
	for ((i=1; i<=${numF}; i++))
	do 
		if [[ -d "${dirF}/F${i}" ]]; then

			cd "${dirF}/F${i}"
			
			tiltNum=$((i+offset))			

			tmpName=$(echo *.rawtlt)
			
			tiltName="${tmpName%.*}"

		
			if [[ -f ${tiltName}_fid.xf ]] && [[ -f ${tiltName}_fid.tlt ]]; then

				echo "${tiltName}_fid.xf and ${tiltName}_fid.tlt exist!"
				
				excludedViews=$(grep "Excluded  Views ," ${dirF}/${tiltName}_Attributes.csv | awk -F "," '{print $2}')


				echo "All ${tiltName} related files will be renamed to tilt${tiltNum}"

				if [[ -z $useNoDW ]]; then 
				
					echo "${tiltName}	tilt${tiltNum}	${excludedViews}" >> "${fStacks}/fixedStacks/${logFile}"
				else
					echo "${tiltName%_DW}	tilt${tiltNum}	${excludedViews}" >> "${fStacks}/fixedStacks/${logFile}" 
				fi

				cp  ${tiltName}_fid.xf ${fStacks}/fixedStacks/tilt${tiltNum}.xf
				echo "Copied" ${tiltName}_fid.xf "as" tilt${tiltNum}.xf "to ${fStacks}/fixedStacks"

				cp  ${tiltName}_fid.tlt ${fStacks}/fixedStacks/tilt${tiltNum}.tlt
				echo "Copied" ${tiltName}_fid.tlt "as" tilt${tiltNum}.tlt "to ${fStacks}/fixedStacks"

			else 

				echo ""
				echo "${tiltName}_fid.xf and ${tiltName}_fid.tlt do NOT exist in ${dirF}/F${i}!"
				echo "Skipping..."
				echo ""

				echo "F${i}_xf_Or_tlt_Not_Found!	tilt${tiltNum}" >> "${fStacks}/fixedStacks/${logFile}"
				
				continue

			fi

			if [[ -f ${tiltName}local.xf ]]; then

				echo "${tiltName}local.xf exists!"
				cp  ${tiltName}local.xf ${fStacks}/fixedStacks/tilt${tiltNum}.local
				echo "Copied" ${tiltName}local.xf "as" ${fStacks}/fixedStacks/tilt${tiltNum}.local "to ${fStacks}/fixedStacks"

			else

				echo ""
				echo "${tiltName}local.xf does NOT exist!"
				echo "That's totally fine, it's optional."
				echo "Skipping..."
				echo ""

			fi

			if [[ -f ${tiltName}_erase.fid ]]; then

				echo "${tiltName}_erase.fid exists!"
				cp  ${tiltName}_erase.fid ${fStacks}/fixedStacks/tilt${tiltNum}.erase
				echo "Copied" ${tiltName}_erase.fid "as" ${fStacks}/fixedStacks/tilt${tiltNum}.erase "to ${fStacks}/fixedStacks"

			else
			
				echo ""
				echo "${tiltName}_erase.fid does NOT exist!"
				echo "That's totally fine, it's optional."
				echo "Skipping..."
				echo ""

			fi
			

			if [[ -f ${dirF}/${tiltName}.st ]]; then
				
				if [[ -z $useNoDW ]]; then

				echo "Creating soft-link to ${tiltName}.st in ${fStacks}/fixedStacks"
				ln -s ${dirF}/${tiltName}.st ${fStacks}/fixedStacks/tilt${tiltNum}.fixed

				else

				echo "Creating soft-link to ${tiltName%_DW*}.st in ${fStacks}/fixedStacks"
				ln -s ${dirF}/${tiltName%_DW*}.st ${fStacks}/fixedStacks/tilt${tiltNum}.fixed 
			
				fi

			else
				echo ""
				echo "${tiltName}.st does NOT exist!"
				echo "Something is quite wrong..."
				echo "Skipping..."
				echo ""

				echo "${tiltName}_stack_Not_Found!	tilt${tiltNum}" >> "${fStacks}/fixedStacks/${logFile}"
			fi

		else

			echo ""
			echo "Could not find F${i}"
			echo "Skipping..."
			echo ""

		fi
	done

	
	echo ""
	echo "*********************************************************************************************"
	echo "Done!!!"
	echo "Check the ${fStacks}/fixedStacks/${logFile} to see which tilt-series is which tilt# in fixedStacks."
	echo "${fStacks}/fixedStacks/${logFile} also lists when there was a hiccup in moving things :)"
	echo "*********************************************************************************************"
	echo ""

fi





