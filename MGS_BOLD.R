# Maria Perica
# 12/13/2019
# extracting ROIs from MGS data 
library(dplyr); library(tidyr); library(ggplot2); library(lubridate)

#### Get BOLD data for the delay period #### 
matlabbold <- read.csv('/Volumes/Zeus/Finn/mvm_tbl_withBOLD.csv')
mgsbold <- read.csv('/Volumes/Zeus/Orma/7T_MGS/group_contrasts/beta_clust.txt')
mgsbold2 <- read.csv('/Volumes/Zeus/Orma/7T_MGS/group_contrasts/beta_clust2.txt')
delay_mgsbold <- mgsbold2 %>% filter(event=='delay')

#### Get MRS Data ####

# import spectroscopy data
MRSI <- read.csv('/Volumes/Hera/Projects/7TBrainMech/scripts/mri/MRSI_roi/txt/subj_label_val_gm_24specs_20191102.csv')

# get id, age, gender, and DOB 
# [1] "ld8"    "age"    "Gender" "DOB"
age_df<-read.csv('/Volumes/Hera/Projects/7TBrainMech/scripts/mri/txt/ld8_age_sex.tsv', sep='\t')
names(age_df)[names(age_df) == 'dob'] <- 'DOB'
age_df<-age_df %>% separate(ld8,c("id","vdate"),remove=FALSE) %>% 
  mutate(vdate=ymd(vdate), DOB = ymd(DOB), age = round(as.numeric(vdate - DOB)/365.25, digits=2))

# get average frame displacement during rest
fd <- read.csv("/Volumes/Hera/Projects/7TBrainMech/scripts/mri/txt/rest_fd.csv", sep=' ')

# mergin'
age_fd <- merge(age_df, fd, by="id")
all <- merge (MRSI, age_fd, by="ld8")

#make glutamate and gaba dataframes
glu_all <- all[,c("X", "ld8", "roi_num", "Glu","Cre", "Glu..SD", "Glu.Cre", "roi_label", "FSfracGM", "age", "sex", "fd")]
GABA_all <- all[,c("X", "ld8", "roi_num", "GABA", "Cre","GABA..SD", "GABA.Cre", "roi_label", "FSfracGM", "age", "sex", "fd")]

#CRLB exclusion 
glu <- subset(glu_all, glu_all$Glu..SD<=20)
GABA <- subset(GABA_all, GABA_all$GABA..SD<=20)
gluGABA <- merge(glu, GABA, by = c("ld8","roi_num", "X","roi_label", "FSfracGM", "age", "sex", "fd"))

#### Get MGS Data ####
MGS <- read.csv('/Volumes/Hera/Projects/7TBrainMech/scripts/eeg/eog_cal/eog_group_data_20191212.csv')

#### Right DLPFC ####
rdlpfc_glu <- subset(glu, glu$roi_num == 11)
# remove implausible values
rdlpfc_glu <- rdlpfc_glu[rdlpfc_glu$Glu.Cre <20 & rdlpfc_glu$Glu.Cre > 0,]
# outlier removal
rdlpfc_glu_noout <- rdlpfc_glu %>% filter(Glu.Cre < (mean(rdlpfc_glu$Glu.Cre) + 3*sd(rdlpfc_glu$Glu.Cre))
                                          & Glu.Cre > (mean(rdlpfc_glu$Glu.Cre) - 3*sd(rdlpfc_glu$Glu.Cre)))
sep_rdlpfc_glu <- separate(rdlpfc_glu_noout, c("ld8"), into=c("LunaID","vdate"),remove=TRUE)
MGS_glu <- merge(MGS, sep_rdlpfc_glu, by.x="LunaID", by.y="LunaID")
mgs_bold_glu <- merge(MGS_glu, delay_mgsbold, by.x="LunaID", by.y="subj")

sep_rdlpfc_glu <- separate(rdlpfc_glu_noout, c("ld8"), into=c("LunaID","vdate"),remove=TRUE)
mgs_bold_glu <- merge(MGS_glu, delay_mgsbold, by.x="LunaID", by.y="subj")
mgs_bold_glu$invage <- (mgs_bold_glu$age)^-1
#### STS ####
sts_glu <- glu %>% filter(roi_num==13)
sts_glu <- sts_glu[sts_glu$Glu.Cre <20 & sts_glu$Glu.Cre > 0,]
sts_glu_noout <- sts_glu %>% filter(Glu.Cre < (mean(sts_glu$Glu.Cre) + 3*sd(sts_glu$Glu.Cre))
                                    & Glu.Cre > (mean(sts_glu$Glu.Cre) - 3*sd(sts_glu$Glu.Cre)))
