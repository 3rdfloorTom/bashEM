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
	echo "This scripts plots a histogram the Autopick Figure-of-Merit (FOM) of a coordinate star file"
	echo ""
	echo "It uses gnuplot for plotting and Eye of Gnome for display of the histogram at the end."
	echo ""
	echo "Usage is:"
	echo ""
	echo "$(basename $0) -i input.star -f fineness"
	echo ""
	echo "options list:"
	echo "	-i: .star generated from a RELION/Warp template matching run			(required)"
	echo "	-f: fineness of how to set the bins, bigger number = more bins			(optional, default=4)"
	echo ""
	exit 0
}

# set default values
fineness=4

# check for any arguements at all
if [[ $# == 0 ]] ; then
	usage
fi

#grab command-line arguements
while getopts ":i:f:" options; do
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
	f)
	    if	[[ ${OPTARG} =~ ^[0-9]+$ ]] ; then
			fineness=${OPTARG}
	    else
			echo ""
			echo "Error: the fineness parameter must be a postive integer!"
			echo "Using the default of $fineness"
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

if [[ -z $(grep "_rlnAutopickFigureOfMerit" ${inStar}) ]] ; then

	echo ""
	echo "Error: Input file does not contain a _rlnAutopickFigureOfMerit column...not much to do here."
	echo "Exiting..."
	echo ""
	usage
fi

# Give output a name
outFile="${inStar%.*}_FOM.dat"

# Get FOM field
fomField=$(grep "_rlnAutopickFigureOfMerit" ${inStar} | awk '{print $2}' | sed 's|#||')

# Sort data lines based on autopick FOM
awk -v fom=$fomField '{if ($0 ~ /.mrc/) {print $fom}}' ${inStar} | sort -nr > ${outFile}

count=$(wc -l ${outFile} | awk '{print $1}')
echo ""
echo "There are coordinates for $count particles."
echo ""

echo ""
echo "Now preparing binned data for histogram..."
echo ""

# Get histogram parameters
xmin=$(tail -n 1 ${outFile})
xmax=$(head -n 1 ${outFile})
bins=$(echo "scale = 2; ($xmax - $xmin)*$fineness " | bc)
width=$(echo "scale = 2; ($xmax -$xmin)/$bins" | bc)

# File for plotting
histfile=${inStar%.*}.hist

if [[ -f $histfile ]] ; then
	rm $histfile
fi

awk -v xmin=$xmin -v xmax=$xmax -v bins=$bins -v width=$width -v histfile=$histfile '
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

set size ratio 0.5
set terminal pngcairo enhanced font "arial,10" fontscale 1.0
set output "${outFile%.*}_histogram.png"

set title "Histogram of Autopick FOM scores"
set ylabel "Counts"
set xlabel "Score bins"

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
