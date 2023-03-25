#!/bin/bash
#
#
############################################################################
#
# Author: "Thomas (Tom) G. Laughlin III"
# University of California-Berkeley 2018
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


echo "****************************************************************************************"
echo "Class change script for Relion, Tom Laughlin University of California-Berkeley 2018"
echo ""
echo "This will plot the fraction of particles with a class change for Class2/3D in Relion"
echo "Note: This script uses Eye Of Gnome to display the output"
echo "***************************************************************************(************"


## Inputs
xlow=$1
xhigh=$2

## Test if input variables are empty (if or statement)

if [[ -z $1 ]] || [[ -z $2 ]] ; then

  echo ""
  echo "Variables empty, usage is $(basename $0) (1) (2)"
  echo ""
  echo "(1) = Low iteration (x) value to plot"
  echo "(2) = High iteration (x) value to plot"
  echo ""

  exit

else

  echo "**********************************************************************************"
  echo "Printing fraction of pctls with class change for iterations" $xlow "to" $xhigh
  echo "**********************************************************************************"
  
  #Make file with names of model.star in order of iteration (really time of creation) within specified range
  
  ls -rtl *optimiser.star | awk '{print $NF}'| head -n "$((xhigh+2))" | tail -n +"$((xlow+1))" > optiFiles.txt


  #Remove exisiting optimal.dat if present
  if [ -f optimal.dat ]; then
	rm  -f optimal.dat
  fi  

  #Print the raw class occupancy data to terminal and store info in optimal.dat
  for i in $(cat optiFiles.txt)
  do
	grep _rlnChangesOptimalClasses $i | awk '{print $2}'
	grep _rlnChangesOptimalClasses $i | awk '{print $2}' >> optimal.dat
  done

  
  echo ""
  echo "*********************************************************************************"
  echo "Printed class change for iterations " $xlow "to" $xhigh
  echo ""
  echo "Now working on graphical plot..."
  echo "*********************************************************************************"
  echo ""
  
  #tidy up step
  rm -f optiFiles.txt

fi
  
## gnuplot 

gnuplot <<- EOF
set title "Fraction particles changing assigned optimal class"
set xlabel "Classification Iteration"
set ylabel "Fraction of ptcls"
set nokey
set border 3
set yrange [0:1]
set xtic 0,1,$xhigh nomirror
set xtic font ",10"
set ytic nomirror
set ytic font ",10"
set term png size 900,400
set size ratio 0.4
set output "classChangeOptimal_${xlow}to${xhigh}.png"
plot 'optimal.dat' with linespoints lc rgb '#006ad' lt 1 lw 2 pt 7 ps 1
EOF

eog classChangeOptimal_${xlow}to${xhigh}.png &
