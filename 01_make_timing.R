##Title: Time Script Preliminary 
##Author: Julia Pan 
##Date Created: 3/1/19
##Purpose: to organize run order and factor variance 

# apt install libxml2-dev # ubuntu package
#install.packages("XML")  # CRAN package
#install.packages("devtools")
#library(devtools)
#install_github("LabNeuroCogDevel/LNCDR") # github

## import all subject's timing files to R
library(stringr)
library(tidyr)
library(dplyr)
library(LNCDR)


# b has all subject timing files to R 

b <- system("find /Volumes/L/bea_res/Data/Tasks/MGSEncMem/7T/1*_2*/ -iname '*_view.csv' ", intern = T) %>% 
  lapply(function(x) read.csv(x,header=T) %>% 
           mutate(f=basename(x),subj=stringr::str_extract(x,"\\d{5}_\\d{8}"))) %>% 
  bind_rows

# can't use this because some file structures are different
#b <- Sys.glob('/Volumes/L/bea_res/Data/Tasks/MGSEncMem/7T/1*_2*/*/mri_mgsenc*/*_mri_*_view.csv') %>% 
#  lapply(function(x) read.csv(x,header=T) %>% 
#           mutate(f=basename(x),subj=stringr::str_extract(x,"\\d{5}_\\d{8}"))) %>% 
#  bind_rows


## Create new column to specify run number by extracting from file name

b <- separate(b, f, c("subj", "date", "mri", "run", "data"), sep = "_", remove = TRUE)
b <- subset(b, select = -c(mri, data))


# Create additional column of the difference between mgs column and dly column

b["diff_mgs_dly"] <- NA
b$diff_mgs_dly <- (b$mgs - b$dly)

##find cue times for subject 1 (use run 1), then find times for run 2 

b$ld8 <- paste(b$subj, b$date, sep='_')


# 1: create list/vector of subject IDs
# 2: create for loop to loop through list of subject IDs
# 3: write save1D function for cue timing files

setwd("/Volumes/Zeus/Orma/7T_MGS")

# created list of subject IDs
subj.list <- as.list(unique(select(b, ld8)))
#subj.list <- as.list(c("11741","11747","11758","11761"))




#create a for loop 
#error in description 

names(b)[names(b) == 'run'] <- 'block'

# ld8 <- paste(subj.list$subj, subj.list$date, sep='_')

for(s in subj.list$ld8) {
#for(s in subj.list) {
  setwd("/Volumes/Zeus/Orma/7T_MGS/data")
  if(!dir.exists(s)) dir.create(s)
  setwd(s)
  sub.cue <- paste(s, "_cue.1D", sep="")
  b %>%
    filter(ld8 %in% s) %>%
    save1D(colname="cue", nblocks=3, fname = sub.cue)
  sub.delay <- paste(s, "_delay.1D", sep="")
  b %>%
    filter(ld8 %in% s) %>%
    save1D(colname="dly", nblocks=3, dur="diff_mgs_dly", fname = sub.delay)
  sub.resp <- paste(s, "_resp.1D", sep="")
  b %>%
    filter(ld8 %in% s) %>%
    save1D(colname="mgs", nblocks=3, fname = sub.resp)
}



