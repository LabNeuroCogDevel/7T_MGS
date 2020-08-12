#!/usr/bin/env Rscript

#
#

# 20200806WF - init
library(dplyr)
library(ggplot2)
theme_set(cowplot::theme_cowplot())


####
## settings
####
z_thres <- 2
MDL_FML <- list(lin=beta~age+gender,
                inv=beta~invage+gender,
                quad=beta~age2+age+gender)

####
## quick functions for messing with models
####

# given a (slice of a) dataframe, run lm with each of the named formulas in M (likely, MDL_FML)
mk_models <- function(d, M) lapply(M, function(f) lm(f,d))
# given a list of models with names() matching M, pull out the name of best AIC
best_model <- function(models, M)  names(M)[which.min(sapply(models, AIC))]
# quick plot
plotme <- function(d) ggplot(d) + aes(x=age, y=beta) + geom_point(aes(color=gender)) + geom_smooth()

#####
## read in data
####

# get data, merge with age, make invage and age2
d <- read.csv('../group_contrasts/resp_beta_clust_spheres_08042020.txt') %>%
   merge(read.table('scan_IDs_ages.txt', header=T), by="subj", all.x=T) %>%
   mutate(invage=1/age, age2=age**2)

# remove outliers
beta_clean <- d %>%
   group_by(roi) %>%
   mutate(zscore=scale(beta, center=T, scale=T)) %>%
   filter(zscore <= z_thres) %>% ungroup



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
mr_sig_plt <- mr_best_fit_and_p %>% filter(p<=.01) %>% inner_join(d, by="roi") %>% plotme(.) + facet_wrap(.~roi)
print(mr_sig_plt)

#####
## again for MRSI
####
library(tidyr)
si_zthres <- 3
source('/Volumes/Hera/Projects/7TBrainMech/scripts/mri/MRSI_roi/mrsi_r/R/mrsi_fitdf.R')
## reshape data to be more amenable to modeling
#  row per ld8+si_roi+metabolite. value is "mrsi"
#   additional "fd" (per ld8), "GM" (per ld8+roi), and "SD"(per row) values
# names(si_clean) 
#  "ld8" "si_roi" "si_label" "metabolite" "mrsi"
#  "SD" "fd_mean" "fd_sd" "fd_max" "fd_maxdiff"  
#  "fd_ratgt_0.5" "gm.atlas"  "GMrat"  "GMcnt"       
#  
# N.B. Cr.Cr is useless, messes up reshaping
#      there are some rows with fd but without mrsi (label is NULL)
si_wide <- read.csv('/Volumes/Hera/Projects/7TBrainMech/scripts/mri/MRSI_roi/txt/13MP20200207_LCMv2fixidx.csv') %>% filter(!is.na(label))
fd <- si_wide %>% select(ld8,matches("fd")) %>% unique
gm <- si_wide %>% select(ld8, si_label=label, matches("GM"))
si_long <- si_wide %>%
    select(matches("ld8|roi|label|Cr|SD"))  %>%
    gather(m,v,-matches("ld8|roi|label")) %>% unique
si_mtbl <- si_long %>% 
    filter(grepl("SD|Cr", m), m!='Cr.Cr', m!='X.CrCH2') %>%
    mutate(metabolite=gsub(".(SD|Cr)$", "", m),
           m=gsub(".*.(SD|Cr)$","\\1", m)) %>%
    spread(m,v) %>%
    rename(si_roi=roi, si_label=label, mrsi=Cr)

si_all <-si_mtbl %>% inner_join(fd) %>% inner_join(gm)

# clean up. TODO - match mrsi_clean
si_clean <- si_all %>%
    group_by(si_label, metabolite) %>% # for each roi/metabolite pair
    filter(SD < 20,
           scale(mrsi, center=T, scale=T) <= si_zthres,
           !is.na(GMrat))



# every mr_roi to every si voxel
beta_si <- merge(beta_clean, si_clean, by.x="subj",by.y="ld8") # 508,116 rows

# TODO: pull in mrsi data
 MDL_FML_ALL <- list(lin=beta~age*mrsi+gender,
                     inv=beta~invage*mrsi+gender,
                     quad=beta~age2*mrsi+age*mrsi+gender) # 2 interactions is too many?

### EXAMPLE on just Glu for mr roi 1  and si_roi 1
# try on just one
si_model_Glu1 <- beta_si %>%
    filter(roi==1, si_roi==1, metabolite=="Glu") %>%
    mk_models(MDL_FML_ALL)
# run this subset through all our models
Glu1Best <- best_model(si_model_Glu1, MDL_FML_ALL)
# find the best one
si_model_Glu1[Glu1Best]

## GIANT MODEL LIST
#  a model for each mr_roi, si_roi, and metabolite pairing
beta_si_models <- beta_si %>%
    split(paste(.$roi, .$si_label, .$metabolite)) %>%
    # remove combinations with too few rows (less than 10)
    Filter(function(x) nrow(x) > 10, .) %>%
    lapply(mk_models, MDL_FML_ALL) 
si_best <- sapply(beta_si_models, best_model, MDL_FML_ALL)
# # TODO: check coef matrix
   expl1_models <- beta_si_models[[1]]
   lapply(expl1_models, summary)
   expl1_i     <- si_best[[1]]
   summary(expl1_models[[expl1_i]])
# TODO: is idx=2 always the correct p-value in summary coeff matrix
  si_pval <- mapply(function(m,i) summary(m[[i]])$coef[2,'Pr(>|t|)'], beta_si_models, si_best)

