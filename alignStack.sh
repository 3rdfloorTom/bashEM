#!/bin/bash
#
#!/bin/bash
#
#
############################################################################
#
# Author: "Thomas (Tom) Laughlin"
# @ UCSD 2020
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


#usage description
usage () 
{
	echo ""
	echo "Rather simple wrapper to IMOD's newstack to align a stack based on precomputed transforms"
	echo "Useful for when upsampling and not wanting to redo everything from scratch"
  echo ""
	echo "Usage is:"
	echo ""
	echo "$(basename $0) -i input.st -o outRootName -x transformsFile.xf -b binningFactor"
	echo ""
	echo "options list:"
	echo "		-i: input stack (.st) file    						     (required)"
	echo "		-o: rootname for output files (if different than input, e.g. 'volume01')     (optional)"
	echo "		-x: transforms file from etomo (.xf) 					     (required)"
	echo "   		-b: binning factor for output aligned stack (.ali) file  		     (optional, default is no binning)"
	echo ""
	exit 0
}

# Check for inputs
if [[ $# == 0 ]] ; then
  usage
fi

# Grab command-line arguements
while getopts ":i:o:x:b:" options; do
    case "${options}" in
        i)
            if [[ -f ${OPTARG} ]] ; then
           		inStack=${OPTARG}
           		echo ""
           		echo "Found ${inStack}"
           		echo ""
           	else
           		echo ""
           		echo "Error: Cannot find file named ${inStack}"
           		echo "exiting..."
           		echo ""
           		usage
           	fi
            ;;
        o)
           	outRootName=${OPTARG}
            ;;
        x)
          if [[ -f ${OPTARG} ]] ; then
            transformsFile=${OPTARG}
            echo ""
            echo "Found ${transformsFile}"
          else
            echo ""
            echo "Error: Cannot find file named ${transformsFile}"
            echo "exiting..."
            echo ""
            usage
          fi
          ;;
        b)
            if [[ ${OPTARG} =~ ^[0-9]+$ ]] ; then
           		binningFactor=${OPTARG}
           	else
           		echo ""
           		echo "Error: Scaling factor must be a positive integer, if invoked."
           		echo "exiting..."
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


# Check the optional inputs and set to defaults, if necessary
if [[ -z "$outRootName" ]] ; then

	outRootName="${inFile%.*}"

	echo ""
	echo "Outname is not set..."
	echo "Using input file rootname of ${outName} for output files."
	echo ""
fi

# Make full output name
outputName="${outRootName}.ali"

# Check if ouput file exists and back it up if so
if [[ -f ${outputName} ]] ; then
  
  echo "A file ${outputName} already exists in this directory."
  echo "Converting pre-existing file to ${outputName}.bak"

  mv ${outputName} ${outputName}".bak"

fi

echo ""
echo "Now running newstack...this can take some time, please be patient :)"
echo ""

if [[ -z ${binningFactor} ]] || [[ ${binningFactor} -le 1 ]]   ; then
  newstack \
  -in ${inStack} \
  -LinearInterpolation \
  -x ${transformsFile} \
  -out ${outputName} \
  -TaperAtFill 1,0 \
  -AdjustOrigin \
  -OffsetsInXandY 0.0,0.0 > ${outRootName}"_align.log"
else
  newstack \
  -in ${inStack} \
  -LinearInterpolation \
  -bin ${binningFactor} \
  -an -1 \
  -x ${transformsFile} \
  -out ${outputName} \
  -TaperAtFill 1,0 \
  -AdjustOrigin \
  -OffsetsInXandY 0.0,0.0 > ${outRootName}"_align.log"
fi

echo ""
echo "Finished running newstack to create:     ${outputName}"
echo "Previous aligned stack may now be name:    ${outputName}.bak"
echo ""

exit 1



