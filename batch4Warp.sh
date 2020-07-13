#!/bin/bash
#
#
#############################################################################
#
# Author(s): "Thomas (Tom) G. Laughlin III"
# University of California-San Diego 2020
#
#
############################################################################

echo "***************************************************************************************************************"
echo ""
echo ""
echo ""
echo ""
echo "Tom Lauglin, UC-San Diego 2020"
echo "***************************************************************************************************************"

##default hard-codings
accessories_path="/data/Users/share/shell_scripts/automatic_reconstruction_DS_edit/"
adocTemplate="DS_directive_Robust.adoc"

#default for bad tilt exclusion threshold
exclusionThresh=7

#defaults for automated patch-tracking for etomo
target_resid=0.5
min_points=7

usage () 
{
	echo ""
	echo "Usage is $(basename $0) -i <imod directory> [optional arguments]"
	echo ""
	echo "-i: Path to Warp's imod directory (required)"
	echo ""
	echo "-a: Path to accessories files 					(optional)"
	echo "-d: Name of .adoc template files 					(optional)"
	echo "-t: Excluded-view mean-intensity threshold 			(optional, default=7)"
	echo "-r: Target residual for alignment					(optional, default=0.5)"
	echo "-m: Minimum number of tracked points 				(optional, default=7"
	exit 1
}

while getopts ":i:a::d::t::r::m::" options; do
    case "${options}" in
        i)
            imodDirectory=${OPTARG}
            ;;
        a)
            accessories_path=${OPTARG}
            ;;
        d)
            adocTemplate=${OPTARG}
            ;;
        t)
            exclusionThresh=${OPTARG}
            ;;
        r)
            target_resid=${OPTARG}
            ;;
        m)
	    min_points=${OPTARG}
	    ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))


## Check inputs
if [[ -z $1 ]] || [[ -z $2 ]] || [[ -z $3 ]]; then

	echo ""
	echo "Arguements empty, usage is $(basename $0) (1)"
	echo ""
	echo "Path to Warp's imod directory"
	echo ""
	exit

elif [[ ! -d "${imodDirectory}" ]]; then

	echo ""
	echo "${imodDirectory} does not exist!"
	echo "Check that the given path is correct"
	exit 


else

#set user-defined accessories path if available
if [[ -v ]]
	accessories_path=
fi

#set user-defined adoc file if available
if [[ -v ]]
	adocFile=
fi

echo "Using accesories and com scripts located in ${accesories_path}"
echo "Using ${adocTemplate} as directive adoc template file"

#prepare adoc and com files for imod batch processing
for i in `ls $imodDirectory`; do
	
	cd $i
	
	#get tilt-series name and meta-data using IMOD function
	ts_name=${i}
	pixelSize=$(header -pixel ${ts_name}.st | awk '{print $1}')
	#dimX=$(header -size ${ts_name}.st | awk '{print $1}')
	#dimY=$(header -size ${ts_name}.st | awk '{print $2}')

 	#Get image stats for determing bad views using IMOD function
 	clip stats ${ts_name}.st >> stats.log 
 	sed -i -e '1,2d' \
 		-e '$d' \
 		-e 's|)|    |g' \
 		-e 's|(|    |g' \
		-e 's|,|    |g' "stats.log"
	
	#remove bad views based on mean intensity threshold (field 7)
	 awk -v thresh=$exclusionThresh '{if($7 <= thresh) {print $1+1}}' stats.log > ExcludedViews.tmp

	#check if any bad views were found
	 viewCount=$(wc -l ExcludedViews.tmp | awk '{print $1}')

	 if [[ viewCount -gt 0 ]]
		
		counter=0
		#if bad views found, reorder vertical file into horizontal csv
		for i in `cat ExcludedViews.txt`; do

			if (counter == 0)
				viewString=$(echo $i)
			else
				viewString=$(echo $viewString,$i)
			fi
		((counter++))

		done
		
		#record excluded views and tidy-up
		echo ${ts_name} $viewString > ${ts_name}_excludedViews.log
		rm ExcludedViews.tmp
        rm stats.log

        #generate stack with excluded views using IMOD function
		excludeviews -stack ${ts_name}.st -delete -views ${viewString}
		
 	 fi


	#hide pre-existing session if it exists
	if [[  -f "${i}.edf" ]]
		mv "${i}.edf" "${i}.edf.bak"

	# determine binning for coarse alignment (typically ~10 A/px is good)
	# 	bash doesn't handle floating-point and rounding well..."bc" enables floating-point arithmetic, 
	# 	"scale" tells bc to return that many digits past the decimal place
	#	then round
	binBy=$(echo "scale = 1; 10 / $pixelSize" | bc | awk '{print int($1+0.5)}')

	#make adoc file for this tilt-series by putting name for file at the top and tacking on the rest from accessory file
	echo "setupset.copyarg.name=${ts_name}" "${i}_directive.adoc"
	cat "${accesories_path}/${adocTemplate}" >> "${i}_directive.adoc"
	
	if [[ binBy != 2 ]]
		#patch sizes for Patch-tracking routine (based on ~4k x 4k)
		patchX=$(( 680 / binBy ))
		patchY=$(( 680 / binBy ))

		sed -i -e 's|BinByFactor=2|BinByFactor=${binBy}|g' \
		    -e 's|ImagesAreBinned=2|ImagesAreBinned=${binBy}|g' \
    		-e 's|SizeOfPatchesXandY=340,340|SizeOfPatchesXandY=${patchX},${patchY}' "${i}_directive.adoc"
    fi


	etomo --directive "${i}_directive.adoc"

	#Run batch based reconstructions

 	cd ..

 done

#Run batch based reconstructions
