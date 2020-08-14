#!/usr/bin/Rscript

# 20200814WF
# clean and reshape LCMv2 spreadsheet
# save to 'txt/MRSI_clean_long.csv'

# settings
si_zthres <- 3

library(dplyr)
library(ggplot2)
library(tidyr)
setwd('/Volumes/Zeus/Orma/7T_MGS/scripts')
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

write.csv(si_clean, 'txt/MRSI_clean_long.csv')