sep_sts_glu <- separate(sts_glu_noout, c("ld8"), into=c("LunaID","vdate"),remove=TRUE)
MGS_glu <- merge(MGS, sep_sts_glu, by.x="LunaID", by.y="LunaID")
mgs_bold_glu <- merge(MGS_glu, delay_mgsbold, by.x="LunaID", by.y="subj")


#### ROI 1 - STG ####
roi1 <- mgs_bold_glu %>% filter(roi=='roi1')
roi1_bold_glu<- lm(data=roi1, beta~log(Glu.Cre)*age)
summary(roi1_bold_glu)
ggplot(roi1, aes(x=log(Glu.Cre), y=beta)) + geom_point(aes(color=age))  + stat_smooth(method='lm')

roi1_MRS_noout <- roi1 %>% filter(beta < (mean(roi1$beta) + 3*sd(roi1$beta))
                                          & beta > (mean(roi1$beta) - 3*sd(roi1$beta)))
roi1_bold_glu_noout<- lm(data=roi1_MRS_noout, beta~log(Glu.Cre)*age)
summary(roi1_bold_glu_noout)
ggplot(roi1_MRS_noout, aes(x=log(Glu.Cre), y=beta)) + geom_point() + stat_smooth(method='lm')

roi1_MRS_noout <- roi1_MRS_noout %>% filter(roi1_MRS_noout$DispErr_deg<5)

#roi1_bold_beh<- lm(data=roi1_MRS_noout, PosErr_deg~beta)
#summary(roi1_bold_beh)
#ggplot(roi1_MRS_noout, aes(x=beta, y=PosErr_deg)) + geom_point() + stat_smooth(method='lm')

roi1_bold_beh<- lm(data=roi1_MRS_noout, DispErr_deg~beta)
summary(roi1_bold_beh)
ggplot(roi1_MRS_noout, aes(x=beta, y=DispErr_deg)) + geom_point() + stat_smooth(method='lm')

#### ROI 2 - MFG ####
roi2 <- mgs_bold_glu %>% filter(roi=='roi2')
roi2_bold_glu<- lm(data=roi2, beta~Glu.Cre)
summary(roi2_bold_glu)
ggplot(roi2_MRS, aes(x=Glu.Cre, y=beta)) + geom_point() + stat_smooth(method='lm')

roi2_MRS_noout <- roi2 %>% filter(beta < (mean(roi2$beta) + 3*sd(roi2$beta))
                                      & beta > (mean(roi2$beta) - 3*sd(roi2$beta)))
roi2_bold_glu_noout<- lm(data=roi2_MRS_noout, beta~log(Glu.Cre)*age)
summary(roi2_bold_glu_noout)
ggplot(roi2_MRS_noout, aes(x=log(Glu.Cre), y=beta)) + geom_point() + stat_smooth(method='lm')

roi2_bold_beh<- lm(data=roi2_MRS_noout, PosErr_deg~beta)
summary(roi2_bold_beh)
ggplot(roi2_MRS_noout, aes(x=beta, y=PosErr_deg)) + geom_point() + stat_smooth(method='lm')
roi2_MRS_noout_2 <- roi2_MRS_noout %>% filter(roi2_MRS_noout$PosErr_deg<5)
roi2_bold_beh_2<- lm(data=roi2_MRS_noout_2, PosErr_deg~beta)
summary(roi2_bold_beh_2)

#### ROI 3 - MFG/BA9 ####
roi3 <- mgs_bold_glu %>% filter(roi=='roi3')
roi3_bold_glu<- lm(data=roi3, beta~Glu.Cre)
summary(roi3_bold_glu)
ggplot(roi3, aes(x=Glu.Cre, y=beta)) + geom_point() + stat_smooth(method='lm')

roi3_MRS_noout <- roi3 %>% filter(beta < (mean(roi3$beta) + 3*sd(roi3$beta))
                                      & beta > (mean(roi3$beta) - 3*sd(roi3$beta)))
roi3_bold_glu_noout<- lm(data=roi3_MRS_noout, beta~log(Glu.Cre)*age)
summary(roi3_bold_glu_noout)
ggplot(roi3_MRS_noout, aes(x=log(Glu.Cre), y=beta)) + geom_point() + stat_smooth(method='lm')

