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
subjs <- read.table('/Volumes/Zeus/Orma/7T_MGS/data/subjects.txt',header=T)

date <- read.table('/Volumes/Zeus/Orma/7T_MGS/data/subj_date.txt',header=T)

date <- separate(date, c("vdate"), into=c("Subj","vdate"),remove=TRUE)

subjs <- merge(subjs,date, by="Subj")

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
InputFile <-sapply(replist, function(x) sprintf('/Volumes/Zeus/Orma/7T_MGS/data/%s/%s_bucket+tlrc.HEAD', x,x))
inputfileexist <-sapply(InputFile, file.exists)
InputFile_cue <- lapply(replist, function(x) sprintf('/Volumes/Zeus/Orma/7T_MGS/data/%s/%s_bucket+tlrc.HEAD[cue#0_Coef]', x,x))
InputFile_delay<- lapply(replist, function(x) sprintf('/Volumes/Zeus/Orma/7T_MGS/data/%s/%s_bucket+tlrc.HEAD[delay#0_Coef]', x,x))
InputFile_resp <- lapply(replist, function(x) sprintf('/Volumes/Zeus/Orma/7T_MGS/data/%s/%s_bucket+tlrc.HEAD[resp#0_Coef]', x,x))

InputFile <- unlist(InputFile_cue)[inputfileexist]
d.mvm.cue <- cbind(cue[inputfileexist,], InputFile)

InputFile <- unlist(InputFile_delay)[inputfileexist]
d.mvm.delay <- cbind(delay[inputfileexist,], InputFile)

InputFile <- unlist(InputFile_resp)[inputfileexist]
d.mvm.resp <- cbind(resp[inputfileexist,], InputFile)

#rbind all 3 
d.mvm <- rbind(d.mvm.cue,d.mvm.delay)
d.mvm <- rbind(d.mvm,d.mvm.resp)

#### bring in spectroscopy data #### 
MRSI <- read.csv('/Volumes/Hera/Projects/7TBrainMech/scripts/mri/MRSI_roi/txt/subj_label_val_gm_24specs_20191102.csv')
age_df<-read.csv('/Volumes/Hera/Projects/7TBrainMech/scripts/mri/txt/ld8_age_sex.tsv', sep='\t')
names(age_df)[names(age_df) == 'dob'] <- 'DOB'
age_df<-age_df %>% separate(ld8,c("id","vdate"),remove=FALSE) %>% 
  mutate(vdate=ymd(vdate), DOB = ymd(DOB), age = round(as.numeric(vdate - DOB)/365.25, digits=2))
all <- merge (MRSI, age_df, by="ld8")
#make glutamate and gaba dataframes
glu_all <- all[,c("X", "ld8", "roi_num", "Glu","Cre", "Glu..SD", "Glu.Cre", "roi_label", "FSfracGM", "age", "sex")]
GABA_all <- all[,c("X", "ld8", "roi_num", "GABA", "Cre","GABA..SD", "GABA.Cre", "roi_label", "FSfracGM", "age", "sex")]

#CRLB exclusion 
glu <- subset(glu_all, glu_all$Glu..SD<=20)
GABA <- subset(GABA_all, GABA_all$GABA..SD<=20)

#### Right DLPFC ####
rdlpfc_glu <- subset(glu, glu$roi_num == 11)
rdlpfc_GABA <- GABA %>% filter(roi_num==11)
# remove implausible values
rdlpfc_glu <- rdlpfc_glu[rdlpfc_glu$Glu.Cre <20 & rdlpfc_glu$Glu.Cre > 0,]

# outlier removal
rdlpfc_glu_noout <- rdlpfc_glu %>% filter(Glu.Cre < (mean(rdlpfc_glu$Glu.Cre) + 3*sd(rdlpfc_glu$Glu.Cre))
                                          & Glu.Cre > (mean(rdlpfc_glu$Glu.Cre) - 3*sd(rdlpfc_glu$Glu.Cre)))
rdlpfc_gaba_noout <- rdlpfc_GABA %>% filter(GABA.Cre < (mean(rdlpfc_GABA$GABA.Cre) + 3*sd(rdlpfc_GABA$GABA.Cre))
                                            & GABA.Cre > (mean(rdlpfc_GABA$GABA.Cre) - 3*sd(rdlpfc_GABA$GABA.Cre)))
sep_rdlpfc_glu <- separate(rdlpfc_glu_noout, c("ld8"), into=c("Subj","vdate"),remove=TRUE)
sep_rdlpfc_glu <- select(sep_rdlpfc_glu,-c("roi_label"))
sep_rdlpfc_glu <- select(sep_rdlpfc_glu,-c("sex"))
sep_rdlpfc_glu<- select(sep_rdlpfc_glu,-c("age"))
sep_rdlpfc_glu <- select(sep_rdlpfc_glu,-c("vdate"))

sep_rdlpfc_gaba <- separate(rdlpfc_gaba_noout, c("ld8"), into=c("Subj","vdate"),remove=TRUE)
sep_rdlpfc_gaba <- select(sep_rdlpfc_gaba,-c("roi_label"))
sep_rdlpfc_gaba <- select(sep_rdlpfc_gaba,-c("sex"))
sep_rdlpfc_gaba <- select(sep_rdlpfc_gaba,-c("age"))
sep_rdlpfc_gaba <- select(sep_rdlpfc_gaba,-c("vdate"))

