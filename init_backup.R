#! /usr/bin/r

library(elasticdumpr)
library(digest)
library(dplyr)
library(R.utils)

# readRenviron("/Users/jacobmalcom/.Renviron")
readRenviron("/home/jacobmalcom/.Renviron")

BASE_DIR <- path.expand("~/Data/ESAdocs_ES_bak")
STAGE_DIR <- file.path(BASE_DIR, "staging")
DATA_DIR <- file.path(BASE_DIR, "data")
INFO_DIR <- file.path(BASE_DIR, "info")
LOG_PATH <- file.path(INFO_DIR, "esadocs_es_bak.log")
TYPES <- c("candidate", "conserv_agmt", "consultation",
           "federal_register", "five_year_review", "misc",
           "policy", "recovery_plan")

# bak_analyzer_res <- es_analyzer_backup(
#   "http://localhost:9200",
#   "esadocs",
#   STAGE_DIR
# )
#
# bak_maps_res <- sapply(
#   TYPES,
#   FUN = es_mapping_backup,
#   server = "http://localhost:9200",
#   index = "esadocs",
#   bak_dir = STAGE_DIR
# )
#
# bak_data_res <- sapply(
#   TYPES,
#   FUN = es_data_backup,
#   server = "http://localhost:9200",
#   index = "esadocs",
#   bak_dir = STAGE_DIR
# )
#
# fils <- list.files(STAGE_DIR, pattern = "*.json", full.names = TRUE)
# md5s <- sapply(fils, digest, file = TRUE)
# size <- sapply(fils, file.size)
# bak_dat <- data_frame(file = names(md5s),
#                    md5 = as.vector(md5s),
#                    size = as.vector(size),
#                    date = Sys.Date())
# save(bak_dat,
#      file = file.path(INFO_DIR, paste0("bak_data_", Sys.Date(), ".rda")))
# gzip_res <- sapply(fils, gzip)
# nfil <- paste0(fils, ".gz")
# mv_res <- file.rename(nfil, gsub(nfil, pattern = "staging", replacement = "data"))

# cmd <- paste0("scp -r ", BASE_DIR, "/* ",
#               Sys.getenv("BAK_SERVER"), ":", Sys.getenv("BAK_PATH"))
# scp_res <- system(cmd, intern = FALSE, wait = TRUE)

# # > scp_res <- system(cmd, intern = FALSE, wait = TRUE)
# # bak_esadocs_misc_mapping_2017-02-13.json.gz                        100%  298     0.3KB/s   00:00
# # bak_esadocs_conserv_agmt_data_2017-02-13.json.gz                   100%   61MB  61.5MB/s   00:01
# # bak_esadocs_analyzer_2017-02-13.json.gz                            100%  351     0.3KB/s   00:00
# # bak_esadocs_recovery_plan_data_2017-02-13.json.gz                  100%   31MB  30.6MB/s   00:01
# # bak_esadocs_consultation_mapping_2017-02-13.json.gz                100%  302     0.3KB/s   00:00
# # bak_esadocs_federal_register_data_2017-02-13.json.gz               100%   95MB  47.4MB/s   00:02
# # bak_esadocs_five_year_review_mapping_2017-02-13.json.gz            100%  256     0.3KB/s   00:00
# # bak_esadocs_federal_register_mapping_2017-02-13.json.gz            100%  303     0.3KB/s   00:00
# # bak_esadocs_candidate_mapping_2017-02-13.json.gz                   100%  223     0.2KB/s   00:00
# # bak_esadocs_policy_data_2017-02-13.json.gz                         100%  990KB 989.5KB/s   00:00
# # bak_esadocs_recovery_plan_mapping_2017-02-13.json.gz               100%  317     0.3KB/s   00:00
# # bak_esadocs_five_year_review_data_2017-02-13.json.gz               100%   21MB  21.4MB/s   00:01
# # bak_esadocs_candidate_data_2017-02-13.json.gz                      100% 2218KB   2.2MB/s   00:01
# # bak_esadocs_policy_mapping_2017-02-13.json.gz                      100%  228     0.2KB/s   00:00
# # bak_esadocs_consultation_data_2017-02-13.json.gz                   100%  116MB  57.8MB/s   00:02
# # bak_esadocs_misc_data_2017-02-13.json.gz                           100%  100MB  50.0MB/s   00:02
# # bak_esadocs_conserv_agmt_mapping_2017-02-13.json.gz                100%  293     0.3KB/s   00:00
# # bak_data_2017-02-13.rda                                            100%  931     0.9KB/s   00:00