roi3_bold_beh<- lm(data=roi3_MRS_noout, PosErr_deg~beta)
summary(roi3_bold_beh)
ggplot(roi3_MRS_noout, aes(x=beta, y=PosErr_deg)) + geom_point() + stat_smooth(method='lm')
roi3_MRS_noout_2 <- roi3_MRS_noout %>% filter(roi3_MRS_noout$PosErr_deg<5)
roi3_bold_beh_2<- lm(data=roi3_MRS_noout_2, PosErr_deg~beta)
summary(roi3_bold_beh_2)

#### ROI 4 - SFG ####
roi4 <- mgs_bold_glu %>% filter(roi=='roi4')
roi4_bold_glu<- lm(data=roi4, beta~Glu.Cre)
summary(roi4_bold_glu)
ggplot(roi4, aes(x=Glu.Cre, y=beta)) + geom_point() + stat_smooth(method='lm')

roi4_MRS_noout <- roi4 %>% filter(beta < (mean(roi4$beta) + 3*sd(roi4$beta))
                                      & beta > (mean(roi4$beta) - 3*sd(roi4$beta)))
roi4_bold_glu_noout<- lm(data=roi4_MRS_noout, beta~log(Glu.Cre)*age)
summary(roi4_bold_glu_noout)
ggplot(roi4_MRS_noout, aes(x=Glu.Cre, y=beta)) + geom_point() + stat_smooth(method='lm')

#### ROI 5 - ACC ####
roi5 <- mgs_bold_glu %>% filter(roi=='roi5')
roi5_bold_glu<- lm(data=roi5, beta~Glu.Cre)
summary(roi5_bold_glu)
ggplot(roi5, aes(x=Glu.Cre, y=beta)) + geom_point() + stat_smooth(method='lm')

roi5_MRS_noout <- roi5 %>% filter(beta < (mean(roi5$beta) + 3*sd(roi5$beta))
                                      & beta > (mean(roi5$beta) - 3*sd(roi5$beta)))
roi5_bold_glu_noout<- lm(data=roi5_MRS_noout, beta~log(Glu.Cre)*age)
summary(roi5_bold_glu_noout)
ggplot(roi5_MRS_noout, aes(x=Glu.Cre, y=beta)) + geom_point() + stat_smooth(method='lm')

#### ROI 6 - BA6 ####
roi6 <- delay_mgsbold %>% filter(roi=='roi6')
roi6_MRS <- merge(roi6, sep_rdlpfc_glu, by.x='subj', by.y='LunaID')
roi6_bold_glu<- lm(data=roi6_MRS, beta~Glu.Cre*age)
summary(roi6_bold_glu)
ggplot(roi6_MRS, aes(x=Glu.Cre, y=beta)) + geom_point() + stat_smooth(method='lm')

roi6_MRS_noout <- roi6_MRS %>% filter(beta < (mean(roi6_MRS$beta) + 3*sd(roi6_MRS$beta))
                                      & beta > (mean(roi6_MRS$beta) - 3*sd(roi6_MRS$beta)))
roi6_bold_glu_noout<- lm(data=roi6_MRS_noout, beta~Glu.Cre*age)
summary(roi6_bold_glu_noout)
ggplot(roi6_MRS_noout, aes(x=Glu.Cre, y=beta)) + geom_point() + stat_smooth(method='lm')

#### ROI 7 - MFG/BA6 ####
roi7 <- mgs_bold_glu %>% filter(roi=='roi7')
roi7_bold_glu<- lm(data=roi7, beta~log(Glu.Cre))
summary(roi7_bold_glu)
ggplot(roi7, aes(x=Glu.Cre, y=beta)) + geom_point() + stat_smooth(method='lm')

roi7_MRS_noout <- roi7 %>% filter(beta < (mean(roi7$beta) + 3*sd(roi7$beta))
                                      & beta > (mean(roi7$beta) - 3*sd(roi7$beta)))
roi7_bold_glu_noout<- lm(data=roi7_MRS_noout, beta~log(Glu.Cre)*age)
summary(roi7_bold_glu_noout)
ggplot(roi7_MRS_noout, aes(x=Glu.Cre, y=beta)) + geom_point() + stat_smooth(method='lm')

roi7_bold_beh<- lm(data=roi7_MRS_noout, PosErr_deg~beta)
summary(roi7_bold_beh)
ggplot(roi7_MRS_noout, aes(x=beta, y=PosErr_deg)) + geom_point() + stat_smooth(method='lm')
roi7_MRS_noout_2 <- roi7_MRS_noout %>% filter(roi7_MRS_noout$PosErr_deg<5)
roi7_bold_beh_2<- lm(data=roi7_MRS_noout_2, PosErr_deg~beta)
summary(roi7_bold_beh_2)
ggplot(roi7_MRS_noout_2, aes(x=beta, y=PosErr_deg)) + geom_point() + stat_smooth(method='lm')

