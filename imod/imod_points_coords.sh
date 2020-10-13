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
	echo "This script uses IMOD for generating points for a point picking model in Dynamo"
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
	echo "2)	Don't worry about the pts/contour limit, the script just exports points all together"
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
	echo "6)	Use middle mouse button to trace/place markers on the points of interest."
	echo "			*[Backspace] to delete most recent and/or selected point."
	echo "			*[Left-click] to select a placed point."
	echo "			*[Right-click] to move selected point to new position."
	echo "			*[Shift+D] to delete selected contour/Z-level of points."
	sleep ${shortSleep}
	echo ""
	sleep ${shortSleep}
	echo "7)	Press 's' to save the model before proceeding."		
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
count = $(wc -l ${outName}.pt | awk '{print $1}') 

# Scale everything
awk -v scale=$scalingFactor '{print $3*scale, $4*scale, $5*scale}' ${outName}.pt > ${outName}_model_${i}_pts.xyz

echo "	*Coordinates for ${count} points of model-${i} have been scaled by ${scalingFactor} and written out as:	${outName}_model_${i}_pts.xyz"
echo ""


echo ""
echo "Finished writing out scaled coordinates for import into Dynamo, or whatever this coordinate convention works for really."
echo ""

exit 1



