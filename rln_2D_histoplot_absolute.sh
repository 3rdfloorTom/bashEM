#!/bin/bash
#
#
#############################################################################
#
# Author: "Thomas (Tom) G. Laughlin III"
# University of California-Berkeley 2018
#
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

echo "**************************************************************************"
echo "Class occupancy script for Relion, Tom Laughlin UC-Berkeley 2018"
echo ""
echo "This will plot the # of particles per class  of Class2D from Relion 2.1"
echo "Note: This script uses Eye of Gnome"
echo "**************************************************************************"

## inputs
data2D=${1%_data.star}

## Check inputs
if [[ -z $1 ]] ; then

	echo ""
	echo "Variable empty, usage is ${0} (1)"
	echo "(1) = run_it###_data.star"
	echo ""
	
	exit

else
	echo "*****************************************************************"
	echo "Extracting class data for "$data2D", this may take a minute..."
	echo "*****************************************************************"

## Extract ClassNumber, sort, count
awk '{print $4}' < ${data2D}_data.star | sort -n | uniq -c | awk '{print $1,$2}' > del.plt
cp del.plt del2.plt
awk '($2!=p+1){print "0",p+1} {p=$2}' del.plt >> del2.plt
cat del2.plt | sort -n -k2 > tmp.plt

xmax=$(tail -n 1 tmp.plt | awk '{print $2}')
tail -n $(($xmax-1)) < tmp.plt > ${data2D}_classes_dist.plt

#tidy up
rm -f del.plt del2.plt tmp.plt

fi
## gnuplot
gnuplot <<- EOF
set font ",12"
set autoscale y 		       # scale axes automatically
set autoscale x			       # set x range
set nokey		    	       # We don't need a key :)
set border 3			       # Draw only left-hand and bottom borders
set term png size 1000,450
set xtic 0,1,$xmax nomirror	       # set xtics and show only on bottom
set xtic font ",9"
set ytic nomirror
set title "Number of particles in each class"
set xlabel "Class #"
set ylabel "# of particles"
set style data boxes			#for histogram
set boxwidth 0.9 absolute
set style fill solid border
set output "${data2D}_class_dist.png"
plot '${data2D}_classes_dist.plt' using 2:1 with boxes fillcolor rgb 0x0000ff
EOF


echo ""
echo "*********************************************************************************"
echo "Here are some nice numbers to know about your data"
echo "*********************************************************************************"
echo ""

## print class statistics to terminal
awk '{s+=$1} END{print "Number of classes: "(NR+1), "\nAverage # of particles: "s/(NR+1)}' ${data2D}_classes_dist.plt
awk 'NR == 1 {max=$1 ; min=$1} $1 >= max {max = $1} $1 <= min {min = $1} END { print "Min: "min,"Max: "max }' ${data2D}_classes_dist.plt

echo "*********************************************************************************"


eog ${data2D}_class_dist.png &