#### ROI 8 - ACC ####
roi8 <- mgs_bold_glu %>% filter(roi=='roi8')
roi8_bold_glu<- lm(data=roi8, beta~Glu.Cre*age)
summary(roi8_bold_glu)
ggplot(roi8, aes(x=Glu.Cre, y=beta)) + geom_point() + stat_smooth(method='lm')

roi8_MRS_noout <- roi8 %>% filter(beta < (mean(roi8$beta) + 3*sd(roi8$beta))
                                      & beta > (mean(roi8$beta) - 3*sd(roi8$beta)))
roi8_bold_glu_noout<- lm(data=roi8_MRS_noout, beta~log(Glu.Cre)*age)
summary(roi8_bold_glu_noout)
ggplot(roi8_MRS_noout, aes(x=log(Glu.Cre), y=beta)) + geom_point() + stat_smooth(method='lm')

roi8_bold_beh<- lm(data=roi8_MRS_noout, PosErr_deg~beta)
summary(roi8_bold_beh)
ggplot(roi8_MRS_noout, aes(x=beta, y=PosErr_deg)) + geom_point() + stat_smooth(method='lm')
roi8_MRS_noout_2 <- roi8_MRS_noout %>% filter(roi8_MRS_noout$PosErr_deg<5)
roi8_bold_beh_2<- lm(data=roi8_MRS_noout_2, PosErr_deg~beta)
summary(roi8_bold_beh_2)
ggplot(roi8_MRS_noout_2, aes(x=beta, y=PosErr_deg)) + geom_point() + stat_smooth(method='lm')

#### ROI 9 - BA46 ####
roi9 <- mgs_bold_glu %>% filter(roi=='roi9')
roi9_bold_glu<- lm(data=roi9, beta~Glu.Cre)
summary(roi9_bold_glu)
ggplot(roi9, aes(x=Glu.Cre, y=beta)) + geom_point() + stat_smooth(method='lm')

roi9_MRS_noout <- roi9 %>% filter(beta < (mean(roi9$beta) + 3*sd(roi9$beta))
                                      & beta > (mean(roi9$beta) - 3*sd(roi9$beta)))
roi9_bold_glu_noout<- lm(data=roi9_MRS_noout, beta~log(Glu.Cre)*age)
summary(roi9_bold_glu_noout)
ggplot(roi9_MRS_noout, aes(x=Glu.Cre, y=beta)) + geom_point() + stat_smooth(method='lm')

roi9_bold_beh<- lm(data=roi9_MRS_noout, DispErr_deg~beta)
summary(roi9_bold_beh)
ggplot(roi9_MRS_noout, aes(x=beta, y=DispErr_deg)) + geom_point() + stat_smooth(method='lm')
roi9_MRS_noout_2 <- roi9_MRS_noout %>% filter(roi9_MRS_noout$DispErr_deg<7.5)
roi9_bold_beh_2<- lm(data=roi9_MRS_noout_2, DispErr_deg~beta)
summary(roi9_bold_beh_2)
ggplot(roi9_MRS_noout_2, aes(x=beta, y=DispErr_deg)) + geom_point() + stat_smooth(method='lm')

#### ROI 10 - BA46 ####
roi10 <- mgs_bold_glu %>% filter(roi=='roi10')
roi10_bold_glu<- lm(data=roi10, beta~Glu.Cre)
summary(roi10_bold_glu)
ggplot(roi10, aes(x=Glu.Cre, y=beta)) + geom_point() + stat_smooth(method='lm')

roi10_MRS_noout <- roi10 %>% filter(beta < (mean(roi10$beta) + 3*sd(roi10$beta))
                                      & beta > (mean(roi10$beta) - 3*sd(roi10$beta)))
roi10_bold_glu_noout<- lm(data=roi10_MRS_noout, beta~log(Glu.Cre)*age)
summary(roi10_bold_glu_noout)
ggplot(roi10_MRS_noout, aes(x=Glu.Cre, y=beta)) + geom_point() + stat_smooth(method='lm')

roi10_bold_beh<- lm(data=roi10_MRS_noout, DispErr_deg~beta)
summary(roi10_bold_beh)
ggplot(roi10_MRS_noout, aes(x=beta, y=DispErr_deg)) + geom_point() + stat_smooth(method='lm')
roi10_MRS_noout_2 <- roi10_MRS_noout %>% filter(roi10_MRS_noout$DispErr_deg<7.5)
roi10_bold_beh_2<- lm(data=roi10_MRS_noout_2, DispErr_deg~beta)
summary(roi10_bold_beh_2)
ggplot(roi10_MRS_noout_2, aes(x=beta, y=DispErr_deg)) + geom_point() + stat_smooth(method='lm')

