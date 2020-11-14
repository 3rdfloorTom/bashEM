#!/bin/bash
#
###############################################################################
#	Author: TL @ UCSD 2020
#
#
###############################################################################

# Usage description
usage () 
{
	echo ""
	echo "This script uses IMOD for generating particle coordinates for extraction in Warp"
	echo ""
	echo "It will output a coordinate .star file named [input]_[coordinateSuffix].star"
	echo ""
	echo "Usage is:"
	echo ""
	echo "$(basename $0) -i input.mrc -o coordinateSuffix -v"
	echo ""
	echo "options list:"
	echo "		-i: tomogram to use for picking							(required)"
	echo "		-o: suffix for coordinate output file						(optional, default = manualPick)"
	echo "		-v: display instructions in terminal (i.e., 'verbose' running)			(optional)"
	echo ""
	exit 0
}

# Check for inputs
if [[ $# == 0 ]]; then
	usage
fi

# Set defaults
coordSuffix="manualPick"

# Grab command-line arguements
while getopts ":i:o:v" options; do
    case "${options}" in
        i)
            if [[ -f ${OPTARG} ]] ; then
           		inFile=${OPTARG}
           		echo ""
           		echo "Found ${inFile}."
           		echo "Opening ${inFile} using 3dmod."
           		echo ""
           	else
           		echo ""
           		echo "Error: Cannot find file named ${inFile}."
           		echo "exiting..."
           		echo ""
           		usage
           	fi
            ;;
        o)
           	coordSuffix=${OPTARG}
            ;;
	v)
		instructions=1
	    ;;
        *)
            usage
            ;;
    esac
done
shift "$((OPTIND-1))"


# Check the optional inputs and set to defaults, if necessary
if [[ -z "$inFile" ]] ; then

	echo ""
	echo "No input file found..."
	echo "Exiting...."
	echo ""
	usage
fi

outName=${inFile%.*}"_"$coordSuffix


#To open all mrc files in specific order

3dmod -E t1 \
	-xyz	\
	 ${inFile} \
	 ${outName}.mod


# For ease of adjusting below
longSleep=5s
shortSleep=3s

echo ""
echo "*Wait for tomogram to load. It can take a few seconds*"
echo ""
sleep ${longSleep}


# Show instructions if verbosity has been invoked
if [[ -n ${instructions} ]] ; then
	echo ""
	echo "	In object edit dialogue window select/check:"
	sleep ${longSleep}
	echo "1)	Object type: 'Scatter'"
	echo ""
	sleep ${shortSleep}
	echo "2)	Don't worry about the pts/contour limit, the script just exports points assuming 1 pt/particle."
	echo "			*Visually, Scatter will probably look the best"
	echo ""
	sleep ${shortSleep}
	echo "3)	Change the symbol style if you like (open circle is a popular)."
	echo ""
	sleep ${shortSleep}
	echo "4)	Movement Controls:"
	echo ""	
	echo "			*[pg up/pg dn] to move up/down in slices (or use sliders)."
	echo "			*[+/-] to zoom in and out."
	echo "			*[Left-click and hold] to drag image."
	sleep ${shortSleep}
	echo "5)	Picking Controls:"
	echo ""	
	echo "			*[Middle-click] to pick coordinates."
	echo ""
	echo "			*[Backspace] to delete most recent and/or selected point."
	echo "			*[Left-click] to select a placed point."
	echo "			*[Right-click] to move selected point to new position."
	echo "			*[Shift+D] to delete selected contour/Z-level of points."
	sleep ${shortSleep}
	echo ""
	echo "6)	Press 's' to save the model before proceeding."		
	echo ""
	echo ""
fi

# When user hits a key in the terminal, proceed with the rest of the script
sleep ${longSleep}
echo ""
read -n1 -rsp $'When finished and model is saved, hit spacebar to continue...\n'
echo ""

# Convert model to points file (they should all be the same)
model2point 	-input ${outName}.mod \
		-output ${outName}.pt

# Determine the number of points
count=$(wc -l ${outName}.pt | awk '{print $1}') 

outStar=${outName}.star

# make the starfile header (The Origins and Angles might be useless, but eh, it works)
if (true) ; then
	echo ""
	echo "data_"
	echo ""
	echo "loop_"
	echo "_rlnCoordinateX #1"
	echo "_rlnCoordinateY #2"
	echo "_rlnCoordinateZ #3"
	echo "_rlnOriginX #4"
	echo "_rlnOriginY #5"
	echo "_rlnOriginZ #6"
	echo "_rlnAngleRot #7"
	echo "_rlnAngleTilt #8"
	echo "_rlnAnglePsi #9"
	echo "_rlnMicrographName #10"
fi > $outStar

# Append points to header
awk -v micName=$inFile '{printf "%5s %5s %5s %5s %5s %5s %5s %5s %5s %s\n", $1,$2,$3,"0","0","0","0","0","0",micName}' ${outName}.pt >> $outStar

echo ""
echo "Coordinates for ${count} points within $inFile have written out as:	$outStar"
echo "Ready for export of subtomograms in Warp!"
echo ""
echo "Script done!"
echo ""

exit 1



