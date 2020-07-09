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
echo "This will plot FSC curves for a specified iteraion"
echo "Note: This script uses Eye Of Gnome to display the e2_FSCs_iter.png"
echo "******************************************************************************************"

iterNum=$1 ; iterName=$(printf "%02" $iterNum) #the iteration files are zero-padded to 2-digits...Don't know what happens at iter 100i

if [[ -z $1 ]] ; then 
  echo ""
  echo "Variables empty, usage is $(basename $0) (1)"
  echo ""
  echo "(1) = Iteration for which to plot the FSCs from EMAN2 SPT/Subtilt routine"
  echo ""

  exit

else




  echo "***********************************************************************"
  echo "Checking if the files exist"
 
  #check if a fsc file even exists

	if [[ ! -f fsc_masked_${iterName}.txt ]] ; then
	
		echo""
		echo"Could not find fsc_masked_${iterName}.txt"
		echo"Does not look like this iteration has completed"
		echo"exiting"
		echo""

		exit

	elif [[ ! -f fsc_unmasked_${iterName}.txt ]] ; then
	
		
		echo""
		echo"Could not find fsc_unmasked_${iterName}.txt"
		echo"Does not look like this iteration has completed"
		echo"exiting"
		echo""
		
		exit

	elif [[ ! -f fsc_maskedtight_${iterName}.txt ]] ; then
	
		echo""
		echo"Could not find fsc_maskedtight_${iterName}.txt"
		echo"Does not look like this iteration has completed"
		echo"exiting"
		echo""
		
		exit
	fi
	
  
  echo "Found all the necessary files and will now collate the data"
 
  paste fsc_unmasked_${iterName}.txt fsc_masked_${iterName}.txt fsc_maskedtight_${iterName}.txt | cut -f 1,2,4,6 > FSCs_${iterName}_plottable.dat	
  
 

  echo ""
  echo "Now working on graphical plot..."
  echo "***********************************************************************"
  echo ""

fi
#Gnu plot 

gnuplot <<- EOF
set title "FSC plot: Iteration $iterNum"
set xlabel "Resolution 1/A"
set ylabel "FSC"
set yrange [0:1.2]

set term pngcairo size 900,400 font 'Helvetica,14'
set term ratio 0.6
set border linewidth 2
set tic scale 1
set key top right

labels = "unmasked masked tight"
set style line 1 lt 5 lw 1 pt 7 ps 0.5 lc rgb "black" 	#Lines
set style line 2 lt 5 lw 3 pt 7 ps 0.5 lc rgb "gold"  	#unmasked
set style line 3 lt 5 lw 3 pt 7 ps 0.5 lc rgb "magenta"	#masked
set style line 4 lt 5 lw 3 pt 7 ps 0.5 lc rgb "cyan"	#tight

set arrow 1 ls 1 from graph 0,first 0.143 to graph 1,first 0.143 nohead lt 7 lw 1 lc "black" front

set output "e2_FSCs_for_iter_${iterName}.png"

plot "FSCs_${iterName}_plottable.dat" using 1:2 title ''.word(labels,1).'' with lines ls 2, \
     "FSCs_${iterName}_plottable.dat" using 1:3 title ''.word(labels,2).'' with lines ls 3, \
     "FSCs_${iterName}_plottable.dat" using 1:4 title ''.word(labels,3).'' with lines ls 4, \
EOF

eog e2_FSCs_for_iter_${iterName}.png &
