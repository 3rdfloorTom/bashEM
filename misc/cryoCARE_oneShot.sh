#!/bin/bash
#
#
##########################################################################################################
#
# Author(s): Tom Laughlin Altos labs 2023
#
# 
#
###########################################################################################################

# Defaults
## Extract
patch_shape=72
no_subtomos_extract=1200
fraction_subtomos_train=0.9
no_subtomos_meanSD=500
extract_output_dir="cryoCARE_training"

## Train
gpu_count=1
epochs=100
steps_per_epoch=200
batch_size=16
unet_size=3
unet_depth=3
unet_first=16
learning_rate=0.0004
train_output_dir="cryoCARE_models"

## Predict
n_tiles=1
overwrite="False"
predict_output_dir="cryoCARE_predict"


## functions
# usage description
usage () 
{
	echo ""
	echo "This script prepares the JSON files and executes all steps of cryoCARE sequentially."
	echo ""
	echo "Note:"
	echo "This script runs trains and applies models invidiually for each tomogram."
	echo "It will perform all steps for a tomogram before moving to the next one."
	echo ""
	echo ""
	echo "Usage is:"
	echo ""
	echo "$(basename $0) -i <path/to/even/odd/parent/directory>"
	echo ""
	echo "options list:"
	echo "	-i: /path/to/even/odd/parent/direcotry				(required)"
	echo "	-g: gpu_count							(optional, default=1)"
	exit 0
	
} # usage close

# cryoCARE check
cryocare_check()
{
	if [[ $(command -v cryoCARE_extract_train_data.py &> /dev/null) ]] || [[ $(command -v cryoCARE_train.py &> /dev/null) ]] || [[ $(command -v cryoCARE_predict.py &> /dev/null) ]] ; then
	echo ""
	echo "Error: Could not find cryoCARE python executables"
	echo "Load cryoCARE and re-run the script."
	echo "Exiting..."
	echo ""

	exit 0
	fi

} # close cryoCARE check
# extract function
extract()
{
	local tomo_base_name=$1
	local extract_json_file=$2
	local extracted_data=$3
	
	# Make JSON file
	if (true) ; then
	printf '{\n'
	printf '"even": ["%s"],\n' $(realpath ${even_odd_path}"/even/"${tomo_basename}".mrc")
	printf '"odd": ["%s"],\n'  $(realpath ${even_odd_path}"/odd/"${tomo_basename}".mrc")
	printf '"patch_shape": [%d,%d,%d],\n' ${patch_shape} ${patch_shape} ${patch_shape}
	printf '"num_slices": %d,\n' ${no_subtomos_extract}
	printf '"split": %f,\n' ${fraction_subtomos_train}
	printf '"tilt_axis": "Y",\n'
	printf '"n_normalization_samples": %d,\n' ${no_subtomos_meanSD}
	printf '"path": "%s" \n' ${extracted_data}
	printf '}\n'
	fi > ${extract_json_file}
	
	echo "Wrote config JSON for ${tomo_basename}" >&2
	echo "" >&2

	echo "Extracting data..." >&2

	cryoCARE_extract_train_data.py --conf ${extract_json_file} >&2 

	echo "Finished extacting for ${tomo_basename}" >&2 
	
} # extract close

# train function
train()
{
	local tomo_basename=$1
	local gpu_id=$2
	local train_json_file=$3
	local trained_model_name=$4
	
	# Prepare JSON files
	echo "Training on ${tomo_basename}" >&2

	# Make JSON file
	if (true) ; then
	printf '{\n'
	printf '"train_data": "%s",\n' $(realpath ${extracted_data})
	printf '"epochs": %d,\n'  ${epochs}
	printf '"steps_per_epoch": %d,\n' ${steps_per_epoch}
	printf '"batch_size": %d,\n' ${batch_size}
	printf '"learning_rate": %f,\n' ${learning_rate}
	printf '"unet_kern_size": %d,\n' ${unet_size}
	printf '"unet_n_depth": %d,\n' ${unet_depth}
	printf '"unet_n_first": %d,\n' ${unet_first}
	printf '"gpu_id": %d,\n' ${gpu_id}
	printf '"model_name": "%s", \n' ${trained_model_name}
	printf '"path": "%s" \n' ${train_output_dir}
	printf '}\n'
	fi > ${train_json_file}
	
	echo "Wrote training config JSON for ${tomo_basename}" >&2
	echo "" >&2
	echo "Training model for ${tomo_basename}" >&2

	cryoCARE_train.py --conf ${train_json_file} >&2 

	echo "Finished training for ${tomo_basename}" >&2


} # close train

predict()
{
	local tomo_basename=$1
	local gpu_id=$2
	local trained_model_file=$3
	local predicted_json_file=$4	
	
	# Make JSON file
	if (true) ; then
	printf '{\n'
	printf '"even": "%s",\n' $(realpath ${even_odd_path}"/even/"${tomo_basename}".mrc")
	printf '"odd": "%s",\n'  $(realpath ${even_odd_path}"/odd/"${tomo_basename}".mrc")
	printf '"path": "%s",\n' ${trained_model_file}
	printf '"n_tiles": [%d,%d,%d],\n' ${n_tiles} ${n_tiles} ${n_tiles}
	printf '"overwrite": "%s",\n' ${overwrite}
	printf '"output": "%s",\n' ${predict_output_dir}
	printf '"gpu_id": %d\n' ${gpu_id}
	printf '}\n'
	fi > ${predict_json_file}
	
	echo "Wrote predict config JSON for ${tomo_basename}" >&2
	echo "" >&2
	echo "Predicting..." >&2

	cryoCARE_predict.py --conf ${predict_json_file} >&2
	
	echo "Finished prediction for ${tomo_basename}" >&2
	echo "" >&2
	

} #close predict

