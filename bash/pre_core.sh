#!/bin/bash

R1=$1

# Determine the parent folder (90-xxxxx)
folder=$(basename $(dirname "${R1}"))
if [[ $folder != 90-* ]]; then
    folder=$(basename $(dirname $(dirname "${R1}")))
fi

# Determine the sample name and corresponding R2 file
SAMPLE_NAME=$(basename "$R1" | sed -e 's/-WGS_R1_001.fastq.gz//g')
R1_SUFFIX=$(basename "$R1" | sed -e 's/.*\(-WGS_R1_001.fastq.gz\)/\1/')
R2_SUFFIX=$(echo "$R1_SUFFIX" | sed -e 's/_R1_001.fastq.gz/_R2_001.fastq.gz/')
R2=$(dirname "${R1}")/${SAMPLE_NAME}${R2_SUFFIX}

log_file="/minicubio/yifei/germline/Germline-short-variant-calling/WGS/log_updated/${folder}-${SAMPLE_NAME}.log"

OUT="/minicubio/yifei/germline/Germline-short-variant-calling/WGS/result/pre_data_WGS_updated/${folder}-${SAMPLE_NAME}"

# Check if the target folder already exists
if [ -d "${OUT}" ]; then
    echo "Target folder ${OUT} already exists, skipping this iteration." | tee -a "$log_file"
    exit 0
fi

mkdir -p "/minicubio/yifei/germline/Germline-short-variant-calling/WGS/result/pre_data_WGS_updated/${folder}-${SAMPLE_NAME}"
echo "Processing ${folder}-${SAMPLE_NAME}"

{

		    # Perform BWA alignment
		    # Pretty time-consuming
		    bwa mem -M -t 128 -R "@RG\tID:${folder}-${SAMPLE_NAME}\tSM:${folder}-${SAMPLE_NAME}\tPL:ILLUMINA" "$REFERENCE" "$R1" "$R2" > "${OUT}/${folder}-${SAMPLE_NAME}.sam"
		    echo "--------------------------------------------"
		    echo "BWA alignment: ${folder}-${SAMPLE_NAME} Done"
                    
		    # SAM to BAM convertion
		    samtools view -S -b -@ 8 "${OUT}/${folder}-${SAMPLE_NAME}.sam" > "${OUT}/${folder}-${SAMPLE_NAME}.bam"
		    echo "--------------------------------------------"
		    echo "SAM to BAM conversion for ${folder}-${SAMPLE_NAME} Done"

                    # rm "${OUT}/${folder}-${SAMPLE_NAME}.sam"

		    # Sort BAM by quaryname
		    samtools sort -n -o "${OUT}/${folder}-${SAMPLE_NAME}.sorted.bam" -@ 8 "${OUT}/${folder}-${SAMPLE_NAME}.bam"
		    echo "--------------------------------------------"
		    echo "Sort quaryname BAM: ${folder}-${SAMPLE_NAME} Done"

		    # rm "${OUT}/${folder}-${SAMPLE_NAME}.bam"

		    # Fixmate
                    samtools fixmate -m -@ 8 "${OUT}/${folder}-${SAMPLE_NAME}.sorted.bam" "${OUT}/${folder}-${SAMPLE_NAME}.fixmate.bam"
		    echo "--------------------------------------------"
                    echo "Fixmate: ${folder}-${SAMPLE_NAME} Done"

                    # Sort BAM by coordinate
                    samtools sort -o "${OUT}/${folder}-${SAMPLE_NAME}.sorted.bam" -@ 8 "${OUT}/${folder}-${SAMPLE_NAME}.fixmate.bam"
                    echo "--------------------------------------------"
                    echo "Sort coordinate BAM: ${folder}-${SAMPLE_NAME} Done"

		    # rm "${OUT}/${folder}-${SAMPLE_NAME}.fixmate.bam"

		    # Mark Duplicates
		    samtools markdup -@ 8 "${OUT}/${folder}-${SAMPLE_NAME}.sorted.bam" "${OUT}/${folder}-${SAMPLE_NAME}.markdup.bam" 
		    echo "--------------------------------------------"
		    echo "Mark Duplicates: ${folder}-${SAMPLE_NAME} Done"
		    
                    # rm "${OUT}/${folder}-${SAMPLE_NAME}.sorted.bam"

		    # Indexing
		    samtools index "${OUT}/${folder}-${SAMPLE_NAME}.markdup.bam"
		    echo "--------------------------------------------"
		    echo "Indexing: ${folder}-${SAMPLE_NAME} Done"

		    # BQSR
		    # Generate recalibration table
		    gatk --java-options '-Xmx60g' BaseRecalibrator \
			-I "${OUT}/${folder}-${SAMPLE_NAME}.markdup.bam" \
			--reference "${REFERENCE}" \
			--known-sites "${HS38_VCF}" \
			-O "${OUT}/${folder}-${SAMPLE_NAME}_recal.table"
			
		    echo "--------------------------------------------"
		    echo "Recalibration table: ${folder}-${SAMPLE_NAME} Done"

		    # Apply recalibration
		    gatk --java-options '-Xmx60g' ApplyBQSR \
			-I "${OUT}/${folder}-${SAMPLE_NAME}.markdup.bam" \
			--reference "${REFERENCE}" \
			--bqsr-recal-file "${OUT}/${folder}-${SAMPLE_NAME}_recal.table" \
			-O "${OUT}/${folder}-${SAMPLE_NAME}_recalibrated.bam"
		    
		    echo "--------------------------------------------"
		    echo "Apply recalibration: ${folder}-${SAMPLE_NAME} Done"
		    echo "Sample complete: ${folder}-${SAMPLE_NAME}"

		    # rm "${OUT}/${folder}-${SAMPLE_NAME}.markdup.bam"

		    # Record the processed files with folder information
		    echo "${folder}/$(basename "$R1")" >> /minicubio/yifei/germline/Germline-short-variant-calling/WGS/result/pre_data_WGS_updated/preprocessed_sample_names.txt
		    echo "${folder}/$(basename "$R2")" >> /minicubio/yifei/germline/Germline-short-variant-calling/WGS/result/pre_data_WGS_updated/preprocessed_sample_names.txt

		    
} 2>&1 | tee "$log_file"

