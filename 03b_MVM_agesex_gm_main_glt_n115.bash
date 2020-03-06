#!/bin/bash

rm 03b_MVM_agesex_gm_main_glt_n115.nii.gz

3dMVM	-prefix 03b_MVM_agesex_gm_main_glt_n115.nii -jobs 25	\
-bsVars "age+sex"	\
-wsVars "condition"	\
-qVars "age"	\
-mask mni_icbm152_gm_tal_nlin_asym_09c_2mm_mask.nii.gz	\
-num_glt 6	\
-gltLabel 1 cue_main_effect -gltCode 1 'condition : 1*cue'	\
-gltLabel 2 delay_main_effect -gltCode 2 'condition : 1*delay'	\
-gltLabel 3 resp_main_effect -gltCode 3 'condition : 1*resp'	\
-gltLabel 4 cue_age_effect -gltCode 4 'condition : 1*cue age :'	\
-gltLabel 5 delay_age_effect -gltCode 5 'condition : 1*delay age :'	\
-gltLabel 6 resp_age_effect -gltCode 6 'condition : 1*resp age :'	\
-dataTable	@mvm_table.txt
