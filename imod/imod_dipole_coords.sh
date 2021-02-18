#!/bin/bash
#
###############################################################################
#
#
#
###############################################################################

# Usage description
usage () 
{
	echo ""
	echo "This script uses IMOD for generating points for a dipole model in Dynamo"
	echo "(really, it is just seperating by contour, so works for anything you seperate in 3dmod that way)"
	echo "Usage is:"
	echo ""
	echo "$(basename $0) -i input.rec -o outputRootname -s scalingFactor"
	echo ""
	echo "options list:"
	echo "		-i: tomogram to use for picking							(required)"
	echo "		-o: rootname for output files (if different than input, e.g. 'volume_1')	(optional)"
	echo "		-s: scaling factor for upsampling model if to be used for unbinned volume	(optional)"
	echo "		-v: display instructions in terminal (i.e., 'verbose' running)			(optional)"
	echo ""
	exit 0
}

# Check for inputs
if [[ $# == 0 ]]; then
	usage
fi

# Grab command-line arguements
while getopts ":i:o:s:v" options; do
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
           	outName=${OPTARG}
            ;;
        s)
            if [[ ${OPTARG} =~ ^[0-9]+([.][0-9]+)?$ ]] ; then
           		scalingFactor=${OPTARG}
           	else
           		echo ""
           		echo "Error: Scaling factor must be a positive number, if invoked."
           		echo "exiting..."
           		echo ""
           		usage
           	fi
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
if [[ -z "$outName" ]] ; then

	outName="${inFile%.*}"

	echo ""
	echo "Outname is not set..."
	echo "Using input file rootname of ${outName} for output files."
	echo ""
fi

if [[ -z $scalingFactor ]] ; then

	scalingFactor=1

	echo ""
	echo "Scaling factor is not set..."
	echo "Assuming the intended scaling is: ${scalingFactor}"
	echo ""

fi

#To open all mrc files in specific order

3dmod -E t1 \
	-S	\
	 ${inFile} \
	 ${outName}_dipoles.mod


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
	echo "1)	Object type: 'Open'"
	echo ""
	sleep ${shortSleep}
	echo "2)	Set '2' of points per contour"
	echo ""
	sleep ${shortSleep}
	echo "2.5)	Change the symbol style if you like."
	echo ""
	sleep ${shortSleep}
	echo "3)	Click on Slicer window (picture of specimen)."
	echo ""
	sleep ${shortSleep}
	echo "4)	On keyboard press 'end' (to bring you to first slice)."
	echo ""
	sleep ${shortSleep}
	echo "5)	Use 'pg up/down' on keyboard to move through images."
	echo ""	
	sleep ${shortSleep}
	echo "6)	Use middle mouse button to trace/place markers on the surface of interest."
	echo "			*[Backspace] to delete most recent and/or selected point."
	echo "			*[Left-click] to select a placed point."
	echo "			*[Right-click] to move selected point to new position."
	echo "			*[Shift+D] to delete selected contour/Z-level of points."
	sleep ${shortSleep}
	echo ""
	echo "		Notes:"
	echo "		The first point is the assumed start/center and the second point the assumed end/perimeter point."
	echo "		Increasing the slice count can be useful, just remember where you are in Z"
	echo ""
	echo ""
	sleep ${shortSleep}
	echo " 		Once finished with marking a dipole of interest:"
	echo ""
	sleep ${shortSleep}
	echo "7)	For a new contour should start automatically, if you had set the point limit to 2."
	echo ""
	sleep ${shortSleep}
	echo "8)	Repeat picking as necessary to select all dipoles of interest."
	echo ""
	sleep ${shortSleep}
	echo "9)	Press 's' to save the model before proceeding."		
	echo ""
	echo ""
fi

# When user hits a key in the terminal, proceed with the rest of the script
sleep ${longSleep}
echo ""
read -n1 -rsp $'When finished and model is saved, hit spacebar to continue...\n'
echo ""

# Convert model to points file with contour indicies
model2point 	-contour \
		-input ${outName}_dipoles.mod \
		-output ${outName}_dipoles.pt

# Determine the number of contours
contours=$(awk '{print $1}' ${outName}_dipoles.pt | uniq | wc -l)

echo ""
echo "Found point pairs for ${contours} dipoles."
echo "Scaling points by a factor of ${scalingFactor}."
echo ""

awk -v scale=${scalingFactor} '{print $1, $2*scale, $3*scale, $4*scale}' ${outName}_dipoles.pt > ${outName}_dipoles.xyz

echo ""
echo "Finished writing out scaled coordinates for import into Dynamo, or whatever this coordinate convention works for really."
echo ""

exit 1



