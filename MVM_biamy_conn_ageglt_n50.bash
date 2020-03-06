#!/bin/bash

3dMVM	-prefix MVM2_seedconn_biamy_fd_age_glt_n50.nii -jobs 25	\
-bsVars "age*sex+meanfd"	\
-qVars "age,meanfd"	\
-num_glt 1	\
-gltLabel 1 age_effect -gltCode 1 'age :'	\
-dataTable	@biamy_fd_mvm_table_n50.txt


#-mask mni_icbm152_gm_tal_nlin_asym_09c_3mm_mask.nii.gz	\