#### ROI 11 DLPFC ####
roi11 <- mgs_bold_glu %>% filter(roi=='roi11')
roi11 <- roi11[-c(2,8),]
roi11$invage <- (roi11$age)^-1
roi11_bold_age<- lm(data=roi11, beta~age*Glu.Cre)
summary(roi11_bold_age)
ggplot(roi11, aes(x=age, y=beta)) + geom_point() + stat_smooth(method='lm')

roi11_MRS_noout <- roi11 %>% filter(beta < (mean(roi11$beta) + 3*sd(roi11$beta))
                                        & beta > (mean(roi11$beta) - 3*sd(roi11$beta)))
roi11_bold_glu_noout<- lm(data=roi11_MRS_noout, beta~age*Glu.Cre+sex)
summary(roi11_bold_glu_noout)
ggplot(roi11_MRS_noout, aes(x=Glu.Cre, y=beta)) + geom_point() + stat_smooth(method='lm')

#### ROI 12 ####
roi12 <- mgs_bold_glu %>% filter(roi=='roi12')
roi12 <- roi11[-c(2,8),]
roi12$invage <- (roi12$age)^-1
roi12_bold_age<- lm(data=roi12, beta~age*Glu.Cre)
summary(roi12_bold_age)
ggplot(roi12, aes(x=Glu.Cre, y=beta)) + geom_point() + stat_smooth(method='lm')

#### ROI 13 ####
roi13 <- mgs_bold_glu %>% filter(roi=='roi13')
roi13 <- roi13[-c(2,8),]
roi13$invage <- (roi13$age)^-1
roi13_bold_age<- lm(data=roi13, beta~age*Glu.Cre)
summary(roi13_bold_age)

### ROI 14 ####
roi14 <- mgs_bold_glu %>% filter(roi=='roi14')
roi14 <- roi14[-c(2,8),]
roi14_bold_age<- lm(data=roi14, beta~age*Glu.Cre)
summary(roi14_bold_age)

#### ROI 15 -- ACC ####
roi15 <- mgs_bold_glu %>% filter(roi=='roi15')
roi15 <- roi15[-c(2,8),]
roi15_bold_age<- lm(data=roi15, beta~Glu.Cre*age)
summary(roi15_bold_age)
ggplot(roi15, aes(x=Glu.Cre, y=beta, color= age)) + geom_point() + stat_smooth(method='lm')
roi15_MRS_noout <- roi15 %>% filter(beta < (mean(roi15$beta) + 3*sd(roi15$beta))
                                    & beta > (mean(roi15$beta) - 3*sd(roi15$beta)))
ggplot(roi15_MRS_noout , aes(x=log(Glu.Cre), y=beta, color= age)) + geom_point() + stat_smooth(method='lm')
roi15_bold_age<- lm(data=roi15_MRS_noout, beta~log(Glu.Cre)*age)
summary(roi15_bold_age)

#### ROI 16 ####
roi16 <- mgs_bold_glu %>% filter(roi=='roi16')
roi16 <- roi16[-c(2,8),]
roi16_bold_age<- lm(data=roi16, beta~Glu.Cre*age)
summary(roi16_bold_age)
ggplot(roi16, aes(x=Glu.Cre, y=beta, color= age)) + geom_point() + stat_smooth(method='lm')
roi16_MRS_noout <- roi16 %>% filter(beta < (mean(roi16$beta) + 3*sd(roi16$beta))
                                    & beta > (mean(roi16$beta) - 3*sd(roi16$beta)))
ggplot(roi16_MRS_noout , aes(x=log(Glu.Cre), y=beta, color= age)) + geom_point() + stat_smooth(method='lm')
roi16_bold_age<- lm(data=roi16_MRS_noout, beta~log(Glu.Cre)*age)
summary(roi16_bold_age)

#### ROI 17 ####
roi17 <- mgs_bold_glu %>% filter(roi=='roi17')
roi17 <- roi17[-c(2,8),]
roi17_bold_age<- lm(data=roi17, beta~Glu.Cre*age)
summary(roi17_bold_age)
ggplot(roi17, aes(x=Glu.Cre, y=beta, color= age)) + geom_point() + stat_smooth(method='lm')
roi17_MRS_noout <- roi17 %>% filter(beta < (mean(roi17$beta) + 3*sd(roi17$beta))
                                    & beta > (mean(roi17$beta) - 3*sd(roi17$beta)))
