#!/bin/bash
#
#
##########################################################################################################
#
# Author(s): Tom Laughlin University of California-San Diego 2021
#		
#		adaptation from suggesttion in cisTEM forum by Tim Grant
# 
#
###########################################################################################################

#usage description
usage () 
{
	echo ""
	echo "This scripts converts the fsc.txt file from cryoSPARC into a .xml format for EMDB deposition."
	echo ""
	echo "Functional portion of code based on suggestion by Tim Grant."
	echo ""
	echo "Usage is:"
	echo ""
	echo "$(basename $0) -i cryoSPARC_FSC.txt -p pixel_size -b box_size"
	echo ""
	echo "options list:"
	echo "	-i: .txt file containing wave_number and fsc_noisesub fields			(required)"
	echo "	-p: pixel size (in Ang) of the map for which the FSC information pertains to	(required)"
	echo "	-b: box size (in pixels) of the map for which the FSC information pertains to	(required)"
	echo ""
	exit 0
}

# check for any arguements at all
if [[ $# == 0 ]] ; then
	usage
fi

#grab command-line arguements
while getopts ":i:p:b:" options; do
    case "${options}" in
        i)
            if [[ -f ${OPTARG} ]] ; then
           		inFSC=${OPTARG}
			echo ""
			echo "Found input statistics file: ${inFSC}"
			echo ""
            else
           		echo ""
           		echo "Error: could not input statistics file: ${inFSC}"
           		echo ""
           		usage
            fi
            ;;

	p)
	    if	[[ ${OPTARG} =~ ^[0-9]+([.][0-9]+)?$ ]] ; then
			pixelSize=${OPTARG}
	    else
			echo ""
			echo "Error: pixel size must be a positive number."
			echo ""
			usage
	    fi
	    ;;

	b)
	    if	[[ ${OPTARG} =~ ^[0-9]+$ ]] ; then
			boxSize=${OPTARG}
	    else
			echo ""
			echo "Error: box zie must be a positive integer."
			echo ""
			usage
	    fi
	    ;;

        *)
	            usage
            ;;
    esac
done
shift "$((OPTIND-1))"

# Check inputs
if [[ -z $inFSC ]] ; then

	echo ""
	echo "Error: No FSC file provided!"
	echo ""
	usage	
	
fi

if [[ -z $pixelSize ]] || [[ -z $boxSize ]] ; then
	echo""
	echo "Error: both pixel and box size must be set!"
	echo ""
	usage
fi

# Parse inputs
if [[ -z $(grep "wave_number" ${inFSC}) ]] || [[ -z $(grep "fsc_noisesub" ${inFSC}) ]] ; then

	echo ""
	echo "Error: Input file either does not contain a wave_number or a fsc_noisesub column...not much to do here."
	echo "Exiting..."
	echo ""
	usage
fi

# Give output a name
outFile="${inFSC%.*}.xml"

# Store header as an array
headerArr=$(head -n 1 ${inFSC})
headerArr=(${headerArr[@]})

# column variables initialize outside loop
fscNoiseSub=""
waveNum=""

# Find column numbers for fields of interest
for i in "${!headerArr[@]}"
do
	if [[ "${headerArr[$i]}" == "wave_number" ]] ; then
		waveNum=$((i+1))
	fi

	if [[ "${headerArr[$i]}" == "fsc_noisesub" ]] ; then
		fscNoiseSub=$((i+1))
	fi
done

if [[ -z ${waveNum} ]] || [[ -z ${fscNoiseSub} ]] ; then
	echo ""
	echo "Error: Could not get the column #'s for either wave_number or fsc_noisesub."
	echo "Exiting"
	echo ""
	exit
fi

# make data file (remove empty lines, header, and grab res and part_fsc columns)
fscData=${inFSC%.*}.dat
cat ${inFSC} | sed '/^$/d' | sed '1d' | awk -v px=$pixelSize -v box=$boxSize -v wv=$waveNum -v fsc=$fscNoiseSub '{print $wv/(px*box),$fsc}' > ${fscData}

echo ""
echo "Extracted FSC data, working on .xml file..."
echo "This can take a sec...have to do some math."
echo ""

# Read in data file as an array
readarray fscLines < ${fscData}

# Add header to .xml
if (true) ; then
	echo '<fsc title="cryoSPARC masked-corrected FSC" xaxis="Resolution (A-1)" yaxis="Correlation Coefficient">'
	echo '  <coordinate>'
	echo '   <x>0.0</x>'
	echo '   <y>1.0</y>'
	echo '  </coordinate>'
fi > ${outFile}

# convert resolution to spatial frequency and fill the .xml file
for i in "${fscLines[@]}"
do
	spatial_freq=$(echo $i | awk '{print $1}')
	fsc=$(echo $i | awk '{print $2}')
	
	echo '  <coordinate>'
	echo "   <x>$spatial_freq</x>"
	echo "   <y>$fsc</y>"
	echo '  </coordinate>' 
done >> ${outFile}

# Close .xml header/formatting 
echo '</fsc>' >> ${outFile}

echo ""
echo "A .xml version of the FSC for a cryoSPARC refinement has been written to:		${outFile}"
echo ""
echo "There is also a [Spatial-frequency, FSC] file for quick plotting:			${fscData}"
echo ""
echo "Script done!"
echo ""

exit 1
