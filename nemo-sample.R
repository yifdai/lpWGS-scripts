setwd("/minicubio/yifei/germline/Germline-short-variant-calling/")

data <- read.csv("./lpWGS-scripts/Sample_List_LPWGS_withClinical_20230612.csv")

opt <- paste(data[data$TRT01P == "Nemolizumab", "SampleID"])

writeLines(opt, con = "./WGS/bash/Nemo-sample.txt")

