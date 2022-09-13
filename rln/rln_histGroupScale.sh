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
	echo "This scripts plots a histogram of the GroupScaleCorrection from a model star file"
	echo ""
	echo "It uses gnuplot for plotting and Eye of Gnome for display of the histogram at the end."
	echo ""
	echo "Usage is:"
	echo ""
	echo "$(basename $0) -i input.star -b bins"
	echo ""
	echo "options list:"
	echo "	-i: .star generated from a RELION		(required)"
	echo "	-b: number of bins to use for historgram	(optional, default=100)"
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
while getopts ":i:b:" options; do
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
	b)
	    if	[[ ${OPTARG} =~ ^[0-9]+$ ]] ; then
			bins=${OPTARG}
	    else
			echo ""
			echo "Error: the bins parameter must be a postive integer!"
			echo "Using the default of $bins"
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

if [[ -z $(grep "_rlnGroupScaleCorrection" ${inStar}) ]] ; then

	echo ""
	echo "Error: Input file does not contain a _rlnGroupScaleCorrection column...are you sure this in a run_model.star?"
	echo "Exiting..."
	echo ""
	usage
fi

# Give output a name
outFile="${inStar%.*}_gsc.dat"

# Get field of interest
gscField=$(grep "_rlnGroupScaleCorrection" ${inStar} | awk '{print $2}' | sed 's|#||')

# Sort data lines based on autopick FOM
awk -v gsc=$gscField '{if ($0 ~ /.mrc/) {print $gsc}}' ${inStar} | sort -nr > ${outFile}

# First line of .mrc references the map reference
sed -i -e "1d" ${outFile}
count=$(wc -l ${outFile} | awk '{print $1}')

echo ""
echo "There are values for $count micrographs."
echo ""

echo ""
echo "Now preparing binned data for histogram..."
echo ""

# File for plotting
histfile=${inStar%.*}_gsc.hist

if [[ -f $histfile ]] ; then
	rm $histfile
fi

awk -v xmin=0 -v xmax=2 -v bins=200 -v width=0.01 -v histfile=$histfile '
BEGIN {

# set up arrays
for (i = 1 ; i <= bins; ++i) 
	{

		n[i] = xmin+(i*width) 		# upper bound of bin
		c[i] = n[i] - (width/2) 	# center of bin
		f[i] = 0			# starting count for each bin
	} # close for loop
} # close begin

# file operation
{
 # bin data
 for (i = 1 ; i <= bins; ++i) 
	{
		if ($1 <= n[i]) # if value in field 1 is less than the upper bound of bin
		{
			++f[i]	# increment bin count
			break	# exit when criterion if first achieved to avoid over counting
		} # close if
	} # close for loop
}

END {
 for ( i = 1; i <= bins; ++i)
	{
		if (f[i] > 0)
		{
			print c[i], f[i] > histfile
		}
		else
		{
			print c[i], 0 > histfile
		}
	} # close for loop 
} # close end

' < ${outFile}

wait

awk '{printf "%0.2f %s\n",$1,$2}' ${histfile} > tmp.hist
mv tmp.hist ${histfile}

echo ""
echo "Finished binning data for histogram and written to ${histfile}"
echo "Now preparing plot..."
echo ""

# gnuplot 
gnuplot <<- EOF
set key off
set border 4095

set xtics 0.5 rotate by 60 right nomirror
set grid xtics
set xtics 0,0.05,2

set size ratio 0.5
set terminal pngcairo noenhanced font "arial,10" fontscale 1.0
set output "${outFile%.*}_histogram.png"

set title "Histogram of GroupScaleCorrection: \n ${inStar}"
set ylabel "Counts"
set xlabel "bins"

set style data boxes
set boxwidth 0.45 relative
set style fill solid



plot "$histfile" using 1:2
EOF

eog ${outFile%.*}_histogram.png &

# tidy-up
rm ${outFile}

echo ""
echo "Bins and counts used for the histogram have been written out as:"
echo "${histfile}"
echo ""
echo "Plot will display shortly...Eye of Gnome can take a minute of some manchines."
echo ""
echo "Script done!"
echo ""

exit 1