#df1 age 10,11,12,13,14
df1 <- sep_rdlpfc_glu %>% filter(age >=10, age < 15)
df1 <- select(df1,-c("age"))

#df2 age 15,16,17,18,19
df2 <- sep_rdlpfc_glu %>% filter(age >=15, age < 20)
df2 <- select(df2,-c("age"))

#df3 age 20,21,22,23,24
df3 <- sep_rdlpfc_glu %>% filter(age >=20, age < 25)
df3 <- select(df3,-c("age"))

#df4 age 25,26,27,28,29
df4 <- sep_rdlpfc_glu %>% filter(age >=25, age < 30)
df4 <- select(df4,-c("age"))

#### Left DLPFC####
ldlpfc_glu <- subset(glu, glu$roi_num == 12)
ldlpfc_GABA <- GABA %>% filter(roi_num==12)

# remove implausible values
ldlpfc_glu <- ldlpfc_glu[ldlpfc_glu$Glu.Cre <20 & ldlpfc_glu$Glu.Cre > 0,]

# outlier removal
ldlpfc_glu_noout <- ldlpfc_glu %>% filter(Glu.Cre < (mean(ldlpfc_glu$Glu.Cre) + 3*sd(ldlpfc_glu$Glu.Cre))
                                          & Glu.Cre > (mean(ldlpfc_glu$Glu.Cre) - 3*sd(ldlpfc_glu$Glu.Cre)))
ldlpfc_gaba_noout <- ldlpfc_GABA %>% filter(GABA.Cre < (mean(ldlpfc_GABA$GABA.Cre) + 3*sd(ldlpfc_GABA$GABA.Cre))
                                            & GABA.Cre > (mean(ldlpfc_GABA$GABA.Cre) - 3*sd(ldlpfc_GABA$GABA.Cre)))
sep_ldlpfc_glu <- separate(ldlpfc_glu_noout, c("ld8"), into=c("Subj","vdate"),remove=TRUE)
sep_ldlpfc_glu <- select(sep_ldlpfc_glu,-c("roi_label"))
sep_ldlpfc_glu <- select(sep_ldlpfc_glu,-c("sex"))
sep_ldlpfc_glu <- select(sep_ldlpfc_glu,-c("age"))
sep_ldlpfc_glu <- select(sep_ldlpfc_glu,-c("vdate"))

sep_ldlpfc_gaba <- separate(ldlpfc_gaba_noout, c("ld8"), into=c("Subj","vdate"),remove=TRUE)
sep_ldlpfc_gaba <- select(sep_ldlpfc_gaba,-c("roi_label"))
sep_ldlpfc_gaba <- select(sep_ldlpfc_gaba,-c("sex"))
sep_ldlpfc_gaba <- select(sep_ldlpfc_gaba,-c("age"))
sep_ldlpfc_gaba <- select(sep_ldlpfc_gaba,-c("vdate"))

#### R and L DLPFC ####
rdlpfc_glu_noout$hemisphere <- "right"
ldlpfc_glu_noout$hemisphere <- "left"
dlpfc_glu <- rbind(rdlpfc_glu_noout, ldlpfc_glu_noout)

rdlpfc_gaba_noout$hemisphere <- "right"
ldlpfc_gaba_noout$hemisphere <- "left"
dlpfc_gaba <- rbind(rdlpfc_gaba_noout, ldlpfc_gaba_noout)
sep_dlpfc_glu <- separate(dlpfc_glu, c("ld8"), into=c("Subj","vdate"),remove=TRUE)
sep_dlpfc_glu <- select(sep_dlpfc_glu,-c("roi_label"))
sep_dlpfc_glu <- select(sep_dlpfc_glu,-c("sex"))
sep_dlpfc_glu <- select(sep_dlpfc_glu,-c("age"))
sep_dlpfc_glu <- select(sep_dlpfc_glu,-c("vdate"))

#### MVM ####
#right dlpfc glu
d.mvm <- merge(d.mvm, sep_rdlpfc_glu, by="Subj")
d.mvm<-d.mvm%>%select(-InputFile,InputFile)

d.cue <- subset(d.mvm, condition=="cue")
d.delay <- subset(d.mvm, condition=="delay")
d.delay<-d.delay%>%select(-InputFile,InputFile)

d.resp <- subset(d.mvm, condition=="resp")

#write table
write.table(d.mvm, '/Volumes/Zeus/Orma/7T_MGS/scripts/rdlpfc_glu_mvm_table.txt', quote = FALSE, sep="\t", row.names = FALSE)
write.table(d.cue, '/Volumes/Zeus/Orma/7T_MGS/scripts/rdlpfc_glu_cue_mvm_table.txt', quote = FALSE, sep="\t", row.names = FALSE)
write.table(d.delay, '/Volumes/Zeus/Orma/7T_MGS/scripts/rdlpfc_glu_delay_mvm_table.txt', quote = FALSE, sep="\t", row.names = FALSE)
write.table(d.resp, '/Volumes/Zeus/Orma/7T_MGS/scripts/rdlpfc_glu_resp_mvm_table.txt', quote = FALSE, sep="\t", row.names = FALSE)
