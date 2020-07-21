#
#Author: Maria Perica
#Title: 04_Make_MVM_Datatable.R
#Purpose: To create data table for use in 3dMVM script
#
#
library(readxl)
library(tidyr)
library(dplyr)
library(reshape2)
library(ggplot2)
library(purrr)
library(LNCDR)
library(lubridate)


#make table of subjects
#subjs <- read.table('/Volumes/Zeus/Orma/7T_MGS/data/subjects.txt',header=T)

subjs <- read.table('/Volumes/Zeus/Orma/7T_MGS/data/have_decon_2020-07-21.txt',header=T)

subjs <- separate(subjs, c("Subj"), into=c("Subj","vdate"),remove=FALSE)


database <- LNCDR::db_query("select id,sex,dob from person natural join enroll where etype like 'LunaID'")

database$dob <- ymd(database$dob)

subjs$vdate <- ymd(subjs$vdate)

subjs <-
  
  merge(subjs,database,by.x=c("Subj"), by.y=c("id"),all.x=T,all.y=F) %>%
  
  mutate(age=as.numeric(vdate-dob)/365.25)

#repeat each dataframe 3 times
cue <- subjs
delay <- subjs
resp <- subjs

#create a condition column
cue$condition <- "cue"
delay$condition <- "delay"
resp$condition <- "resp"

#make list of subject IDs
replist <- as.list(subjs$Subj)
#create input file column to point to bucket file for each subject
InputFile <-sapply(replist, function(x) sprintf('/Volumes/Zeus/Orma/7T_MGS/data/%s/cenfd0.5/%s_bucket+tlrc.HEAD', x,x))
inputfileexist <-sapply(InputFile, file.exists)
InputFile_cue <- lapply(replist, function(x) sprintf('/Volumes/Zeus/Orma/7T_MGS/data/%s/cenfd0.5/%s_bucket+tlrc.HEAD[cue#0_Coef]', x,x))
InputFile_delay<- lapply(replist, function(x) sprintf('/Volumes/Zeus/Orma/7T_MGS/data/%s/cenfd0.5/%s_bucket+tlrc.HEAD[delay#0_Coef]', x,x))
InputFile_resp <- lapply(replist, function(x) sprintf('/Volumes/Zeus/Orma/7T_MGS/data/%s/cenfd0.5/%s_bucket+tlrc.HEAD[resp#0_Coef]', x,x))

InputFile <- unlist(InputFile_cue)[inputfileexist]
d.mvm.cue <- cbind(cue[inputfileexist,], InputFile)

InputFile <- unlist(InputFile_delay)[inputfileexist]
d.mvm.delay <- cbind(delay[inputfileexist,], InputFile)

InputFile <- unlist(InputFile_resp)[inputfileexist]
d.mvm.resp <- cbind(resp[inputfileexist,], InputFile)

#rbind all 3 
d.mvm <- rbind(d.mvm.cue,d.mvm.delay)
d.mvm <- rbind(d.mvm,d.mvm.resp)



#### MVM ####

d.mvm<-d.mvm%>%select(-InputFile,InputFile)
d.cue <- subset(d.mvm, condition=="cue")
d.delay <- subset(d.mvm, condition=="delay")
d.resp <- subset(d.mvm, condition=="resp")



#write table
write.table(d.mvm, '/Volumes/Zeus/Orma/7T_MGS/scripts/07212020_mvm_table.txt', quote = FALSE, sep="\t", row.names = FALSE)
write.table(d.cue, '/Volumes/Zeus/Orma/7T_MGS/scripts/07212020_cue_mvm_table.txt', quote = FALSE, sep="\t", row.names = FALSE)
write.table(d.delay, '/Volumes/Zeus/Orma/7T_MGS/scripts/07212020_delay_mvm_table.txt', quote = FALSE, sep="\t", row.names = FALSE)
write.table(d.resp, '/Volumes/Zeus/Orma/7T_MGS/scripts/07212020_resp_mvm_table.txt', quote = FALSE, sep="\t", row.names = FALSE)
