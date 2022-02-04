#!/bin/bash
#
#
############################################################################
#
# Author: "Kyle L. Morris"
# University of Warwick 2016
#   
# Edited: "Tom Laughlin"
# University of California-Berkeley 2017
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

# Usage description
usage ()
{
	echo ""
	echo "This will plot the class occupancy of Class3D files from RELION 2+" 
	echo ""
	echo "Note: This script uses gnuplot and Eye Of Gnome."
	echo ""
	echo "Run from within Class3D directory with usage:"
	echo ""
	echo "$(basename $0) -c <first class#> -d <last class#> -l <lowest iteration> -h <highest iteration>"
	echo ""
	echo "	-c: Index of first class to consider.		(required)"
	echo "	-d: Index of last class to consider.		(required)"
	echo "	-l: Earliest iteration to consider.		(optional, default=0)"
	echo "	-h: Latest iteration to consider.		(optional, default=last)"
	echo ""

	exit
}

# Check for any arguements at all.
if [[ $# == 0 ]] ; then
	usage
fi

# Parse arguements
while getopts "c:d:l:h:" options; do
	case "${options}" in

		c)
			if [[ ${OPTARG} =~ ^[0-9]+$ ]] ; then
				classfirst=${OPTARG}
			else
				echo ""
				echo "Error: Class numbers must be a postive integer!"
				echo "Exiting..."
				echo ""
				usage
			fi
			;;

		d)
			if [[ ${OPTARG} =~ ^[0-9]+$ ]] ; then
				classlast=${OPTARG}
			else
				echo ""
				echo "Error: Class numbers must be a postive integer!"
				echo "Exiting..."
				echo ""
				usage
			fi
			;;

		l)
			if [[ ${OPTARG} =~ ^[0-9]+$ ]] ; then
				xlow=${OPTARG}
			else
				echo ""
				echo "Error: Iterations must be a postive integer!"
				echo "Exiting..."
				echo ""
				usage
			fi
			;;

		h)
			if [[ ${OPTARG} =~ ^[0-9]+$ ]] ; then
				xhigh=${OPTARG}
			else
				echo ""
				echo "Error: Iterations must be a postive integer!"
				echo "Exiting..."
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

# Check if input variables are empty (if or statement)
if [[ -z $classfirst ]] || [[ -z $classlast ]] ; then
	echo ""
	echo "Error: Both the first and last class #'s to be used must be set!"
	echo "Exiting..."
	echo ""
	usage
fi

# Check class input ordering is correct
if [ $classfirst -gt $classlast ] ; then
	echo ""
	echo "Input order of class numbers seems to be wrong."
	echo "Swapping..."
	echo ""
	
	tmpClass=$classfirst
	classfirst=$classlast
	classlast=$tmpClass
fi

# Check if iteration bounds are set correctly
if ! [[ -z $xlow ]] && [[ -z $xhigh ]] ; then
	
	# Order bounds properly
	if [ $xlow -gt $xhigh ] ; then
		tmpBound=$xlow
		xlow=$xhigh
		xhigh=$tmpBound
	fi
fi

# Format class strings with leading 0's
CF=$(printf "%03d" $classfirst) 
CL=$(printf "%03d" $classlast)

  echo ""
  echo "Grabbing class occupancies per iteration for class$CF to class$CL"
  echo ""
  
  #Make file with names of model.star in order of iteration (really time of creation)
  
  ls -rtl *model.star | awk '{print $9}' > modelFiles.txt

  # Grab data from *model.star and write *.dat files for this

  for (( i=$classfirst; i<=$classlast; i++ ))
  do
	j=$(printf "%03d" $i)
	grep class$j `cat modelFiles.txt` | awk '{print $2}' > class$j.dat
  done
  
  #tidy up step
  rm -rf modelFiles.txt

  #Populate class_occupancy.dat file with individual class data
  # class001.dat into tmp file
  k=$(printf "%03d" "1")
  paste class$k.dat > tmp.dat
  echo "Finished for class$k"

  # if more than one class for plotting loop through other class files, otherwise do nothin
  if [ $classlast -gt 1 ]
  then
	for (( i=$classfirst; i<$classlast; i++ ))
	do
		  j=$((i+1))
		  j=$(printf "%03d" $j)
		  paste tmp.dat class$j.dat > tmp2.dat
		  paste tmp2.dat > tmp.dat
		  echo "Finished for class$j"	
	done

	rm -rf tmp2.dat
  fi

  # Make final file containing all data
  mv tmp.dat class_occupancy.dat

  # Remove individual class###.dat files

  for (( i=$classfirst; i<=$classlast; i++ ))
  do
	j=$(printf "%03d" $i)
	rm -rf class$j.dat
  done


#gnuplotting

smoothlines=$(wc -l class_occupancy.dat | awk '{print $1}')

if (($smoothlines > 3))
then
	echo ''
	echo 'More than 4 data points per line, using smooth lines for plot'
	echo ''
	lines='with lines lw 2 smooth bezier'
else
	echo ''
	echo 'Fewer than 4 data points, using normal lines for plot'
	lines='with lines lw 2'
	echo ''
fi

gnuplot <<- EOF
set xlabel "Class3D iteration"
set ylabel "Fraction of all particles"
set xrange [$xlow:$xhigh]
set key outside
set term png size 900,400
set size ratio 0.6
set output "class_occupancy.png"
plot for [i=$classfirst:$classlast] "class_occupancy.dat" using i title 'class' .i $lines
EOF

eog class_occupancy.png &

echo "Script is done!"
echo "EOG can take a minute to display class_occupancy.png."
echo "Raw values for each iteration are in class_occupancy.dat."
echo ""