ggplot(roi17_MRS_noout , aes(x=log(Glu.Cre), y=beta, color= age)) + geom_point() + stat_smooth(method='lm')
roi17_bold_age<- lm(data=roi17_MRS_noout, beta~log(Glu.Cre)*age)
summary(roi17_bold_age)

#### ROI 18 ####
roi18 <- mgs_bold_glu %>% filter(roi=='roi18')
roi18 <- roi18[-c(2,8),]
roi18_bold_age<- lm(data=roi18, beta~Glu.Cre*age)
summary(roi18_bold_age)
ggplot(roi18, aes(x=Glu.Cre, y=beta, color= age)) + geom_point() + stat_smooth(method='lm')
roi18_MRS_noout <- roi18 %>% filter(beta < (mean(roi18$beta) + 3*sd(roi18$beta))
                                    & beta > (mean(roi18$beta) - 3*sd(roi18$beta)))
ggplot(roi18_MRS_noout , aes(x=log(Glu.Cre), y=beta, color= age)) + geom_point() + stat_smooth(method='lm')
roi18_bold_age<- lm(data=roi18_MRS_noout, beta~log(Glu.Cre)*age)
summary(roi18_bold_age)

#### ROI 19 ####
roi19 <- mgs_bold_glu %>% filter(roi=='roi19')
roi19 <- roi19[-c(2,8),]
roi19_bold_age<- lm(data=roi19, beta~Glu.Cre*age)
summary(roi19_bold_age)
ggplot(roi19, aes(x=Glu.Cre, y=beta, color= age)) + geom_point() + stat_smooth(method='lm')
roi19_MRS_noout <- roi19 %>% filter(beta < (mean(roi19$beta) + 3*sd(roi19$beta))
                                    & beta > (mean(roi19$beta) - 3*sd(roi19$beta)))
ggplot(roi19_MRS_noout , aes(x=log(Glu.Cre), y=beta, color= age)) + geom_point() + stat_smooth(method='lm')
roi19_bold_age<- lm(data=roi19_MRS_noout, beta~log(Glu.Cre)*age)
summary(roi19_bold_age)

#### ROI 20 ####
roi20 <- mgs_bold_glu %>% filter(roi=='roi20')
roi20 <- roi20[-c(2,8),]
roi20_bold_age<- lm(data=roi20, beta~Glu.Cre*age)
summary(roi20_bold_age)
ggplot(roi20, aes(x=Glu.Cre, y=beta, color= age)) + geom_point() + stat_smooth(method='lm')
roi20_MRS_noout <- roi20 %>% filter(beta < (mean(roi20$beta) + 3*sd(roi20$beta))
                                    & beta > (mean(roi20$beta) - 3*sd(roi20$beta)))
ggplot(roi20_MRS_noout , aes(x=log(Glu.Cre), y=beta, color= age)) + geom_point() + stat_smooth(method='lm')
roi20_bold_age<- lm(data=roi20_MRS_noout, beta~log(Glu.Cre)*age)
summary(roi20_bold_age)

#### ROI 21 ####
roi21 <- mgs_bold_glu %>% filter(roi=='roi21')
roi21 <- roi21[-c(2,8),]
roi21_bold_age<- lm(data=roi21, beta~Glu.Cre*age)
summary(roi21_bold_age)
ggplot(roi21, aes(x=Glu.Cre, y=beta, color= age)) + geom_point() + stat_smooth(method='lm')
roi21_MRS_noout <- roi21 %>% filter(beta < (mean(roi21$beta) + 3*sd(roi21$beta))
                                    & beta > (mean(roi21$beta) - 3*sd(roi21$beta)))
ggplot(roi21_MRS_noout , aes(x=log(Glu.Cre), y=beta, color= age)) + geom_point() + stat_smooth(method='lm')
roi21_bold_age<- lm(data=roi21_MRS_noout, beta~log(Glu.Cre)*age)
summary(roi21_bold_age)

#### Anterior Insula ####
#### Right Anterior Insula ####
rantins_glu <- glu %>% filter(roi_num==3)
rantins_GABA <- GABA %>% filter(roi_num==3)
rantins_gluGABA <- gluGABA %>% filter(roi_num==3)
rantins_gluGABA$ratio <- rantins_gluGABA$Glu.Cre/rantins_gluGABA$GABA.Cre
rantins_glu <- rantins_glu[rantins_glu$Glu.Cre <20 & rantins_glu$Glu.Cre > 0,]
rantins_glu_noout <- rantins_glu %>% filter(Glu.Cre < (mean(rantins_glu$Glu.Cre) + 3*sd(rantins_glu$Glu.Cre))
                                            & Glu.Cre > (mean(rantins_glu$Glu.Cre) - 3*sd(rantins_glu$Glu.Cre)))
