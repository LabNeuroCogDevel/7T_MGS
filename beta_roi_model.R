#!/usr/bin/env Rscript

#
#

# 20200806WF - init
library(dplyr)
library(ggplot2)
theme_set(cowplot::theme_cowplot())

z_thres <- 2
MDL_FML <- list(lin=beta~age+gender,
                inv=beta~invage+gender,
                quad=beta~age2+age+gender)

# get data, merge with age, make invage and age2
d <- read.csv('../group_contrasts/resp_beta_clust_spheres_08042020.txt') %>%
   left_join(read.table('scan_IDs_ages.txt', header=T)) %>%
   mutate(invage=1/age, age2=age**2)

# remove outliers
clean <- d %>%
   group_by(roi) %>%
   mutate(zscore=scale(beta, center=T, scale=T)) %>%
   filter(zscore <= z_thres) %>% ungroup


# quick functions for messing with models
mk_models <- function(d, M) lapply(M, function(f) lm(f,d))
best_model <- function(models, M)  names(M)[which.min(sapply(models, AIC))]
plotme <- function(d) ggplot(d) + aes(x=age, y=beta) + geom_point(aes(color=gender)) + geom_smooth()
# apply functions
mr_models <- lapply(split(d,d$roi), mk_models, MDL_FML) 
mr_best <- sapply(mr_models, best_model, MDL_FML)
# get p vals.
# N.B. the models formuals are all written so the coef of interest (age,inv,quad) is always #2 in summary$coef matrix
pvals <- mapply(function(m,i) summary(m[[i]])$coef[2,'Pr(>|t|)'], mr_models, mr_best)
# make into a dataframe
mr_best_fit_and_p <- data.frame(roi=names(pvals), best=mr_best, p=p)

mr_sig_plt <- mr_best_fit_and_p %>% filter(p<=.01) %>% inner_join(d, by="roi") %>% plotme(.) + facet_wrap(.~roi)
print(mr_sig_plt)

# TODO: pull in mrsi data
# mrsi <- read.csv(...)
# si_clean <-  clean_mrsi(...)
# d_all <- merge(d, si_clean, by="subj")
# MDL_FML_ALL <- list(lin=beta~age*mrsi+gender,
#                     inv=beta~invage*mrsi+gender,
#                     quad=beta~age2*mrsi+age*mrsi+gender) # 2 interactions is too many?
# 
# si_models <- d_all %>% split(.$roi) %>% lapply(mk_models, MDL_FML) 
# si_best <- sapply(mr_models, best_model, MDL_FML)
# # TODO: check coef matrix
#   expl1_models <- si_models[[1]]
#   lapply(expl1_models, summary)
#   expl1_i     <- si_best[[1]]
#   summary(expl1_models[[expl1_i]])
# TODO: is idx=2 always the correct p-value in summary coeff matrix
#  si_pval <- mapply(function(m,i) summary(m[[i]])$coef[2,'Pr(>|t|)'], mr_models, mr_best)

