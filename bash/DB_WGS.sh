<< 'Comment'
    For Code chunk 1: 
    'sample_names': The corresponding sample names are stored in an array for each folder.
    e.g. folder1 | sample1_HC_calls.g.vcf.gz 
                   sample2_HC_calls.g.vcf.gz
         folder2 | sample3_HC_calls.g.vcf.gz
                   sample4_HC_calls.g.vcf.gz
    Then sample_names = {
            [folder1] = (sample1 sample2),
            [folder2] = (sample3 sample4)
    }

    For Code chunk 2:
    'v_arguments': A string that consists of all samples that need to merge (Each folder), and form it to GATK command line, each 
    e.g. For the previous example folders, we have v_arguments as;
    For folder1
    -V folder1/sample1_HC_calls.g.vcf.gz -V folder1/sample2_HC_calls.g.vcf.gz
    For folder2
    -V folder2/sample3_HC_calls.g.vcf.gz -V folder2/sample4_HC_calls.g.vcf.gz
}      
Comment

cd /net/psoriasis/home/daiyifei/germline/merge_WES/

CHROMOSOMES=(chr1 chr2 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chr10 chr11 chr12 chr13 chr14 chr15 chr16 chr17 chr18 chr19 chr20 chr21 chr22 chrX chrY)

declare -A sample_names

# Code chunk 1
for folder in ${FOLDER_PREFIX}*; do
    if [ -d "${folder}" ]; then
        echo "Processing folder: ${folder}"
        
        # Initialize an empty array for this folder
        sample_names["${folder}"]=()
        
        for R1 in "${folder}"/*-WXS_R1_001.fastq.gz; do
            # Determine the sample name
            SAMPLE_NAME=$(basename "$R1" -WXS_R1_001.fastq.gz)
            
            # Store the sample name in the array associated with the folder
            sample_names["${folder}"]+=("$SAMPLE_NAME")
        done
    fi
done

# Code chunk 2
## Merging all gvcf from the same folder to one database
merge_function() {
    local folder=$1
    local CHROM=$2
    local v_arguments=""
    
    for sample in "${sample_names["${folder}"][@]}"; do
        # Add each sample to the -V arguments string
        v_arguments+="-V ${folder}/${sample}_${CHROM}_HC_calls.g.vcf.gz "
    done

    # Run gatk GenomicsDBImport with all samples from the folder
    gatk --java-options "-Xmx4g" GenomicsDBImport \
        $v_arguments \
        --genomicsdb-workspace-path "jointed-variants-db-${folder}_${CHROM}" \
        -L "${CHROM}" \
        --tmp-dir "temp_${folder}_${CHROM}"
}

export -f merge_function

for folder in "${!sample_names[@]}"; do
    echo "Running GenomicsDBImport for folder: ${folder}"
    parallel --jobs 7 merge_function ::: "${folder}" ::: "${CHROMOSOMES[@]}"

    # Running gatk GenotypeGVCFs for each chromosome
    echo "Running gatk GenotypeGVCFs for each chromosome"
    parallel --jobs 12 --colsep ' ' \
        'gatk --java-options "-Xmx4g" GenotypeGVCFs \
        -R ${REFERENCE} \
        -V gendb://jointed-variants-db-{1}-{2} \
        -O data/processed/wes/jointed-variants/jointed-variants-{1}-{2}.vcf \
        --tmp-dir "temp-{1}-{2}"' ::: "${folder}" ::: "${CHROMOSOMES[@]}"
    
    echo "Process completed."
done

<< 'Comment'
Reference code from Jose :
cat chroms.txt | parallel --jobs 7 bin/gatk-4.2.6.1/gatk GenomicsDBImport -V data/processed/wes/220805/1600159360S01-WES.vcf.gz -V data/processed/wes/220528/FR01_1600159825S01-WXS.vcf.gz -V data/processed/wes/220528/FR01_1600222573S01-WXS.vcf.gz -V [...] -L {} --genomicsdb-workspace-path jointed-variants-db-{} --tmp-dir temp-{}

cat chroms.txt | parallel --jobs 12 bin/gatk-4.2.6.1/gatk GenotypeGVCFs -R data/raw/Homo_sapiens_assembly38.fasta -V gendb://jointed-variants-db-{} -L {} -O data/processed/wes/jointed-variants/jointed-variants-{}.vcf --tmp-dir temp-{}
Comment
