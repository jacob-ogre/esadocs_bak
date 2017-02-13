#! /usr/bin/r
# BSD_2_clause

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

############################################################################
# Runner
#
# This portion of the script will be run on a daily basis (or multiple times per
# day). The idea is to stage the archive, check if MD5s have changed; if
# there is no change, delete; else add to archive. If length(baks|pattern) = 5,
# remove oldest.
############################################################################


bak_dat <- list.files(INFO_DIR ,
                      pattern = "bak_data_", full.names = TRUE)
bak_inf <- file.info(bak_dat)
bak_inf$fname <- row.names(bak_inf)
bak_inf <- dplyr::arrange(bak_inf, desc(ctime))
load(bak_inf$fname[1])

bak_analyzer_res <- es_analyzer_backup(
  "http://localhost:9200",
  "esadocs",
  STAGE_DIR
)

bak_maps_res <- sapply(
  TYPES,
  FUN = es_mapping_backup,
  server = "http://localhost:9200",
  index = "esadocs",
  bak_dir = STAGE_DIR
)

bak_data_res <- sapply(
  TYPES,
  FUN = es_data_backup,
  server = "http://localhost:9200",
  index = "esadocs",
  bak_dir = STAGE_DIR
)

fils <- list.files(STAGE_DIR, pattern = "*.json", full.names = TRUE)
md5s <- sapply(fils, digest, file = TRUE)
size <- sapply(fils, file.size)
new_bak_dat <- data_frame(file = names(md5s),
                          md5 = as.vector(md5s),
                          size = as.vector(size),
                          date = Sys.Date())

get_file_parts <- function(f) {
  fname <- basename(f)
  subd <- basename(dirname(f))
  clean1 <- gsub(fname, pattern = "bak_esadocs_|\\.json", replacement = "")
  clean2 <- gsub(clean1, pattern = "[0-9]{4}-[0-9]{2}-[0-9]{2}", replacement = "")
  category <- ifelse(
    grepl(clean2, pattern = "_data_"),
    "data",
    ifelse(
      grepl(clean2, pattern = "_mapping_"),
      "mapping",
      "analyzer"
    )
  )
  type <- ifelse(
    category == "analyzer",
    NA,
    gsub(clean2, pattern = "_data_|_mapping_", replacement = "")
  )
  return(list(file = f, fname = fname,
              subd = subd, category = category,
              type = type))
}

extra_data <- lapply(fils, get_file_parts)
extra_df <- bind_rows(extra_data)
combo_data <- left_join(new_bak_dat, extra_df, by = "file")
basel_data <- lapply(bak_dat$file, get_file_parts)
basel_df <- bind_rows(basel_data)
baseline <- left_join(bak_dat, basel_df, by = "file")

scp_to_bak <- function(f) {
  cmd <- paste0(
    "scp -C ", f, " ", Sys.getenv("BAK_SERVER"), ":", Sys.getenv("BAK_PATH")
  )
  res <- try(system(cmd, intern = FALSE, wait = TRUE))
  if(class(res) != "try-error") {
    new_msg <- paste0(
      Sys.time(), "\tscp_success\t", cur_rec$category, "\t", cur_rec$type, "\t",
      cur_rec$file, "\n"
    )
    new_cmd <- paste("echo '", new_msg, "' >>", LOG_PATH)
    system(new_cmd, intern = FALSE, wait = TRUE)
    return(res)
  } else {
    new_msg <- paste0(
      Sys.time(), "\tscp_err\t", cur_rec$category, "\t", cur_rec$type, "\t",
      cur_rec$file, "\n"
    )
    new_cmd <- paste("echo '", new_msg, "' >>", LOG_PATH)
    system(new_cmd, intern = FALSE, wait = TRUE)
    return(1)
  }
}

updated <- FALSE
for(i in 1:dim(combo_data)[1]) {
  cur_rec <- combo_data[i, ]
  if(!is.na(cur_rec$type)) {
    basel <- filter(baseline, category == cur_rec$category & type == cur_rec$type)
    if(cur_rec$md5 != basel$md5) {
      updated <- TRUE
      bak_dat <- filter(baseline, category != cur_rec$category &
                          type != cur_rec$type)
      bak_dat <- rbind(bak_dat, cur_rec)
      scp_res <- scp_to_bak(cur_rec$file)
      file.rename(cur_rec$file,
                  gsub(cur_rec$file, pattern = "staging", replacement = "data"))
      new_msg <- paste0(
        Sys.time(), "\tadded_backup\t", cur_rec$category, "\t", cur_rec$type, "\t",
        gsub(cur_rec$file, pattern = "staging", replacement = "data"), "\n"
      )
      new_cmd <- paste("echo '", new_msg, "' >>", LOG_PATH)
      system(new_cmd, intern = FALSE, wait = TRUE)
    } else {
      file.remove(cur_rec$file)
      new_msg <- paste0(
        Sys.time(), "\tno_updates\t", cur_rec$category, "\t", cur_rec$type, "\t",
        cur_rec$file, "\n"
      )
      new_cmd <- paste0("echo '", new_msg, "' >> ", LOG_PATH)
      system(new_cmd, intern = FALSE, wait = TRUE)
    }
  }
}

if(updated) {
  save(bak_dat,
       file = file.path(INFO_DIR, paste0("bak_data_", Sys.Date(), ".rda")))
}

# Now to gzip
new_fils <- list.files(DATA_DIR, pattern = "json$", full.names = TRUE)
gzip_res <- sapply(new_fils, gzip)
