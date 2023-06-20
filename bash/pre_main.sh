#!/bin/bash

total_log="/minicubio/yifei/germline/Germline-short-variant-calling/WGS/log/pre_records.log"

# Define the folder to be processed
folder="/home/daiyifei/net/psoriasis/Galderma/Phase3/AD_Blood_Genomics/LP-WGS_RAW/data"

# Check if the folder exists
if [ -d "${folder}" ]; then
	    echo "Processing folder: ${folder}" | tee -a ${total_log}
    else
	    echo "Folder ${folder} does not exist!"
            exit 1
fi

for subfolder in "${folder}"; do
	if [ -d "${subfolder}" ]; then
		echo "Processing subfolder: ${subfolder}" | tee -a ${total_log}
	else
		echo "${subfolder} is not a directory!"
	fi

	find "${subfolder}" -type f -name '*-WGS_R1_001.fastq.gz' | xargs -I {} -P 24 /minicubio/yifei/germline/Germline-short-variant-calling/WGS/bash/pre_core.sh "{}"

	if [ $? -ne 0 ]; then
		echo "Error occurred while processing files in ${folder}" | tee -a ${total_log}
		exit 1
	fi
done

echo "Data preprocessing completed."

