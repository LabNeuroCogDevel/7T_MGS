#!/usr/bin/env Rscript

##Title: Time Script Preliminary 
##Author: Julia Pan 
##Date Created: 3/1/19
##Purpose: to organize run order and factor variance 
## 20201023WF - functions, tests, and merge with survey

# apt install libxml2-dev # ubuntu package
#install.packages("XML")  # CRAN package
#install.packages("devtools")
#library(devtools)
#install_github("LabNeuroCogDevel/LNCDR") # github

## import all subject's timing files to R
suppressPackageStartupMessages({
library(stringr)
library(tidyr)
library(dplyr)
library(LNCDR) })



#' @title normpath
#' path is created sometimes on win7 sometimes MacOS. standardize it
#'
#' @tests
#' expect_equal(normpath("a/b\\\\c\\\\d.png"),
#'              "a/b/c/d.png")
#' expect_equal(normpath("a/b\\\\c\\\\d.png"),
#'              "x/b/c/d.png")
normpath <- function(path) gsub("\\\\+","/", path)

read_data <- function() {
    # b has all subject timing files to R 
    cat('#finding all view.csv files... ')
    b_files <- system("find /Volumes/L/bea_res/Data/Tasks/MGSEncMem/7T/1*_2*/ -iname '*_view.csv' ", intern = T)
    cat(length(b_files), "found\n")

    cat("#reading views\n")
    b_all <- lapply(b_files, function(x) read.csv(x,header=T) %>% 
            mutate(f=basename(x),subj=stringr::str_extract(x,"\\d{5}_\\d{8}"))) %>% 
    bind_rows
    ## Create new column to specify run number by extracting from file name
    # * Filename carries a lot of info not otherwise in the data. extract that and remove the excess
    # * noramlize image path for merging to survey. survey run on macOS. task run on Win7
    # * derive duration of delay used for 1D modulation
    b <- b_all %>%
        separate(f, c("subj", "date", "mri", "run", "data"), sep = "_", remove = TRUE) %>%
        select(-mri, -data) %>%
        mutate(imgfile = normpath(imgfile),
            diff_mgs_dly = mgs - dly,
            ld8 = paste(subj, date, sep="_"))


    # 20201021WF - get performance too
    cat('#finding all recall.csv files...')
    all_surveys <- system("find /Volumes/L/bea_res/Data/Tasks/MGSEncMem/7T/1*_2*/ -iname '*_recall*csv' ", intern = T)
    cat(length(all_surveys), "found\n")

    cat("#reading recalls\n")
    srvy <- all_surveys %>% 
    lapply(function(x) read.csv(x,header=T) %>% 
            mutate(f=basename(x),subj=stringr::str_extract(x,"\\d{5}_\\d{8}")) %>%
            select(-X)) %>% 
    bind_rows %>%
    unique

    # corkeys like "('0','5')" but we need it as two columns to compare to what they actually pushed
    # with that we can score known/unkonw and side
    # we need to keep ld8 (id) and imgfile to merge back
    srvy_iscor <-srvy %>%
        select(ld8=subj, corkeys, know_key, dir_key, imgfile) %>%
        mutate(corkeys=gsub('[^0-9 ]','',corkeys)) %>%
        separate(corkeys,c('exp_know','exp_dir'),sep="\\s+") %>%
        mutate(iscor_known=know_key==exp_know,
            iscor_dir=dir_key==exp_dir,
            imgfile=normpath(imgfile))

    # add survey and task together
    # prepare for save1D:
    #  requires there to be a block column that desribes runnumber
    #  wont hurt to be sorted by onset time
    #  TODO/BUG: why is unique necessary?
    tsk_and_srvy <- merge(b, srvy_iscor, by=c("ld8","imgfile"), all.x=T)  %>%
        unique %>%
        arrange(ld8, run, trial) %>%
        rename(block=run) 
}

#' name1d
#' @description
#' find cue times for subject 1 (use run 1), then find times for run 2 
#' 1: create list/vector of subject IDs
#' 2: create for loop to loop through list of subject IDs
#' 3: write save1D function for cue timing files
#'
#' @tests
#' expect_equal(name1d('12_34','delay',mkdir=F),
#'             "/Volumes/Zeus/Orma/7T_MGS/data/12_34/delay.1D")
#' expect_equal(name1d('12_34','delay','subdir', mkdir=F),
#'             "/Volumes/Zeus/Orma/7T_MGS/data/12_34/subdir/delay.1D")
name1d <- function(ld8, desc, subfolder=NULL, mkdir=TRUE) {
  outdir <- file.path("/Volumes/Zeus/Orma/7T_MGS/data/", ld8, "1d")
  # create additional folder if given subfolder
  if(!is.null(subfolder)) outdir <- file.path(outdir, subfolder)
  # make it if it doesn't exist
  if(!dir.exists(outdir) && mkdir) dir.create(outdir, recursive=T)
  # return final name
  sprintf("%s/%s.1D", outdir, desc)
}

# untested -- modifies files
save_each_event <- function(d, subfolder=NULL) {
  ld8 <- first(d$ld8)
  cat("# cue/dly/mgs for", ld8,
      ifelse(is.null(subfolder),"",subfolder),
      "\n")
  save1D(d, colname="cue", nblocks=3, fname=name1d(ld8,"cue", subfolder))
  save1D(d, colname="dly", nblocks=3, dur="diff_mgs_dly", fname=name1d(ld8,"delay", subfolder))
  save1D(d, colname="mgs", nblocks=3, fname=name1d(ld8, "resp", subfolder))
}

#'@name img_desc
#' make a describe trial type from response (remembered, forgotten, no image)
#'
#' @tests
#'  expect_equal(img_desc(c(T,F,NA)),
#'               c("img_rmbr", "img_frgt", "img_none"))
img_desc <- function(iscor_known) {
    case_when(
          is.na(iscor_known) ~ "img_none",
          iscor_known        ~ "img_rmbr",
          !iscor_known       ~ "img_frgt",
          TRUE               ~ "CODEERR")
}

write_by_srvytype <- function(d_subknown){
   ld8 <- first(d_subknown$ld8)
   imgdesc <- first(d_subknown$imgdesc)
   # save the normal 3 1D files, but put them in a subdirectory for what imgdesc case we have
   save_each_event(d_subknown, imgdesc)
   # mgs duration is 2seconds. total triald uration is onset of vgs from onset of mgs + mgs duration
   d_subknown %>%
       mutate(trial_dur=(mgs+2)-vgs) %>%
       save1D("trial", nblocks=3, fname=name1d(ld8, "trial", imgdesc), dur="trial_dur")
}

data_to_1D <- function(){
    tsk_and_srvy <- read_data()
    idlist <- unique(tsk_and_srvy$ld8)
    for(s in idlist) {
        # filter just the subject we are on and describe trial based on response
        this_subj <- filter(tsk_and_srvy, ld8 %in% s)  %>%
            mutate(imgdesc=img_desc(iscor_known))

        # save cue, delay, and resp .1D files
        save_each_event(this_subj)

        # run seperately for each imgdesc
        imgdesc_df_list <- split(this_subj, this_subj$imgdesc)
        lapply(imgdesc_df_list, write_by_srvytype)
    }
}

# when not sourced (e.g. testing), actually run
if (sys.nframe() == 0) data_to_1D() 
