#!/bin/bash

BAM=$1
OUTPUT_GVCF_BASE=$2

SAMPLE_NAME=$(basename "${BAM}" _recalibrated.bam | cut -d '_' -f 1)
GROUP_NAME=$(dirname "${BAM}" | xargs basename)

echo "Processing sample: ${SAMPLE_NAME}"

OUTPUT_GVCF_DIR="${OUTPUT_GVCF_BASE}/${SAMPLE_NAME}"

mkdir -p "${OUTPUT_GVCF_DIR}"

CHROMOSOMES=(chr1 chr2 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chr10 chr11 chr12 chr13 chr14 chr15 chr16 chr17 chr18 chr19 chr20 chr21 chr22 chrX chrY)

for CHROM in ${CHROMOSOMES[@]}; do
    (
    gatk --java-options '-Xmx60g' HaplotypeCaller \
        -R "${REFERENCE}" \
        -I "${BAM}" \
        --emit-ref-confidence GVCF \
        --active-probability-threshold 0.0015 \
        --assembly-region-padding 100 \
        -G StandardAnnotation \
        -G AS_StandardAnnotation \
        -G StandardHCAnnotation \
        -OBI true \
        -O "${OUTPUT_GVCF_DIR}/${SAMPLE_NAME}_${CHROM}_HC_calls.g.vcf.gz" \
        -L "${CHROM}"

    echo "HaplotypeCaller(GVCF mode) for ${CHROM}: ${SAMPLE_NAME} done"
    ) 
done

wait
echo "Variant calling for all chromosomes of ${SAMPLE_NAME} completed."
echo "-------------------------------------------------------------------------"

