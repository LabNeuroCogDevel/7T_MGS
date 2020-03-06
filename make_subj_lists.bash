#!/bin/bash

# list of all subjects with deconvolved data

mv /Volumes/Zeus/Orma/7T_MGS/data/subjects.txt /Volumes/Zeus/Orma/7T_MGS/data/OLD
ls -d /Volumes/Zeus/Orma/7T_MGS/data/1*/ | cut -d "/" -f 7 > subjects.txt

# list of all subjects with timing data, and visit date

mv /Volumes/Zeus/Orma/7T_MGS/data/subj_date.txt /Volumes/Zeus/Orma/7T_MGS/data/OLD
ls -d /Volumes/Zeus/preproc/7TBrainMech_mgsencmem/MHTask_nost/* | cut -d "/" -f 7 > subj_date.txt
