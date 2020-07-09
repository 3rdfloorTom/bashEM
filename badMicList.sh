#!/bin/bash
#
###########################################################################################
# Script to curate and remove bad images from aligned averages of EM movies
#
# Using IMOD functions, all micrographs will be loaded into memory to view via 3dmod 
#
# The script will state what to do when necessary in the 3dmod interface to mark bad images
#
# A list of bad images will be produced which can then be used to remove all files or 
# directories associated with these images using a 'for loop' over the names. 
#
#
#
# To run script, simply execute in the directory containing the aligned .mrc files
#
#
###########################################################################################


ls -rt *.mrc > filenames.txt
filenames=(`cat filenames.txt`)

#To open all mrc files in specific order

3dmod -E t1 ${filenames[*]} badfiles.mod

#instructions to select bad images

echo "Wait for images to load. It can take several minutes"
sleep 10s
echo " "
echo "In object edit dialogue window select:"
sleep 5s
echo "Scattered"
sleep 5s
echo "Symbols: Triangle, Filled, size 100"
sleep 5s
echo " "
echo "Click on Zap window (picture of specimen)"
sleep 5s
echo "on keyboard press End (will bring you to first image)"
sleep 5s
echo "use page up on keyboard to move through images"
echo "place marker with middle mouse button on each bad image"
sleep 20s
echo " "
echo "at end, press 's' to save model file"
echo " "
echo " "
#echo "when finish, hit spacebar"
echo " "
echo " "
echo " "

read -n1 -rsp $'When finished and model is saved, hit spacebar to continue...\n'

model2point badfiles.mod badfiles.pt

#awk extracts z coord for extracting badimage name from filename.txt
#first image displayed in 3dmod actually has a z coordinate of 0. Therefore you need to add one to the Z coord to retrive the correct image from the filename list

awk '{print $3+1}' badfiles.pt > badimages.txt


# making a file with the list of files that need deleteing.
#-v in awk allows an input variable

rm badimages2delete.txt

for i in  `cat badimages.txt`  ; do awk -v image=$i '(NR == image) {print $1}' filenames.txt >> badimages2delete.txt; done

#to remove bad raw movie image frames

for i in `cat badimages2delete.txt`; do echo $(basename $i .mrc).tif ; done > frameofbadimages.txt

for i in `cat badimages2delete.txt`; do echo $(basename $i .mrc).star ; done > starforbadimages.txt
exit

#if all has gone well, delete bad image/movie directories