rantins_gaba_noout <- rantins_GABA %>% filter(GABA.Cre < (mean(rantins_GABA$GABA.Cre) + 3*sd(rantins_GABA$GABA.Cre))
                                              & GABA.Cre > (mean(rantins_GABA$GABA.Cre) - 3*sd(rantins_GABA$GABA.Cre)))
rantins_glugaba_noout <- rantins_gluGABA %>% filter(ratio < (mean(rantins_gluGABA$ratio) + 3*sd(rantins_gluGABA$ratio))
                                                    & ratio > (mean(rantins_gluGABA$ratio) - 3*sd(rantins_gluGABA$ratio)))
lantins_glu <- glu %>% filter(roi_num==4)
lantins_GABA <- GABA %>% filter(roi_num==4)
lantins_gluGABA <- gluGABA %>% filter(roi_num==4)
lantins_gluGABA$ratio <- lantins_gluGABA$Glu.Cre/lantins_gluGABA$GABA.Cre
lantins_glu <- lantins_glu[lantins_glu$Glu.Cre <20 & lantins_glu$Glu.Cre > 0,]
lantins_glu_noout <- lantins_glu %>% filter(Glu.Cre < (mean(lantins_glu$Glu.Cre) + 3*sd(lantins_glu$Glu.Cre))
                                            & Glu.Cre > (mean(lantins_glu$Glu.Cre) - 3*sd(lantins_glu$Glu.Cre)))
lantins_gaba_noout <- lantins_GABA %>% filter(GABA.Cre < (mean(lantins_GABA$GABA.Cre) + 3*sd(lantins_GABA$GABA.Cre))
                                              & GABA.Cre > (mean(lantins_GABA$GABA.Cre) - 3*sd(lantins_GABA$GABA.Cre)))
lantins_glugaba_noout<- lantins_gluGABA %>% filter(ratio < (mean(lantins_gluGABA$ratio) + 3*sd(lantins_gluGABA$ratio))
                                                   & ratio > (mean(lantins_gluGABA$ratio) - 3*sd(lantins_gluGABA$ratio)))
rantins_glu_noout$hemisphere <- "right"
lantins_glu_noout$hemisphere <- "left"
antins_glu <- rbind(rantins_glu_noout, lantins_glu_noout)

rantins_gaba_noout$hemisphere <- "right"
lantins_gaba_noout$hemisphere <- "left"
antins_gaba <- rbind(rantins_gaba_noout, lantins_gaba_noout)

rantins_glugaba_noout$hemisphere <- "right"
lantins_glugaba_noout$hemisphere <- "left"
antins_glugaba <- rbind(rantins_glugaba_noout, lantins_glugaba_noout)


sep_antins_glu <- separate(antins_glu, c("ld8"), into=c("LunaID","vdate"),remove=TRUE)
sep_antins_gaba <- separate(antins_gaba, c("ld8"), into=c("LunaID","vdate"),remove=TRUE)
sep_antins_glugaba <- separate(antins_glugaba, c("ld8"), into=c("LunaID","vdate"),remove=TRUE)
antins_glu_mgs <- merge(sep_antins_glu, MGS, by="LunaID")
antins_gaba_mgs <- merge(sep_antins_gaba, MGS, by="LunaID")
antins_glugaba_mgs <- merge(sep_antins_glugaba, MGS, by="LunaID")
antins_glu_mgs<- antins_glu_mgs %>% filter(antins_glu_mgs$PosErr_deg<10)
antins_gaba_mgs<- antins_gaba_mgs %>% filter(antins_gaba_mgs$PosErr_deg<10)
antins_glugaba_mgs<- antins_glugaba_mgs %>% filter(antins_glugaba_mgs$PosErr_deg<10)

antins_glu_mgs <- antins_glu_mgs[-c(3,5,17,19,21,23),]
antins_gaba_mgs <- antins_gaba_mgs[-c(3,5,17,19,21,23),]
antins_glugaba_mgs <- antins_glugaba_mgs[-c(3,5,17,19,21,23),]

glu_mgs <- lm(data=antins_glugaba_mgs, PosErr_deg~ratio*age)
summary(glu_mgs)

