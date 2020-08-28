#!/bin/bash
#
#
##########################################################################################################
#
# Author(s): Tom Laughlin University of California-San Diego 2020
#
# 
#
###########################################################################################################

#usage description
usage () 
{
	echo ""
	echo "This scripts generates a rln_tomograms.star and particles .coords files from a Dynamo .tbl"
	echo "The intent is to use the output to extract 2D-projections for RELION Class2D."
	echo ""
	echo "This script assumes that the full paths for the tomograms is in the index doc."
	echo ""
	echo "No shifts will be applied to the particle origins as it assumed that this is from an initial cropping."
	echo "To apply shifts, do so to the .tbl with matlab or awk first."
	echo "Usage is:"
	echo ""
	echo "$(basename $0) -i inputTable.tbl -d indicesColumn20.doc"
	echo ""
	echo "options list:"
	echo "	-i: input .tbl from Dynamo					(required)"
	echo "	-d: output directory for .coord files				(required)"
	exit 0
}

# check for any arguements at all
if [[ $# == 0 ]] ; then
	usage
fi

#grab command-line arguements
while getopts ":i:d:" options; do
    case "${options}" in
        i)
            if [[ -f ${OPTARG} ]] ; then
           		inTbl=${OPTARG}
			echo ""
			echo "Found input:	${inTbl}"
			echo ""
            else
           		echo ""
           		echo "Error: could not find ${inTbl}"
           		echo ""
           		usage
            fi
            ;;
        d)
            if [[ -f ${OPTARG} ]] ; then
           		tomoIdx=${OPTARG}
			echo ""
			echo "Found input:	${tomoIdx}"
			echo ""
            else
           		echo ""
           		echo "Error: could not find ${tomoIdx}"
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

# Check for set inputs
if [[ -z ${inTbl} ]] || [[ -z ${tomoIdx} ]] ; then
	
	echo ""
	echo "One of the inputs is not set!"
	echo "Both the .tbl and .doc are required inputs"
	echo "Exiting..."

	usage
	
fi


# Sanity checks
numPctls=$(wc -l ${inTbl} | awk '{print $1}')
numTomos=$(wc -l ${tomoIdx} | awk '{print $1}')

echo ""
echo "Found coordinates for ${numPctls} from ${numTomos}"
echo ""

# Output directories
outDir="relion2D"
tomoDir="Tomograms"


# Output tomo list
tomoStar="${outDir}/rln_tomos.star"

# Make output directory
if [[ -d ${outDir} ]] ; then
	
	echo ""
	echo "A pre-existing ${outDir} has been found."
	echo "Please delete or rename before continuing."
	echo "Exiting..."
	echo ""
	exit 0	
else
	mkdir ${outDir}
fi


while read -r Idx tomoFull remainder
do
	# Parse tomogram name 
	tomoName=$(basename ${tomoFull})
		
	# Make tomogram specific directory
	mkdir -p "${outDir}/${tomoDir}/${tomoName}"

	# Soft-link and add extension to make Relion happy
	ln -s ${tomoFull} "${outDir}/${tomoDir}/${tomoName}/${tomoName}.mrc"
	
	awk -v Idx=$Idx '{if ($20 == Idx) {print $24,$25,$26}}' ${inTbl} > "${outDir}/${tomoDir}/${tomoName}/${tomoName}.coords"
	
	# Coordinate count
	count=$(wc -l "${outDir}/${tomoDir}/${tomoName}/${tomoName}.coords" | awk '{print $1}')	

	echo "Wrote out ${count} coordinates for ${tomoName}"

done < ${tomoIdx}

# Make the tomogram star file
echo "data_" > ${tomoStar}
echo "loop_" >> ${tomoStar}
echo "_rlnMicrographName" >> ${tomoStar}
ls "${outDir}/${tomoDir}/"*"/"*.mrc | sed -r "s:\x1B\[[0-9;]*[mK]]::g" | sed "s|${outDir}/||g" >> ${tomoStar}

# Make copies for the .tbl and .doc in the outDir to help with locating for back-conversion
cp ${inTbl} "${outDir}/${inTbl}"
cp ${tomoIdx} "${outDir}/${tomoIdx}"

echo ""
echo "Finished writing coordinate files and linking all tomograms to ${outDir}/ for use in RELION"
echo ""
echo "Also wrote out ${tomoStar}"
echo ""
echo "Import the ${tomoStar} and .coords files for Extract with the --project3d flag to perform Class2D of subtomograms"
echo ""
echo "Script done!"
echo ""

exit 1
