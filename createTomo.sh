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
	echo "Rather simple wrapper to IMOD's tilt program to create the tomogram by WBP and rotates about x"
        echo "The script guesses the binning from .ali header, assuming K2 frames (i.e., 3838 x 3710)"
	echo "Useful for when upsampling and not wanting to redo everything from scratch"
        echo ""
	echo "Usage is:"
	echo ""
	echo "$(basename $0) -i input.ali -o outRootName -t tiltFile -x tiltFile -h thickness"
	echo ""
	echo "options list:"
	echo "		-i: input aligned stack (.ali) file 						    (required)"
	echo "		-o: rootname for output files (if different than input, e.g. 'volume01')    	    (optional)"
	echo "		-t: tilt file (.tlt)    							    (required)"
	echo "   		-x: xtilt file (.xtilt) file   							    (required)"
  	echo "   		-h: thickness in voxels    							    (optional, default is a generous 1500)"
	echo ""
	exit 0
}

# Check for inputs
if [[ $# == 0 ]] ; then
  usage
fi

# Grab command-line arguements
while getopts ":i:o:t:x:h:" options; do
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
        t)
          if [[ -f ${OPTARG} ]] ; then
            tiltFile=${OPTARG}
            echo ""
            echo "Found ${tiltFile}"
          else
            echo ""
            echo "Error: Cannot find file named ${tiltFile}"
            echo "exiting..."
            echo ""
            usage
          fi
          ;;
        x)
          if [[ -f ${OPTARG} ]] ; then
            xtiltFile=${OPTARG}
            echo ""
            echo "Found ${xtiltFile}"
          else
            echo ""
            echo "Error: Cannot find file named ${xtiltFile}"
            echo "exiting..."
            echo ""
            usage
          fi
          ;;
        h)
            if [[ ${OPTARG} =~ ^[0-9]+$ ]] ; then
           		thickness=${OPTARG}
           	else
           		echo ""
           		echo "Error: Thickness must be a positive integer, if invoked."
           		echo "Using default value of 1500"
           		echo ""
           		
        	       thickness=1500
	
            fi
            ;;
        *)
            usage
            ;;
    esac
done
shift "$((OPTIND-1))"

# Make sure thickness is set or define default
if [[ -z ${thickness} ]] ; then
  thickness=1500
  echo ""
  echo " Using default thickness:   ${thickness}"
  echo ""
fi

# Check the optional inputs and set to defaults, if necessary
if [[ -z "$outRootName" ]] ; then

	outRootName="${inFile%.*}"

	echo ""
	echo "Outname is not set..."
	echo "Using input file rootname of ${outName} for output files."
	echo ""
fi

# Make fulle output name
outputName=${outRootName}".rec"

# Check if ouput file exists and back it up if so
if [[ -f ${outputName} ]] ; then
  
  echo "A file ${outputName} already exists in this directory."
  echo "Converting pre-existing file to ${outputName}.bak"

  mv ${outputName} ${outputName}".bak"

fi

# Get the size of the aligned stack
sizeX=$(header -s ${inStack} | awk '{print $1}')
sizeY=$(header -s ${inStack} | awk '{print $2}')
sizeZ=$(header -s ${inStack} | awk '{print $3}')


echo "The size of the input stack is: $sizeX $sizeY $sizeZ. Unbinned frame size in X and Y is to be assumed equal to 3838 3710."

if [[ ${sizeX} -lt 4000 ]] && [[ ${sizeX} -gt 2000 ]] ; then
  bin=1

elif [[ ${sizeX} -lt 2000 ]] && [[ ${sizeX} -gt 1500 ]] ; then
  bin=2

elif [[ ${sizeX} -lt 1500 ]] && [[ ${sizeX} -gt 1000 ]] ; then
  bin=3

elif [[ ${sizeX} -lt 1000 ]] && [[ ${sizeX} -gt 800 ]]  ; then
  bin=4

elif [[ ${sizeX} -lt 800 ]] && [[ ${sizeX} -gt 670 ]] ; then
  bin=5

elif [[ $sizeX -lt 670 ]] && [[ ${sizeX} -gt 570 ]] ; then
  bin=6

else
  echo "This script cannot handle such high binning factors."
  exit 0
fi

echo "Detected binning factor: ${bin}."
echo "Proceeding with weighted back projection..."


# Perform WBP using IMOD's tilt command

tilt \
-InputProjections ${inStack} \
-OutputFile tmp.rec \
-TILTFILE ${tiltFile} \
-XTILTFILE ${xtiltFile} \
-THICKNESS ${thickness} \
-OFFSET 0.0 \
-SHIFT 0.0,0.0 \
-XAXISTILT 0.0 \
-FULLIMAGE 3838,3710 \
-SUBSETSTART -1,-1 \
-IMAGEBINNED ${bin} \
-RADIAL 0.35,0.035 \
-FalloffIsTrueSigma 1 \
-MODE 2 \
-PERPENDICULAR 1 \
-AdjustOrigin 1 \
-SCALE 0.0,0.05 \
-ActionIfGPUFails 1,2 > ${outRootName}"_tiltlog.txt"


# Check if WBP was successful
if [[ -f tmp.rec ]]; then
    echo "Completed back projection the tomogram. Rotating around X..."
else
    echo "Something went wrong. Exiting"
    exit 0
fi

# Rotate tomogram to position tilt-axis about Y
trimvol -rx tmp.rec ${outputName} >> ${outRootName}"_tiltlog.txt"


# Check and report if everything work, if so, then remove non-rotated tomogram.
if [[ -f ${outputName} ]] ; then
  echo "Tomogram reconstructed, rotated about x, and written out as:  ${outputName}"
  rm tmp.rec
else
    echo "Tomogram rotation failed...check tmp.rec"
fi

exit 1
