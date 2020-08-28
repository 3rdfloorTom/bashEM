#!/bin/bash
#
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

# Usage description
usage () 
{
	echo ""
	echo "Rather simple wrapper to IMOD's newstack & tilt program to create the tomogram by WBP and rotates about x"
        echo "This scripts assumes K2 frames (i.e., 3838 x 3710) and all necessary files are in working directory"
	echo "Files such as: .st, .tlt, .xf*, *not necessary if no xtilt"
	echo "Useful for when upsampling and not wanting to redo everything from scratch"
        echo ""
	echo "Usage is:"
	echo ""
	echo "$(basename $0) -i input.st -o outDirectory -b binning -h thickness -d"
	echo ""
	echo "options list:"
	echo "		-i: input aligned stack (.st) file						    (required)"							
	echo "		-o: directory name for all output files					    	    (optional, default is reconTomo)"
	echo "		-b: binning factor 			  					    (optional, default is no binning)"
  	echo "		-h: reconstruction thickness in voxels		 				    (optional, default is a generous 1500)"
	echo "		-d: invoke if input.st is nonDW, but alignment data are DW			    (optional)" 
	echo ""
	exit 0
}


# Check for inputs
if [[ $# == 0 ]] ; then
  usage
fi

# Grab command-line arguements
while getopts ":i:o:b:h:d" options; do
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
           	outDirectory=${OPTARG}
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

	 d)
	    namesDW=1
            ;;
        *)
            usage
            ;;
    esac
done
shift "$((OPTIND-1))"


# Check the optional inputs and set to defaults, if necessary
if [[ -z ${outDirectory} ]] ; then

	echo ""
	echo "Output directory is not set..."
	echo "Using ouput directory default name: 	reconTomo"
	echo ""
fi

if [[ -d ${outDirectory} ]] ; then
	
	echo ""
	echo "Target output directory ${outDirectory} already exists."
	echo "Proceeding as intended."
	echo ""
else
	echo ""
	echo "Could not find a pre-existing ${outDirectory}"
	echo "Creating output directory with name ${outDirectory}"
	echo ""
	mkdir -p ${outDirectory}
fi


echo ""
echo "Now working on creating aligned stack for ${inStack}"
echo ""

# Get rootnames for files

stackRootName=${inStack%.st}
recName="${outDirectory}/${stackRootName}_full.rec"

if [[ -f ${recName} ]] ; then

	echo ""
	echo "The reconstruction ${recName} already exists!
	echo "If you wish to redo this reconstruction, first delete this file."
	echo ""
else

	if [[ ${namesDW} ]] ; then

		echo ""
		echo "Input stack is nonDW, but necessary files have DW in name."
		echo "Proceeding accordingly"
		echo ""

		auxFileRootName=${stackRootName}"_DW"
	else
		auxFileRootName=${stackRootName}

	fi

	# Make file names for newstack
	transformsFile=${auxFileRootName}".xf"
	alignStackName="${outDirectory}/${stackRootName}.ali"

	# Check for existence of transforms file
	if [[ -f ${transformsFile} ]] ; then
	
	echo ""
	echo "Found transforms file:	${transformsFile}"
	echo ""
	
	else
		echo ""
		echo "Could not find ${transformsFile}"
		echo "exiting..."
		exit 0

	fi

	echo ""
	echo "Now running newstack...this can take some time, please be patient :)"
	echo ""

	if [[ -z ${binningFactor} ]] || [[ ${binningFactor} -le 1 ]]   ; then
 		 newstack \
 		 -in ${inStack} \
 		 -LinearInterpolation \
  		 -x ${transformsFile} \
 	         -out ${alignStackName} \
  		 -TaperAtFill 1,0 \
 		 -AdjustOrigin \
  		 -OffsetsInXandY 0.0,0.0 > "${outDirectory}/${stackRootName}_align.log"
	else
 		 newstack \
  		 -in ${inStack} \
  		 -LinearInterpolation \
  		 -bin ${binningFactor} \
  		 -an -1 \
  		 -x ${transformsFile} \
  		 -out ${alignStackName} \
  		 -TaperAtFill 1,0 \
  		 -AdjustOrigin \
  		 -OffsetsInXandY 0.0,0.0 > "${outDirectory}/${stackRootName}_align.log"
	fi

	echo ""
	echo "Finished running newstack to create:     ${alignStackName}"
	echo ""

	# Make sure thickness is set or define default
	if [[ -z ${thickness} ]] ; then
 		 thickness=1500
  		echo ""
  		echo " Using default thickness:   ${thickness}"
  		echo ""
	fi


	# Get the size of the aligned stack
	sizeX=$(header -s ${alignStackName} | awk '{print $1}')
	sizeY=$(header -s ${alignStackName} | awk '{print $2}')
	sizeZ=$(header -s ${alignStackName} | awk '{print $3}')


	echo "The size of the aligned stack is: $sizeX $sizeY $sizeZ. Unbinned frame size in X and Y is to be assumed equal to 3838 3710."

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

	# Make file names for tilt files
	tiltFile=${auxFileRootName}".tlt"
	xtiltFile=${auxFileRootName}".xtilt"

	# Check for tilt file
	if [[ -f ${tiltFile} ]] ; then
	
		echo ""
		echo "Tilt angle information found in file:	${tiltFile}"
		echo ""
	# Moving into target directory for personal convience
		cp ${tiltFile} "${outDirectory}/${stackRootName}.tlt" 
	else
		echo ""
		echo "Error: Could not find tilt angle file:	${tiltFile}"
		echo "exiting..."
		echo ""
		exit 0
	fi

	# Check if xtilt file not present, spoof one
	if [[ ! -f ${xtiltFile} ]] ; then

		echo ""
		echo "Could not find ${xtiltFile}"
		echo "Assuming no xtilt and making an empty (all '0.00') file to run tilt"
		echo ""

		touch ${xtiltFile}

		for (( i = 0 ; i < ${sizeZ} ; i++ ))
		do
			echo "0.00" >> ${xtiltFile}
		done
	else
		echo ""
		echo "Found ${xtiltFile}"
		echo ""
	fi

	# Perform WBP using IMOD's tilt command
	echo "Detected binning factor of ${bin}"
	echo "Proceeding with weighted back projection...please be patient"

	tilt \
	-InputProjections ${alignStackName} \
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
	-UseGPU 0 \
	-ActionIfGPUFails 1,2 > "${outDirectory}/${stackRootName}_tiltlog.txt"


	# Check if WBP was successful
	if [[ -f tmp.rec ]]; then
    		echo "Completed back projection. Now rotating around X..."
	else
    		echo "Something went wrong. Exiting"
    		exit 0
	fi

	# Rotate tomogram to position tilt-axis about Y
	trimvol -rx tmp.rec ${recName} >> "${outDirectory}/${stackRootName}_tiltlog.txt"


	# Check and report if everything work, if so, then remove non-rotated tomogram.
	if [[ -f ${recName} ]] ; then
 		 echo "Tomogram reconstructed, rotated about x, and written out as:  ${recName}"
 		 rm tmp.rec
	else
    		echo "Tomogram rotation failed...check tmp.rec"
	fi
fi

exit 1
