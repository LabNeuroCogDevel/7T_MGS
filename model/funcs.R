####
## quick functions for messing with models
####

# given a (slice of a) dataframe, run lm with each of the named formulas in M (likely, MDL_FML)
mk_models <- function(d, M) lapply(M, function(f) lm(f,d))
# given a list of models with names() matching M, pull out the name of best AIC
best_model <- function(models, M)  names(M)[which.min(sapply(models, AIC))]
# quick plot
plotme <- function(d) ggplot(d) + aes(x=age, y=beta) + geom_point(aes(color=gender)) + geom_smooth()
# quick look at p values
getpvals <- function(m) summary(m)$coef[,'Pr(>|t|)']
