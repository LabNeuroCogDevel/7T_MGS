#!/bin/bash

rm 03f_MVM_cue_rdlpfc_glu_n115.nii.gz

3dMVM	-prefix 03f_MVM_cue_rdlpfc_glu_n115.nii -jobs 25	\
-bsVars "age*Glu.Cre+sex"	\	\
-qVars "age,Glu.Cre"	\
-mask mni_icbm152_gm_tal_nlin_asym_09c_2mm_mask.nii.gz	\
-num_glt 8	\
-gltLabel 1 age_effect -gltCode 1 'age :'	\
-gltLabel 2 sex_effect_F -gltCode 2 'sex : 1*F'	\
-gltLabel 3 sex_effect_M -gltCode 3 'sex : 1*M'	\
-gltLabel 4 rdlpfc_glu_effect -gltCode 4 'Glu.Cre :'	\
-gltLabel 5 age_effect_F -gltCode 5 'sex : 1*F age:'	\
-gltLabel 6 age_effect_M -gltCode 6 'sex : 1*M age:'	\
-gltLabel 7 rdlpfc_glu_effect_F -gltCode 7 'sex : 1*F Glu.Cre :'	\
-gltLabel 8 rdlpfc_glu_effect_M -gltCode 8 'sex : 1*M Glu.Cre :'	\
-dataTable	@rdlpfc_glu_cue_mvm_table.txt
