#!/bin/bash
#
#
############################################################################
#
# 
# Author: "Tom Laughlin"
# University of California-San Diego 2020
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


echo "*****************************************************************************************"
echo "FSC plotting script for EMAN2-2.39 SPT/Subtilt routine results"
echo ""
echo "This will plot specified FSC curves in a given EMAN2 SPT/Subtilt routine output directory"
echo "Options are 0-'masked', 1-unmasked, and 2-'maskedtight'"
echo "Note: This script uses Eye Of Gnome to display the e2_'fscType'_by_iter.png"
echo "******************************************************************************************"
#
#Test if input variables are empty (if or statement)
#

if [[ -z $1 ]] ; then 
  echo ""
  echo "Variables empty, usage is $(basename $0) (1)"
  echo ""
  echo "(1) = Type of FSC to plot, 0-masked, 1-unmasked, 2-maskedtight"
  echo "(1) must be a number 0, 1, or 2"
  echo ""

  exit

else

	case $1 in

	"0")
		fscType="fsc_masked"
		;;
	"1")
		fscType="fsc_unmasked"
		;;
	
	"2")
		fscType="fsc_maskedtight"
		;;
       	
	*)
		echo "Input is not 0-2...defaulting to masked option"
		fscType="fsc_masked"
		;;
	esac	


  echo "***********************************************************************"
  echo "Plotting ${fscType}"
 
  #check if a fsc file even exists

	if [[ ! -f ${fscType}_01.txt ]] ; then
	
		echo""
		echo"Could not find ${fscType}_01.txt"
		echo"Does not look like the first iteration has completed"
		echo"exiting"
		echo""

		exit
	fi
	
  #count number of iteraction to plot

  fscIters=$(ls -l ${fscType}_*.txt | wc -l)
 
  echo "Found ${fscIters} of iterations to plot"
 
  echo "0	1" > ${fscType}_plottable.dat
  cat ${fscType}_01.txt >> ${fscType}_plottable.dat	

  #start combining data files
  for (( i=2; i<=$fscIters; i++ ))
  do
	  j=$(printf "%02d" $i)
	  echo "1" > tmp.dat
	  cut -f 2 ${fscType}_${j}.txt >> tmp.dat 
	  paste ${fscType}_plottable.dat tmp.dat > tmp2.dat
	  mv tmp2.dat ${fscType}_plottable.dat 
  done

  #tidy up
  rm tmp.dat || true

  echo ""
  echo "Now working on graphical plot..."
  echo "***********************************************************************"
  echo ""

fi
#Gnu plot 

gnuplot <<- EOF

set terminal pngcairo size 900,400 font 'Helvetica,12'
set size ratio 0.6 
set border linewidth 2
set tic scale 1

set title "${fscType} by iteration"
set xlabel "Resolution 1/A"
set ylabel "FSC"

set yrange [0:1.2]

set key inside

set output "e2_${fscType}_by_iter.png"
plot for [i=2:$((fscIters+1))] "${fscType}_plottable.dat" using 1:i title 'Iter' .(i-1) with linespoints lw 2.5 pt 7 ps 0.5
EOF

eog e2_${fscType}_by_iter.png &
