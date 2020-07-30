#!/usr/bin/env bash
set -euo pipefail
cd $(dirname $0) # make sure we are in the scripts directory (dir of this script)

# 20200729WF - init
#  FC: age as between subject + mask by delay clusters
#  MJ: 03_07222020_MVM_gm_main_glt.bash (base)
# write to ../group_contrasts folder

# headers: Subj	ld8	vdate	sex	dob	age	condition	InputFile
table="07212020_mvm_table.txt" # here so 'gf' in vim opens it
# this mask generated from previous 3dMVM
mask="./delay_age_0.01_20_3122020_mask+tlrc.HEAD"

3dMVM -prefix ../group_contrasts/MVM_ws-cond_bs-Age_msk-dly_20200729.nii.gz -jobs 25 \
  -dataTable @$table \
  -wsVars "condition" \
  -bsVars "age" `#between subject ` \
  -qVars "age" `# q=quantative=numeric` \
  -mask $mask \
  -num_glt 3 \
  -gltLabel 1 cue_main_effect -gltCode 1 'condition : 1*cue' \
  -gltLabel 2 delay_main_effect -gltCode 2 'condition : 1*delay' \
  -gltLabel 3 resp_main_effect -gltCode 3 'condition : 1*resp' \
  -overwrite
