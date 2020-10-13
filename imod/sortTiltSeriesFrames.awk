#!/usr/bin/awk -f

###############################################################################################################
#
#
# Simple awk script to order aligned tilt-series images based on angle information in the SerialEM filenames.
# The idea is to combine this with newstack to yield an ordered stack for alignment. 
# Only really useful if you lost the .mdoc somehow, since IMOD's alignframes takes care of this with the .mdoc.
#
# run: newstack 'ls *.mrc | awk -f /sortTiltSeriesFrames.awk' /path/and/name/of/output/stack
#
###############################################################################################################

{
 match($0, /_\-?[0-9]+\./);
 angle = int(substr($0, RSTART+1, RLENGTH-2));
 a[angle] = $0;
}

END {
for(i = -70; i <= 70; i++) {
if(i in a) {
printf "%s ", a[i];
}
}
}
