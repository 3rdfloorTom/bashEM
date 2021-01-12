#!/bin/bash
#
#
##########################################################################################################
#
# Author(s): Tom Laughlin University of California-San Diego 2021
#		
#		adaptation from suggesting in forum by Tim Grant
# 
#
###########################################################################################################

#usage description
usage () 
{
	echo ""
	echo "This scripts converts the statistics.txt file from Frealign/cisTEM containing partFSC information into a .xml format for EMDB deposition."
	echo "NOTE: this script requires the function 'calc' to be installed (if you have a cuda-enabled IMOD install, it should already be present)."
	echo ""
	echo "Functional portion of code based on suggestion by Tim Grant."
	echo ""
	echo "Usage is:"
	echo ""
	echo "$(basename $0) -i mystatistics.txt"
	echo ""
	echo "options list:"
	echo "	-i: .par file output from a Frealign/cisTEM refinement run			(required)"
	echo ""
	exit 0
}

# set default values (not happy about hard-codings, but for a first pass...)
partFSC_col=6
res_col=3

# check for any arguements at all
if [[ $# == 0 ]] ; then
	usage
fi

#grab command-line arguements
while getopts ":i:" options; do
    case "${options}" in
        i)
            if [[ -f ${OPTARG} ]] ; then
           		inStats=${OPTARG}
			echo ""
			echo "Found input statistics file: ${inStats}"
			echo ""
            else
           		echo ""
           		echo "Error: could not input statistics file: ${inStats}"
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
if [[ -z $inStats ]] ; then

	echo ""
	echo "Error: No Statistics file provided!"
	echo ""
	usage	
	
fi

if [[ -z $(grep "Part_FSC" ${inStats}) ]] || [[ -z $(grep "RESOLUTION" ${inStats}) ]] ; then

	echo ""
	echo "Error: Input file either does not contain a Part_FSC or a RESOLUTION column...not much to do here."
	echo "Exiting..."
	echo ""
	usage
fi

# Give output a name
outFile="${inStats%.*}.xml"

# Store header as an array
headerArr=$(head -n 1 ${inStats})
headerArr=(${headerArr[@]})

# column variables initialize outside loop
partFSCcol=""
resCol=""

# Find column numbers for fields of interest (header has a leading 'C' that doesn't have a data column, so off-by-one indexing fixes things...weird)
for i in "${!headerArr[@]}"
do
	if [[ "${headerArr[$i]}" == "RESOLUTION" ]] ; then
		resCol=$i
	fi
	
	if [[ "${headerArr[$i]}" == "Part_FSC" ]] ; then
		partFSCcol=$i
	fi
done

if [[ -z ${resCol} ]] || [[ -z ${partFSCcol} ]] ; then
	echo ""
	echo "Error: Could not get the column #'s for either RESOLUTION or Part_FSC."
	echo "Exiting"
	echo ""
	exit
fi

# make data file (remove empty lines, header, and grab res and part_fsc columns)
fscData=${inStats%.*}.dat
cat ${inStats} | sed '/^$/d' | sed '1d' | awk -v res=$resCol -v partF=$partFSCcol '{print 1/$res,$partF}' > ${fscData}

echo ""
echo "Extracted FSC data, working on .xml file..."
echo "This can take a sec...have to do some math."
echo ""

# Read in data file as an array
readarray fscLines < ${fscData}

# Add header to .xml
if (true) ; then
	echo '<fsc title="Frealign/cisTEM Solvent-corrected particle FSC" xaxis="Resolution (A-1)" yaxis="Correlation Coefficient">'
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
echo "A .xml version of the FSC for a Frealign/cisTEM refinement has been written to:		${outFile}"
echo ""
echo "There is also a [Spatial-frequency, FSC] file for quick plotting:	${fscData}"
echo ""
echo "Script done!"
echo ""

exit 1
