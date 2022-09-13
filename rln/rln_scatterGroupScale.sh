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
	echo "This scripts plots a scatter plot of the GroupScaleCorrection from a model star file"
	echo ""
	echo "It uses gnuplot for plotting and Eye of Gnome for display of the histogram at the end."
	echo ""
	echo "Usage is:"
	echo ""
	echo "$(basename $0) -i input.star"
	echo ""
	echo "options list:"
	echo "	-i: model.star generated from a RELION		(required)"
	echo ""
	exit 0
}

# set default values
bins=100

# check for any arguements at all
if [[ $# == 0 ]] ; then
	usage
fi

#grab command-line arguements
while getopts ":i:" options; do
    case "${options}" in
        i)
            if [[ -f ${OPTARG} ]] ; then
           		inStar=${OPTARG}
			echo ""
			echo "Found input starfile: ${inStar}"
			echo ""
            else
           		echo ""
           		echo "Error: could not input starfile: ${inStar}"
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
if [[ -z $inStar ]] ; then

	echo ""
	echo "Error: No star file provided!"
	echo ""
	usage	
	
fi

if [[ -z $(grep "_rlnGroupScaleCorrection" ${inStar}) ]] ; then

	echo ""
	echo "Error: Input file does not contain a _rlnGroupScaleCorrection column...are you sure this in a run_model.star?"
	echo "Exiting..."
	echo ""
	usage
fi

# Give output a name
outFile="${inStar%.*}_scatter_gsc.dat"

# Get field of interest
gscField=$(grep "_rlnGroupScaleCorrection" ${inStar} | awk '{print $2}' | sed 's|#||')

# Sort data lines based on autopick FOM
awk -v gsc=$gscField '{if ($0 ~ /.mrc/) {print $1,$gsc}}' ${inStar} > ${outFile}

# First line of .mrc references the map reference
sed -i -e "1d" ${outFile}
count=$(wc -l ${outFile} | awk '{print $1}')

echo ""
echo "There are values for $count micrographs."
echo ""
echo "Now preparing plot..."
echo ""

xmax=$(tail -n 1 ${outFile} | awk '{print $1}')

# gnuplot 
gnuplot <<- EOF
set key off
set border 4095

set size ratio 0.25
set terminal pngcairo noenhanced font "arial,10" fontscale 1.0 size 1260,680
set output "${outFile%.*}_scatter.png"

set title "_rlnGroupScaleCorrection: \n ${inStar}"
set ylabel "value"
set xlabel "micrograph index"

set yrange [0:1.5]
set grid ytics
set ytics 0,0.1,1.5

set xrange [0:$xmax]
set grid xtics
set xtics 0,250,$xmax

set style fill transparent solid 0.5
set style circle radius 15

plot "$outFile" using 1:2 with circles lc rgb "royalblue" lw 0.5
EOF

eog ${outFile%.*}_scatter.png &

# tidy-up
#rm ${outFile}

echo ""
echo "Plot will display shortly...Eye of Gnome can take a minute of some manchines."
echo ""
echo "Script done!"
echo ""

exit 1
