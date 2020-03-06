#!/bin/bash

3dMVM	-prefix 03_MVM_age_glt_n51.nii -jobs 25	\
-bsVars "age"	\
-wsVars "condition"	\
-qVars "age"	\
-num_glt 1	\
-gltLabel 1 age_effect -gltCode 1 'age :'	\
-dataTable	@mvm_table.txt
