## inputs
image_file=$1

## hard-codings
rotY=7.0
rotX=-3.3
z_low=120
z_high=220
y_low=50
y_high=750

## Check inputs
if [[ -z $1 ]] ; then

	echo ""
	echo "Variable empty, usage is $(basename $0)"
	echo "(1) = image_file"
	echo ""
	
	exit

else

	## Get rootname of file

	image_name=${image_file%.mrc}
	
	## First rotation
	out_file=${image_name}_rotY.mrc
	rotatevol -angles 0,$rotY,0 $image_file $out_file
	
	## Second rotation
	image_file=${out_file}
	out_file=${out_file%.mrc}_rotX.mrc		
	rotatevol -angles 0,0,$rotX $image_file $out_file

	## Trim in Z
	image_file=${out_file}
	out_file=${out_file%.mrc}_z${z_low}To${z_high}.mrc
	trimvol -z $z_low,$z_high $image_file $out_file	

	## Trim in Y
	image_file=${out_file}
	out_file=${out_file%.mrc}_y${y_low}To${y_high}.mrc
	trimvol -y $y_low,$y_high $image_file $out_file
	
	
	echo ""
	echo "*********************************************************************************************"
	echo "Done!!!"
	echo "*********************************************************************************************"
	echo ""

fi

