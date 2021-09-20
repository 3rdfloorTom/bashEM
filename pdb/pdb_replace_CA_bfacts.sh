#!/bin/bash
#
#
##########################################################################################################
#
# Author(s): Tom Laughlin University of California-San Diego 2021
#
# 
#
###########################################################################################################

#usage description
usage () 
{
	echo ""
	echo "This script replaces the B-factor vaules of CA entries in a .pdb-format coordinate file using a user provided list of values."
	echo "The user-provided list is expected to match the order of CA entries."
	echo ""
	echo "Note: the values of the user-provided list are normalized to the maximum value."
	echo ""
	echo "Usage is:"
	echo ""
	echo "	$(basename $0) -i input.pdb -l ordered_CA_pseudo_Bfactor_list.txt"
	echo ""
	echo "options list"
	echo "	-i: pdb-formatted coordinate file for which the CA B-factors are to be replaced			(required)"
	echo "	-l: order list of pseudo CA B-factors to use for repalcement					(required)"
	echo ""
	exit 0
}

# check for any arguements at all
if [[ $# == 0 ]] ; then
	usage
fi

#grab command-line arguements
while getopts ":i:l:" options; do
    case "${options}" in
        i)
            if [[ -f ${OPTARG} ]] ; then
           		inPDB=${OPTARG}
				
				echo ""
				echo "Found input coordinate file: ${inPDB}"
				echo ""
            else
           		echo ""
           		echo "Error: could not find coordinate file: ${inPDB}"
           		echo ""
           		usage
            fi
            ;;
         l)
            if [[ -f ${OPTARG} ]] ; then
           		bList=${OPTARG}

           		echo ""
				echo "Found input B-factor list: ${bList}"
				echo ""
            else
           		echo ""
           		echo "Error: could not find input B-factor list: ${bList}"
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

if [[ -z ${inPDB} ]] || [[ -z ${bList} ]] ; then

	echo ""
	echo "One of the input files is not set!"
	echo "Both a coordinate and list file are required for the script to run."
	echo "Exiting..."
	usage

fi

# Give output a name
outPDB="${inPDB%.*}_$(basename ${bList%.*})_CAs.pdb"

if [[ -f ${outPDB} ]] ; then
	echo ""
	echo "A ${outPDB} already exists!"
	echo "Renaming as ${outPDB}.bak"
	echo ""

	mv ${outPDB} "${outPDB}.bak"
fi

# get length of b-factor list
listLength=$(wc -l ${bList} | awk '{print $1}')

echo ""
echo "Number of CA pseudo-B-factors for replacing:	${listLength}"
echo ""

# find max value in pseudo-bfactor list 
max=$(cat ${bList} | sort -rg | head -n 1)
# map normalized list into an array indexed starting at 0
mapfile -t bList_arr < <(awk -v max=$max '{print $0/max}' ${bList})


echo ""
echo "Replacing CA B-factors in:	${inPDB}"
echo "with normalized values from:	${bList}"
echo ""
echo "This process is poorly optimized and can take a couple minutes..."
echo ""

# initialize counter
counter=0

# Here comes the wild part...strap-in!!!!
# Step through the file residue by residue
# ...This can take a minute or two

while read -r lineType atomID name resn chain resi x y z occ bfac element remainder;
do
	if [[ $lineType == "ATOM" ]] ; then
       
       if [[ $name == "CA" ]] ; then
       	
       	bfac=${bList_arr[$counter]}

       	((counter++))
       
       fi

		printf "%4s%7i%5s%4s%2s%4i    %8.3f%8.3f%8.3f%6.2f%6.2f%12s    \n" $lineType $atomID $name $resn $chain $resi $x $y $z $occ $bfac $element

	elif [[ $lineType == "TER" ]] ; then

		printf "TER\n"

	fi
done < ${inPDB} > ${outPDB}

wait

echo ""
echo "Number of CA B-factors replaced:	${counter}"
echo ""
echo "Edited coordinate file written out at:	${outPDB}"
echo ""
echo "Script done!"
echo ""
