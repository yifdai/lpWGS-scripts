#!/bin/bash

OUTPUT_BAM="/minicubio/yifei/germline/Germline-short-variant-calling/WGS/result/pre_data_WGS"
OUTPUT_GVCF_BASE="/minicubio/yifei/germline/Germline-short-variant-calling/WGS/result/HC_call_WGS"

# Run a test on the first _recalibrated.bam file
echo "Running test on the first sample..."
FIRST_BAM=$(find ${OUTPUT_BAM} -type f -name "*_recalibrated.bam" | head -n 1)
FIRST_OUTPUT_GVCF_DIR="${OUTPUT_GVCF_BASE}/$(basename $(dirname ${FIRST_BAM}))-$(basename ${FIRST_BAM} _recalibrated.bam)"
bash HC_call_core.sh "${FIRST_BAM}" "${FIRST_OUTPUT_GVCF_DIR}"
echo "Test completed."

# Now ask for user confirmation to proceed with all samples
read -p "Do you want to continue with all samples? [y/N] " answer
case ${answer:0:1} in
    y|Y )
        echo "Running on all samples..."
        find ${OUTPUT_BAM} -type f -name "*_recalibrated.bam" | awk -v base="${OUTPUT_GVCF_BASE}" '{print $0" "base"/"$(basename $(dirname $0))"-"$(basename $0,"_recalibrated.bam")}' |
        xargs -n 2 -P 8 bash HC_call_core.sh
        echo "Variant calling for all samples completed."
    ;;
    * )
        echo "Not proceeding with all samples. Exiting..."
        exit 1
    ;;
esac

