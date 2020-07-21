#!/usr/bin/env Rscript
#
#Author: Maria Perica
#Title: 04_Make_MVM_Datatable.R
#Purpose: To create data table for use in 3dMVM script
#
#
library(tidyr)
library(dplyr)
library(LNCDR)
library(lubridate)


# output of ./02.1_decon_subj_list.bash
decon_subjs <- read.table('/Volumes/Zeus/Orma/7T_MGS/data/have_decon_2020-07-21.txt', header=T) %>%
    rename(ld8=Subj) %>%
  separate("ld8", into=c("Subj","vdate"), remove=FALSE) %>%
    mutate(vdate=ymd(vdate))

# use database to get dob so we can calculate age. will merge on lunaid part of d8
database <- LNCDR::db_query("select id,sex,dob from person natural join enroll where etype like 'LunaID'") %>%
    mutate(dob=ymd(dob))

# use luna_date to find files for each visit
# exclude subject if they don't exist. also get age
filepatt = '/Volumes/Zeus/Orma/7T_MGS/data/%s/cenfd0.5/%s_bucket+tlrc.HEAD'
subjs <- merge(decon_subjs, database, by.x="Subj", by.y="id", all.x=T, all.y=F) %>%
  mutate(age=as.numeric(vdate-dob)/365.25) %>%
  mutate(headfile=sprintf(filepatt,ld8,ld8)) %>%
  filter(file.exists(headfile))

if(nrow(subjs)<=0L) stop('no files like ',filepatt)
if(nrow(subjs) != nrow(decon_subjs))
    warning('lost some subjects in db merge or file check! ', setdiff(decon_subjs$Subj, subjs$Subj) %>% paste0(collapse=", "))

# repeat dataframe for cue, delay, and resp. set new "condition" column
d.mvm <-
  lapply(c("cue","delay","resp"),
         function(cnd) subjs %>% mutate(condition=cnd)) %>%
  bind_rows %>%
  # use 'headfile' to set the location of the named subjbrick and then remove the column
  mutate(InputFile=sprintf('%s[%s#0_Coef]', headfile, condition)) %>%
  select(-headfile)


# break up into cue delay and resp files
d.cue <- subset(d.mvm, condition=="cue")
d.delay <- subset(d.mvm, condition=="delay")
d.resp <- subset(d.mvm, condition=="resp")

# save all and individually
write.table(d.mvm, '/Volumes/Zeus/Orma/7T_MGS/scripts/07212020_mvm_table.txt', quote = FALSE, sep="\t", row.names = FALSE)
write.table(d.cue, '/Volumes/Zeus/Orma/7T_MGS/scripts/07212020_cue_mvm_table.txt', quote = FALSE, sep="\t", row.names = FALSE)
write.table(d.delay, '/Volumes/Zeus/Orma/7T_MGS/scripts/07212020_delay_mvm_table.txt', quote = FALSE, sep="\t", row.names = FALSE)
write.table(d.resp, '/Volumes/Zeus/Orma/7T_MGS/scripts/07212020_resp_mvm_table.txt', quote = FALSE, sep="\t", row.names = FALSE)