#### ROI 22 ####
insula1 <- delay_mgsbold %>% filter(roi=='roi22')
antins1_glu_mgs_bold <- merge(antins_glu_mgs, insula1, by.x="LunaID", by.y="subj")

roi22_noout <- antins1_glu_mgs_bold %>% filter(beta < (mean(antins1_glu_mgs_bold$beta) + 3*sd(antins1_glu_mgs_bold$beta))
                                    & beta > (mean(antins1_glu_mgs_bold$beta) - 3*sd(antins1_glu_mgs_bold$beta)))


#age and bold
age_bold1 <- lm(data=antins1_glu_mgs_bold, beta~age + hemisphere)
summary(age_bold1) #not sig
ggplot(antins1_glu_mgs_bold, aes(x=age, y=beta, color=hemisphere)) + geom_point() + stat_smooth(method='lm')

#bold and glu
glu_bold1 <- lm(data=antins1_glu_mgs_bold, beta~Glu.Cre + hemisphere)
summary(glu_bold1) #not sig

#bold in insula and performance
bold_MGS1 <- lm(data=antins1_glu_mgs_bold, beta~PosErr_deg + hemisphere)
summary(bold_MGS1) #not sig
ggplot(antins1_glu_mgs_bold, aes(x=beta, y=PosErr_deg, color=hemisphere)) + geom_point() + stat_smooth(method='lm')
d <- antins1_glu_mgs_bold %>% filter(antins1_glu_mgs_bold$DispErr_deg<7.5)
bold_MGS2 <- lm(data=d, beta~DispErr_deg + hemisphere)
summary(bold_MGS2) #not sig
ggplot(d, aes(x=beta, y=DispErr_deg, color=hemisphere)) + geom_point() + stat_smooth(method='lm')

#### ROI 23 ####
insula2 <- delay_mgsbold %>% filter(roi=='roi23')

antins2_glu_mgs_bold <- merge(antins_glu_mgs, insula2, by.x="LunaID", by.y="subj")

roi22_noout <- antins2_glu_mgs_bold %>% filter(beta < (mean(antins2_glu_mgs_bold$beta) + 2*sd(antins2_glu_mgs_bold$beta))
                                               & beta > (mean(antins2_glu_mgs_bold$beta) - 2*sd(antins2_glu_mgs_bold$beta)))


#age and bold
age_bold2 <- lm(data=antins2_glu_mgs_bold, beta~age + hemisphere)
summary(age_bold2) #not sig
ggplot(antins2_glu_mgs_bold, aes(x=age, y=beta, color=hemisphere)) + geom_point() + stat_smooth(method='lm')

#bold and glu
glu_bold2 <- lm(data=antins2_glu_mgs_bold, beta~Glu.Cre + hemisphere)
summary(glu_bold2) #not sig

#bold in insula and performance
bold_MGS2 <- lm(data=antins2_glu_mgs_bold, beta~PosErr_deg + hemisphere)
summary(bold_MGS2) #not sig
ggplot(antins2_glu_mgs_bold, aes(x=beta, y=PosErr_deg, color=hemisphere)) + geom_point() + stat_smooth(method='lm')
d$invage <- (d$age)^-1
d <- antins2_glu_mgs_bold %>% filter(antins2_glu_mgs_bold$PosErr_deg<7.5)
bold_MGS2 <- lm(data=d,PosErr_deg~beta + Glu.Cre + invage + hemisphere)
summary(bold_MGS2) #not sig
ggplot(d, aes(x=beta, y=PosErr_deg, color=hemisphere)) + geom_point() + stat_smooth(method='lm')

#### bold and behavior #### 
roi11_bold_beh<- lm(data=roi11_MRS_noout, DispErr_deg~beta)
summary(roi11_bold_beh)
ggplot(roi11_MRS_noout, aes(x=beta, y=DispErr_deg)) + geom_point() + stat_smooth(method='lm')
roi11_bold_beh_3<- lm(data=roi11_MRS_noout_3, DispErr_deg~beta)
summary(roi11_bold_beh_3)
ggplot(roi11_MRS_noout_3, aes(x=beta, y=DispErr_deg)) + geom_point() + stat_smooth(method='lm')



roi11_MRS_noout_2 <- roi11_MRS_noout %>% filter(roi11_MRS_noout$DispErr_deg<7.5)
roi11_bold_beh_2<- lm(data=roi11_MRS_noout_2, DispErr_deg~beta)
summary(roi11_bold_beh_2)
ggplot(roi11_MRS_noout_2, aes(x=beta, y=DispErr_deg)) + geom_point() + stat_smooth(method='lm')