cryocare_run()
{
	local tomo_basename=$1
	local gpu_id=$2
	
	# check whether extraction has been already performed
	local extract_json_file=${extract_output_dir}"/"${tomo_basename}"_train_data_config.json"
	local extracted_data=${extract_output_dir}"/"${tomo_basename}
	
	if [[ -d  ${extracted_data} ]] ; then
		echo "" >&2
		echo "Extracted data already present for ${tomo_basename}" >&2
		echo "Skipping..." >&2
		echo "" >&2
	else
		extract ${tomo_basename} ${extract_json_file} ${extracted_data}
	fi

	# check whether training has already been performed
	local train_json_file=${train_output_dir}"/"${tomo_basename}"_train_config.json"
	local trained_model_name=${tomo_basename}"_cryoCARE_model"
	
	if [[ -d ${train_output_dir}"/"${trained_model_name} ]] ; then	
		echo "" >&2
		echo "A trained model is  already present for ${tomo_basename}" >&2
		echo "Skipping..." >&2
		echo "" >&2
	else
		train ${tomo_basename} ${gpu_id} ${train_json_file} ${trained_model_name}
	fi
	
	
	local trained_model_file=${train_output_dir}"/"${trained_model_name}".tar.gz"
	local predict_json_file=${predict_output_dir}"/"${tomo_basename}"_predict_config.json"
	
	# execute prediction
	predict ${tomo_basename} ${gpu_id} ${trained_model_file} ${predict_json_file} 
	
	echo "Finished for ${tomo_basename}" >&2
	echo "" >&2
	
} # cryocare_run close





########## Main script ################
# check for any arguements at all
if [[ $# == 0 ]] ; then
	usage
fi

#grab command-line arguements
while getopts ":i:g:" options; do
    case "${options}" in
	
	i)  if [[ -d ${OPTARG} ]] ; then
			even_odd_path=${OPTARG}
	    else
			echo ""
			echo "Cannot find the specified even/odd parent directory."
			echo ""
			exit 0
	    fi
	    ;;


	g)  if [[ ${OPTARG} =~ ^[0-9]+$ ]] && [[ ${OPTARG} -le $(nvidia-smi -L | wc -l) ]] ; then	 
			gpu_count=${OPTARG}
	    else
			echo ""
			echo "GPU count must be a positive integer less than the total number of GPUs!"
			echo "Using default value of $gpu_count"
			echo
	    fi
	    ;;
        *)
            usage
            ;;
    esac
done
shift "$((OPTIND-1))"

echo ""
echo "Running $(basename $0)..."
echo ""

# check if cryoCARE is loaded on PATH
cryocare_check

## Check for required arguements
if [[ ! -d ${even_odd_path} ]] ; then
	echo ""
	echo "Error: Cannot find the specified even/odd parent directory."
	echo "Exiting..."
	exit 0
fi

if [[ ! -d ${even_odd_path}"/even" ]] || [[ ! -d ${even_odd_path}"/odd" ]] ; then
	echo ""
	echo "Error: Specified directory does not contain even/odd sub-directories"
	echo ""
	exit 0
fi 

# Make output directories if not already present
if [[ ! -d ${extract_output_dir} ]] ; then
	mkdir ${extract_output_dir}
fi

if [[ ! -d ${train_output_dir} ]] ; then
	mkdir ${train_output_dir}
fi

if [[ ! -d ${predict_output_dir} ]] ; then
	mkdir ${predict_output_dir}
fi

# array of tomograms which will be acted on
declare -a tomo_array
# tomogram list
for tomo in ${even_odd_path}"/even/"*.mrc
do
	tomo_basename=$(basename $tomo .mrc)
	
	echo "Working on ${tomo_basename}"
	
	
	# check whether an odd counterpart exist
	if [[ ! -f ${even_odd_path}"/odd/"${tomo_basename}".mrc" ]] ; then
	
		echo ""
		echo "Could not find the odd counterpart for ${tomo_basename}"
		echo "Skipping..."

		continue
	fi

	if [[ -f ${predict_output_dir}"/"${tomo_basename}".mrc" ]] ; then
		echo ""
		echo "Predicted output already exists for ${tomo_basename}"
		echo "Skipping..."
		echo ""

		continue
	fi

	# add tomogram to array
	tomo_array+=(${tomo_basename});
		
done

# crude parallel
for tomo in "${tomo_array[@]}"
do
	tomo_basename=$tomo

   	((gpu=gpu%${gpu_count})) ; ((gpu++==0)) && wait
	
	gpu_id=$((gpu-1))
	echo ""
	echo "Running ${tomo_basename} on GPU ${gpu_id}"
	echo ""
	cryocare_run ${tomo_basename} ${gpu_id} > /dev/null &
	
	
done 

wait

echo ""
echo "Finished cryoCARE for all tomograms in specified directory"
echo ""
echo "Script done!"
echo ""


exit 1


