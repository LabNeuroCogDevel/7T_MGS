#!/bin/bash

rm 03a_MVM_agesex_gm_cond_glt_n115.nii.gz

3dMVM	-prefix 03a_MVM_agesex_gm_cond_glt_n115.nii -jobs 25	\
-bsVars "age+sex"	\
-wsVars "condition"	\
-qVars "age"	\
-mask mni_icbm152_gm_tal_nlin_asym_09c_2mm_mask.nii.gz	\
-num_glt 3	\
-gltLabel 1 cue_age_effect -gltCode 1 'condition : 1*cue age :'	\
-gltLabel 2 delay_age_effect -gltCode 2 'condition : 1*delay age :'	\
-gltLabel 3 resp_age_effect -gltCode 3 'condition : 1*resp age :'	\
-dataTable	@mvm_table.txt
