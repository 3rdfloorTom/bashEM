#!/bin/bash
#
#
##########################################################################################################
#
# Author(s): Tom Laughlin University of California-San Diego 2020
#
# 
#
###########################################################################################################

#usage description
usage () 
{
	echo ""
	echo "This script is a crude attempt at batch parallization in bash."
	echo "It takes a file of successive shell commands, splits it, and runs on N cores."
	echo "Usage is:"
	echo ""
	echo "$(basename $0) -i scriptFile.sh -s '[script arguements]' -n cores"
	echo ""
	echo "options list:"
	echo "	-i: input file/script with options				(required)"
	echo "	-s: arguements for the scripts given in -i, enclose in quotes 	(optional)"
	echo "	-n: number of cores to use					(optional, default 12)"
	echo ""
	exit 0
}

# check for any arguements at all
if [[ $# == 0 ]] ; then
	usage
fi

#grab command-line arguements
while getopts ":i:s:n:" options; do
    case "${options}" in
        i)  if [[ -f ${OPTARG} ]] ; then
      		inScript=${OPTARG}
	    else
		echo ""
		echo "Could not find the input file ${OPTARG}"
		echo ""
		usage
	    fi
            ;;
	s)	# Don't know how to check this...
	    scriptArgs=${OPTARG}
	    ;;
        n)
            if [[ ${OPTARG} =~ ^[0-9]+$ ]] ; then
           		Ncores=${OPTARG}
			if [[ ${Ncores} -gt $(nproc) ]] ; then
				echo ""
				echo "Number of requested cores exceeds maximum of $(nproc)"
				echo "Setting to maximum"
				echo ""
				Ncores=$(nproc)

          		fi
	  
            else
           		echo ""
           		echo "Error: Number of cores must be a positive integer."
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

# Check that something was given for input
if [[ -z ${inScript} ]] ; then

	echo ""
	echo "No input scripts/file set!"
	echo "Exiting..."
	echo ""
	usage
		
fi

if [[ -z ${scriptArgs} ]] ; then

	echo ""
	echo "No script arguements set."
	echo ""
	scriptArgs=""
fi

# Check if number of cores has been set either by user or the catch in getopts
if [[ -z ${Ncores} ]] ; then

	echo ""
	echo "Number of cores not set, using default of 12"
	echo ""
	Ncores=12
fi

# Make a fresh output directory
tmpDir=$(basename $0 .sh)

if [[ -d ${tmpDir} ]] ; then
	rm -rf ${tmpDir}
fi

mkdir ${tmpDir}

# Split the input script
scriptRoot=${inScript%.*}
echo ""
echo "Splitting ${inScript} and writing output files to ${tmpDir}/"
echo ""
split -d -l 1 ${inScript} "${tmpDir}/${scriptRoot}_"

# Need to set the permissions
chmod 775 ${tmpDir}"/"*

# Total lines to run over
lines=$(wc -l ${inScript} | awk '{print $1}')

echo "Total number of files from splitting ${inScript} is ${lines}"
echo ""

# Loop counter
count=1
# Run all of the splits

sleep 5s
echo "The script ${inScript} has been split and will run in batches of ${Ncores}...get ready for some terminal vomit!"
echo""
sleep 5s



for script in $(ls ${tmpDir}"/"*) ;
do	
	# Waits for all child processes of the for loop when i is divisible by 0, increment i afer 0 test
	# Not the best way to do it if scripts have variable runtime since it waits for the last to finish before starting the next batch
	((i=i%${Ncores})); ((i++==0)) && wait

	./${script} ${scriptArgs} > /dev/null &
  
	echo "Executed $(basename $script) ${scriptArgs} 	${count} of ${lines}"

	((count++))
done

wait

echo ""
echo "Finished a crude batch parallel run of ${inScript}"
echo "You just ran ${count} jobs in batch parallel."
echo ""
echo "Script done!"
echo ""

exit 1

