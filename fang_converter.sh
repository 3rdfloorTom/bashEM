#!/bin/bash
#
#
##########################################################################################################
#
# Author(s): Tom Laughlin University of California-San Diego 2020
#
# This script coverts between Fourier pixels and real-space resolution (in Angstroms) using shell commands.
#
#
###########################################################################################################

#usage description
usage () 
{
	echo ""
	echo "This script converts between Fourier pixels and real-space resolution (in Angstroms) using shell commands"
	echo ""
	echo "Usage is:"
	echo ""
	echo "$(basename $0) [options]"
	echo ""
	echo "options list:"
	echo "	-p: pixel size in Angstroms		(required)"
	echo "	-b: box size in pixels			(required)"
	echo "	-r: Resolution in Angstroms		(optional, if -f provided)"
	echo "	-f: Resolution in Fourier pixels	(optional, if -r provided)"
	echo ""
	exit
}

#grab command-line arguements
while getopts ":p:b:r:f:" options; do
    case "${options}" in
        p)
            if [[ ${OPTARG} =~ ^[0-9]+([.][0-9]+)?$ ]] ; then
           		pixelSize=${OPTARG}
           	else
           		echo ""
           		echo "Error: pixel size must be a positive number."
           		echo ""
           		usage
           	fi
            ;;
        b)
            if [[ ${OPTARG} =~ ^[0-9]+([.][0-9]+)?$ ]] ; then
           		boxSize=${OPTARG}
           	else
           		echo ""
           		echo "Error: box size must be a positive number."
           		echo ""
           		usage
           	fi
            ;;
        r)
            if [[ ${OPTARG} =~ ^[0-9]+([.][0-9]+)?$ ]] ; then
           		resA=${OPTARG}
           	else
           		echo ""
           		echo "Error: Angstrom resolution must be a positive number."
           		echo ""
           		usage
           	fi
            ;;
        f)
            if [[ ${OPTARG} =~ ^[0-9]+([.][0-9]+)?$ ]] ; then
           		resF=${OPTARG}
           	else
           		echo ""
           		echo "Error: Fourier resolution must be an integer."
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

## Check for required arguements
if [[ -z $pixelSize ]] || [[ -z $boxSize ]] ; then
	echo ""
	echo "Error: Pixel and box sizes must be set!"
	echo ""
	usage
fi

nqAng=$(echo "2*$pixelSize" | bc)

nqF=$((boxSize/2))

boxAng=$(echo "$pixelSize*$boxSize" | bc)



## Check that either only 'a' of 'f' is set
if [[ -z $resA ]] && [[ -z $resF ]] ; then

	echo ""
	echo "Error: Either -a or -f must be set!"
	echo ""
	usage

elif [[ -n $resA ]] && [[ -n $resF ]] ; then

	echo ""
	echo "Error: Both -a and -f cannot simultaneously be set!"
	echo ""
	usage

elif [[ -n $resA ]] ; then
	
	if (( $(echo "$resA < $nqAng" | bc -l) )) ; then
		
		echo ""
		echo "Error: Target Angstrom resolution cannot be greater than Nyquist: $nqAng"
		echo ""
		usage
	fi

	fourierPx=$(echo "$boxAng/$resA" | bc )
	resAng=$(echo "scale = 2; $boxAng/$fourierPx" | bc)

	echo ""
	echo "Resolution of $resA Angstroms converted to Fourier pixels is around: 	$fourierPx"
	echo "To be more accurate, $fourierPx Fourier pixels Angstrom resolution of:	 $resAng"
	echo ""

else
	if (( $(echo "$resF > $nqF" | bc -l) )) ; then
		
		echo ""
		echo "Error: Target Angstrom resolution cannot be greater than Nyquist: $nqF"
		echo ""
		usage
	fi

	resAng=$(echo "scale = 2; $boxAng/$resF" | bc)
	
	echo ""
	echo "Resolution of $resF Fourier Pixel converted to an Angstrom resolution of:	 $resAng"
	echo ""

fi


exit
