#!/usr/bin/env Rscript

# clean and model MR beta data
# initial from resp model rois
# outputs txt/MR_beta_clean_resp.csv

#
# 20200814WF - init split

# libraries
library(dplyr)
library(ggplot2)
library(tidyr)
theme_set(cowplot::theme_cowplot())
source('model/funcs.R') # mk_models

####
## settings
####
z_thres <- 2
MDL_FML <- list(lin=beta~age+gender,
                inv=beta~invage+gender,
                quad=beta~age2+age+gender)


#####
## read in data
####

# get data, merge with age, make invage and age2
setwd('/Volumes/Zeus/Orma/7T_MGS/scripts')
d <- read.csv('../group_contrasts/resp_beta_clust_spheres_08042020.txt') %>%
   merge(read.table('scan_IDs_ages.txt', header=T), by="subj", all.x=T) %>%
   mutate(invage=1/age, age2=age**2)

# remove outliers
beta_clean <- d %>%
   group_by(roi) %>%
   mutate(zscore=scale(beta, center=T, scale=T)) %>%
   filter(zscore <= z_thres) %>% ungroup
write.csv(beta_clean, 'txt/MR_beta_clean_resp.csv')


####
## Do stuff!
####
# - split into dataframes where all rows have the same roi
# - run mk_models
# - use MDL_FML as the model formulas

mr_models <- lapply(split(d,d$roi), mk_models, MDL_FML) 

# now we have a list (ea. roi) of lists (ea. formula) containing a bunch of models
# use 'best_model()' and names of MDL_FML to get which of the models for each roi in MDL_FM (lin,inv,quad) has the best AIC
mr_best <- sapply(mr_models, best_model, MDL_FML)

# get p vals.
# use the index/name from mr_best to pull out the summary for the best model.
# N.B. the models formuals are all written so the coef of interest (age,inv,quad) is always #2 in summary$coef matrix
pvals <- mapply(function(m,i) summary(m[[i]])$coef[2,'Pr(>|t|)'], mr_models, mr_best)
# see
#  roi1_models <- mr_models[[1]] # pull out first model (roi 1)
#  roi1_lin <- summary(roi1_models$lin) # summary of roi1's lin model
#  print(roi1_lin$coef)
#  print(roi1_lin$coef[2,'Pr(>|t|)'])

# make into a dataframe
mr_best_fit_and_p <- data.frame(roi=names(pvals), best=mr_best, p=pvals)

# plot just the best ones
mr_sig_plt <-
    mr_best_fit_and_p %>%
    filter(p<=.01) %>%
    inner_join(d, by="roi") %>%
    plotme(.) +
    facet_wrap(.~roi)

print(mr_sig_plt)
