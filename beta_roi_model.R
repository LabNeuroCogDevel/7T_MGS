#!/usr/bin/env Rscript

#
# model mrsi metabolite concentrations with MR task GLM betas
#
# 20200806WF - init

# libraries
suppressPackageStartupMessages({
library(dplyr)
library(ggplot2)
library(tidyr)})
theme_set(cowplot::theme_cowplot())


#####
# MR beta and MRSI metabolite concentration 
####

MDL_FML_ALL <- list(lin=beta~age*mrsi+gender,
                     inv=beta~invage*mrsi+gender,
                     quad=beta~age2*mrsi+age*mrsi+gender) # 2 interactions is too many?


# read in data
setwd('/Volumes/Zeus/Orma/7T_MGS/scripts')
source('model/funcs.R') # mk_models
beta_clean <- read.csv('txt/MR_beta_clean_resp.csv') # ./model/MR_beta.R
si_clean <- read.csv('txt/MRSI_clean_long.csv') # ./model/mrsi_clean_long.R
# every mr_roi to every si voxel
# row for every visit for every mr roi for every mrsi roi for every metabolite
# 508,116 rows
beta_si <- merge(beta_clean, si_clean, by.x="subj",by.y="ld8") %>%
    mutate(spliton=paste(roi, si_label, metabolite))

## GIANT MODEL LIST
#  a model for each mr_roi, si_roi, and metabolite pairing
cat("Generating models ...\n")
beta_si_models <- beta_si %>%
    split(.$spliton) %>%
    # remove combinations with too few rows (less than 10)
    Filter(function(x) nrow(x) > 10, .) %>%
    lapply(mk_models, MDL_FML_ALL) 
si_best <- sapply(beta_si_models, best_model, MDL_FML_ALL)

# extract the best of the 3 models we generated for each combo
best_model_per_combo <- mapply(function(this_model, which_best) this_model[[which_best]], beta_si_models, si_best, SIMPLIFY=F)
# extact pvalue of all the best models
all_pvals <- sapply(best_model_per_combo, function(m) summary(m)$coef[2,'Pr(>|t|)'])
# remove insig. and keep only combos with Glu and GABA
keep_idx <-  grepl("Glu|GABA",names(best_model_per_combo)) & all_pvals < 0.05
modelsOfInterest <- best_model_per_combo[keep_idx]

cat("Saving models...\n")
save(file="model/mrsi_beta_resp.Rdata",
     list=c("modelsOfInterest", "best_model_per_combo",
            "beta_si_models","beta_si","si_best","all_pvals","MDL_FML_ALL"))

cat("Generating pdf ...\n")
pdf("txt/beta_resp_mrsi_GluGABA_sig05.pdf")
for(mi in 1:length(modelsOfInterest)) {
  m <- modelsOfInterest[[mi]]
  what <- names(modelsOfInterest)[[mi]]
  pval <- summary(m)$coef[2,'Pr(>|t|)']
  d <- m$model

  # interp
  mrsi_grid <- seq(min(d$mrsi),max(d$mrsi), by=.01)
  refat <- list(mrsi=mrsi_grid, gender=c("M","F"))
  fitdf <- emmeans::ref_grid(m, at=refat) %>% as.data.frame
  fitdf$beta <- fitdf$prediction

  mtype <- 'lin'
  if('invage' %in% names(d)) mtype <-'inv'#fitdf$age <- 1/fitdf$invage
  if('age2' %in% names(d)) mtype <-'quad'#fitdf$age <- 1/fitdf$invage

  d$beta_fit <- m$fitted.values
  p <- ggplot(d) + aes(x=mrsi, y=beta, color=gender) +
      geom_point() +
      geom_line(data=fitdf) +
      ggtitle(paste(what, mtype, pval, sep=" "))
  print(p)
  # grid::grid.newpage() # print makes it's own new page
}
dev.off()
