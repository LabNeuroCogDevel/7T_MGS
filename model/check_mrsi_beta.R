#!/usr/bin/env Rscript
# 202008114 WF - check if anything is up with models

# pick any good/signficant model and see its P vals
mi <- 10

suppressPackageStartupMessages({require(dplyr); require(tidyr)})
cat("loading data ...\n")
# esp. model split names
if(!exists("mk_models")) source('model/funcs.R')
if(!exists("modelsOfInterest")) load("model/mrsi_beta_resp.Rdata")


## info about this pick
# what did we extract
mn <- names(modelsOfInterest)[[mi]] # "resp_roi10 L DLPFC Glu"

best_fit_name <- si_best[[mn]]
cat("looking at good model #", mi," : '", mn, "' fit best by ", best_fit_name, "\n")

parts <- as.list(stringr::str_match(mn, "(.*?) (.*) (GABA|Glu)"))
names(parts) <- c("all","mrroi","label","metabolite")
rawdata <-
    beta_si %>%
    filter(spliton==mn)

# smaller subset
testsubset <-
    beta_si %>% 
    filter(roi==parts$mrroi, si_label==parts$label, grepl("GABA|Glu", metabolite))
testsplit <- testsubset %>% split(.$spliton)
testmodels <- testsplit %>%
    lapply(mk_models, MDL_FML_ALL[best_fit_name]) 


# what model?
best_fit_name <- si_best[mn] # quad
print(best_fit_name)

# expect pvalue
pval_at_2 <- all_pvals[mn]

## see models
byall  <- beta_si_models[[mn]][[best_fit_name]]  # from list of all models per pair
bycombo <- best_model_per_combo[[mn]]            # from list of only best models per pair
byinterest <- modelsOfInterest[[mn]]             # after gaba/glu and pval subsest
byraw <- mk_models(rawdata, MDL_FML_ALL[best_fit_name])[[1]]
bysplit <- mk_models(testsplit[[mn]], MDL_FML_ALL[best_fit_name])[[1]]

cat("p:"); print(pval_at_2)
cat("raw: ");     print(getpvals(byraw))
cat("all: ");     print(getpvals(byall))
cat("split: ");   print(getpvals(bysplit))
cat("combo: ");   print(getpvals(bycombo))
cat("interset: ");print(getpvals(byinterest))

cat("rows in model data frame for byall and byraw\n")
byall$model %>% nrow %>% print # [1] 124
byraw$model %>% nrow %>% print # [1] 123

 
# input data is the same!
testsplit[[mn]] %>% select(spliton,beta,mrsi,age,age2,gender) %>% tail
rawdata %>% select(spliton,beta,mrsi,age,age2,gender) %>% tail

## test split
testpvals <- lapply(testmodels, function(x) getpvals(x[[1]]))
print(testpvals[[mn]])
getpvals(byraw)
