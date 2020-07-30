#!/usr/bin/env Rscript
#
#Author: Maria Perica
#Title: 04_Make_MVM_Datatable.R
#Purpose: To create data table for use in 3dMVM script
#
# 20200730WF - add meanFD and nCensored
#
library(tidyr)
library(dplyr)
library(LNCDR)
library(lubridate)

# settings
FD_THRES <- .5    # high, but this is task data
MAX_CENSOR <- 288 # 192 TRs, 3 runs. 50% is 288. kids are bad at moving. would through away too many at lower vals
EXCLUDE_LD8 <- c("11782_20190930")

# output of ./02.1_decon_subj_list.bash
decon_subjs <- read.table('/Volumes/Zeus/Orma/7T_MGS/data/have_decon_2020-07-21.txt', header=T) %>%
    rename(ld8=Subj) %>%
    separate("ld8", into=c("Subj","vdate"), remove=FALSE) %>%
    mutate(vdate=ymd(vdate)) %>%
    group_by(Subj) %>% mutate(visit_num=rank(vdate)) %>% ungroup

# use database to get dob so we can calculate age. will merge on lunaid part of d8
database <- LNCDR::db_query("select id,sex,dob from person natural join enroll where etype like 'LunaID'") %>%
    mutate(dob=ymd(dob))

# use luna_date to find files for each visit
# exclude subject if they don't exist. also get age
filepatt = '/Volumes/Zeus/Orma/7T_MGS/data/%s/cenfd0.5/%s_bucket+tlrc.HEAD'
subjs_file <- merge(decon_subjs, database, by.x="Subj", by.y="id", all.x=T, all.y=F) %>%
  mutate(age=as.numeric(vdate-dob)/365.25) %>%
  mutate(headfile=sprintf(filepatt,ld8,ld8)) %>%
  filter(file.exists(headfile))
if(nrow(subjs_file)<=0L) stop('no files like ',filepatt)

## mean FD and total censored
# N.B. looking at all runs combined. one bad run next to perfect runs might not show up!
fd_info <- lapply(subjs_file$ld8, function(ld8) {
      g <- sprintf('/Volumes/Zeus/preproc/7TBrainMech_mgsencmem/MHTask_nost/%s/*/motion_info/fd.txt', ld8)
      d <- Sys.glob(g) %>% lapply(read.table) %>% bind_rows
      data.frame(ld8=ld8,
                 meanfd=mean(d$V1),
                 ncensor=length(which(d$V1 > FD_THRES)))
   }) %>% bind_rows
subjs  <- left_join(subjs_file, fd_info, by="ld8")


nmissing <- nrow(subjs) - nrow(decon_subjs)
if(abs(nmissing)>0)
    warning(sprintf('lost %d subjects in db merge or file check! %s',
                    nmissing, setdiff(decon_subjs$Subj, subjs$Subj) %>% paste0(collapse=", ")))

# repeat dataframe for cue, delay, and resp. set new "condition" column
d.mvm.all <-
  lapply(c("cue","delay","resp"),
         function(cnd) subjs %>% mutate(condition=cnd)) %>%
  bind_rows %>%
  # use 'headfile' to set the location of the named subjbrick and then remove the column
  mutate(InputFile=sprintf('%s[%s#0_Coef]', headfile, condition)) %>%
  select(-headfile)

# keep all, even bad, around
write.table(d.mvm.all, '/Volumes/Zeus/Orma/7T_MGS/scripts/07212020_mvm_table_noCenFilter.txt',
            quote = FALSE, sep="\t", row.names = FALSE)

# remove when we have too many censored
d.mvm <- d.mvm.all %>%
  filter(ncensor < MAX_CENSOR) %>%
  filter(!ld8 %in% EXCLUDE_LD8)

# note what we've removed
n_ld8_all <- length(unique(d.mvm.all$ld8)) 
censor_rm <- anti_join(d.mvm.all, d.mvm) %>% select(ld8, age,visit_num, meanfd, ncensor) %>% filter(!duplicated(.))
n_censored <- nrow(censor_rm)
if(n_censored>0) {
   cat(sprintf("removed %d/%d visits b/c ncensor > %d or manuall excluded\n", n_censored, n_ld8_all, MAX_CENSOR))
   print(censor_rm)
   #  see it in the terminal
   # d.mvm %>% filter(condition=='cue') %>% with(txtplot::txtplot(ncensor,age))
   #  or in ggplot
   # d.mvm %>% filter(condition=='cue') %>% with(ggplot2::qplot(ncensor,age))
}

# break up into cue delay and resp files
d.cue <- subset(d.mvm, condition=="cue")
d.delay <- subset(d.mvm, condition=="delay")
d.resp <- subset(d.mvm, condition=="resp")

# save all and individually
write.table(d.mvm, '/Volumes/Zeus/Orma/7T_MGS/scripts/07212020_mvm_table.txt', quote = FALSE, sep="\t", row.names = FALSE)
write.table(d.cue, '/Volumes/Zeus/Orma/7T_MGS/scripts/07212020_cue_mvm_table.txt', quote = FALSE, sep="\t", row.names = FALSE)
write.table(d.delay, '/Volumes/Zeus/Orma/7T_MGS/scripts/07212020_delay_mvm_table.txt', quote = FALSE, sep="\t", row.names = FALSE)
write.table(d.resp, '/Volumes/Zeus/Orma/7T_MGS/scripts/07212020_resp_mvm_table.txt', quote = FALSE, sep="\t", row.names = FALSE)
