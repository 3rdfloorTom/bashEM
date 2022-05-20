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
	echo "This script uses IMOD for generating points alphaShapes for culling template-matching results."
	echo "Template-matching results are expected to be from Warp and are normalized to the tomogram dimensions."
	echo ""
	echo "Usage is:"
	echo ""
	echo "$(basename $0) -i input.rec -o outputRootname"
	echo ""
	echo "options list:"
	echo "		-i: tomogram to use for picking							(required)"
	echo "		-o: rootname for output files (if different than input, e.g. 'volume_1')	(optional)"
	echo "		-v: display instructions in terminal (i.e., 'verbose' running)			(optional)"
	echo ""
	exit 0
}

# Check for inputs
if [[ $# == 0 ]]; then
	usage
fi

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
           	outName=${OPTARG}
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
	echo "7)	Press 'n' to start a new contour."
	echo "			*alphaShapes will be made on a per contour basis."
	echo ""
	sleep ${shortSleep}
	echo "8)	Press 's' to save the model before proceeding."		
	echo ""
	echo ""
fi

# When user hits a key in the terminal, proceed with the rest of the script
sleep ${longSleep}
echo ""
read -n1 -rsp $'When finished and model is saved, hit spacebar to continue...\n'
echo ""

# Convert model to points file
model2point -contour -input ${outName}.mod -output ${outName}.pt

x_dim=$(header -size $inFile | awk '{print $1}')
y_dim=$(header -size $inFile | awk '{print $2}')
z_dim=$(header -size $inFile | awk '{print $3}')

# Determine the number of shapes
objects=$(awk '{print $1}' ${outName}.pt | uniq | wc -l)

# Scale everything
awk -v x=$x_dim -v y=$y_dim -v z=$z_dim  '{print $1,$2/x,$3/y,$4/z}' ${outName}.pt > ${outName}_boundary.coords

echo "	*Coordinates for $objects sets of shape coordinates have been normalized and written out as:	${outName}_boundary.coords"
echo ""

echo ""
echo "Done!"
echo ""
exit 1



