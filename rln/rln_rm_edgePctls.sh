#!/bin/bash
#
#
##########################################################################################################
#
# Author(s): Tom Laughlin University of California-San Diego 2022
#
# 
#
###########################################################################################################

#usage description
usage () 
{
	echo ""
	echo "This scripts removes particles within a specified distance (in pixels) from the micrograph edge"
	echo ""
	echo "NOTE: This script does not consider the particle shifts in determinaing distance to edge"
	echo ""
	echo "Usage is:"
	echo ""
	echo "$(basename $0) -i input.star -x mic_X_dim -y mic_Y_dim -d dist_in_px"
	echo ""
	echo "options list:"
	echo "	-i: .star generated from a RELION		     	 (required)"
	echo "	-x: X dimension of micrographs				 (required)"
	echo "	-y: Y dimension of micrographs				 (required)"
	echo "	-d: minimum distance to edge of micrographs	 	 (required)"
	echo ""
	exit 0
}

# check for any arguements at all
if [[ $# == 0 ]] ; then
	usage
fi

#grab command-line arguements
while getopts ":i:x:y:d:" options; do
    case "${options}" in
        i)
                if [[ -f ${OPTARG} ]] ; then
           		inStar=${OPTARG}
				echo ""
				echo "Found input starfile:	${inStar}"
				echo ""
                else
           			echo ""
           			echo "Error: could not input starfile:	${inStar}"
           			echo ""
           			usage
                fi
                ;;
	x)
	    	if	[[ ${OPTARG} =~ ^[0-9]+$ ]] ; then
				xdim=${OPTARG}
	    	else
				echo ""
				echo "Error: The X dimension of the micrographs must be a postive integer!"
				echo ""
	    	fi
	
	    	;;

	y)
	    	if	[[ ${OPTARG} =~ ^[0-9]+$ ]] ; then
				ydim=${OPTARG}
	    	else
				echo ""
				echo "Error: The Y dimension of the micrographs must be a postive integer!"
				echo ""
	    	fi
	
	    	;;

	d)
	    	if	[[ ${OPTARG} =~ ^[0-9]+$ ]] ; then
				dist=${OPTARG}
	    	else
				echo ""
				echo "Error: The minimum distance from micrograph edge must be a postive integer!"
				echo ""
	    	fi
	
	    	;;


    *)
	            usage
            ;;
    esac
done
shift "$((OPTIND-1))"

# Check inputs
if [[ -z $inStar ]] ; then

	echo ""
	echo "Error: No star file provided!"
	echo ""
	usage	
	
fi

if [[ -z $xdim ]] || [[ -z $ydim ]] || [[ -z $dist ]] ; then

	echo ""
	echo "Error: Either the micrograph dimensions or the minimal distance was not provided"
	echo ""
	usage	
	
fi


if [[ -z $(grep "_rlnCoordinate" ${inStar}) ]] ; then

	echo ""
	echo "Error: Input file does not contain a _rlnDefocusX/Y column...not much to do here."
	echo "Exiting..."
	echo ""
	usage
fi

count_in=$(grep .mrc ${inStar} | wc -l | awk '{print $1}')

echo ""
echo "The input star file contains $count_in particles."
echo ""

echo ""
echo "Now removing particles within ${dist} pixels from micrograph edges..."

# Give output a name and copy header from input file
outFile="${inStar%.*}_${dist}_fromEdge.star"
awk '{if ($0 !~ /.mrc/) {print $0}}' ${inStar} > ${outFile}

echo "."

# Get coordinate fields
coordXField=$(grep "_rlnCoordinateX" ${inStar} | awk '{print $2}' | sed 's|#||')
coordYField=$(grep "_rlnCoordinateY" ${inStar} | awk '{print $2}' | sed 's|#||')
echo ".."

# select particle lines based on min/max dimensions
awk -v xmax=$((xdim-dist)) -v ymax=$((ydim-dist)) -v min=$dist -v coordX=$coordXField -v coordY=$coordYField '{if ( $0 ~ /.mrc/ && $coordX > min && $coordX < xmax && $coordY > min && $coordY < ymax ) {print $0}}' ${inStar} >> ${outFile}

echo "..."
count_out=$(grep .mrc ${outFile} | wc -l | awk '{print $1}')

echo "The output star file contains $count_out particles."
echo ""
echo "Output star file written out as:	${outFile}"
echo ""
echo "Script done!"
echo ""

exit 1
