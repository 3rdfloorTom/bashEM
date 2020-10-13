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
echo "This will plot the fractional class occupancy of Class2D from Relion 2.1"
echo "Note: This script uses Eye of Gnome"
echo "**************************************************************************"

## inputs
data2D=${1%_model.star}

## Check inputs
if [[ -z $1 ]] ; then

	echo ""
	echo "Variable empty, usage is $(basename $0) (1)"
	echo "(1) = run_it###_model.star"
	echo ""
	
	exit

else
	echo "*****************************************************************"
	echo "Extracting class data for "$data2D", this may take a minute..."
	echo "*****************************************************************"

## Extract ClassNumber, sort, count
awk '{if ($1 ~/.mrcs/) {print $2}}' < ${data2D}_model.star > tmp.plt

## Set near zero classes to zero
awk '{if ($1 ~/e-/) {print "0"} else {print $1}}' < tmp.plt | sort -nr | awk '{print $1,NR}' > ${data2D}_class_fraction.plt

xmax=$(wc -l tmp.plt | awk '{print $1}')

##tidy up
rm -rf tmp.plt

fi
## gnuplot
gnuplot <<- EOF
set autoscale y 		       # scale axes automatically
set autoscale x			       # set x range
set nokey		    	       # We don't need a key :)
set border 3			       # Draw only left-hand and bottom borders
set term png size 1000,450
set xtic 0,1,$xmax nomirror	       # set xtics and show only on bottom
set xtic font ",10"
set ytic nomirror
set ytic font ",10"
set title "Fraction of particles in each class"
set xlabel "Class #"
set ylabel "Fraction pctls"
set style data boxes			#for histogram
set boxwidth 0.85 absolute
set style fill solid border
set output "${data2D}_class_fraction.png"
plot '${data2D}_class_fraction.plt' using 2:1 with boxes fillcolor rgb 0x0000ff
EOF

echo ""
echo "*********************************************************************************"
echo "The histogram will be displayed shortly..."
echo "*********************************************************************************"


eog ${data2D}_class_fraction.png &
