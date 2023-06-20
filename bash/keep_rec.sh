dir="/net/psoriasis/home/daiyifei/germline/Germline-short-variant-calling/WGS/result/pre_data_WGS"

find "$dir" -type f | while read file; do
    # check whether file ended with _recalibrated.bai、_recalibrated.bam or _recal.table
    if [[ ! "$file" =~ _recalibrated\.bai$ ]] && [[ ! "$file" =~ _recalibrated\.bam$ ]] && [[ ! "$file" =~ _recal\.table$ ]]; then
        # if not one of those three output files, then delete it.
        rm "$file"
    fi
done

