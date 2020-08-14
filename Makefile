.PHONY: always all
all: 06302020_cue_mvm_table.txt

.make:
	@-mkdir .make

.make/mgs_preproc.ls: always | .make
	mkls $@ '/Volumes/Hera/preproc/7TBrainMech_mgsencmem/MHTask_nost/1*_2*/*/nfswdkm_func_4.nii.gz'

.make/mgs_task.ls: always | .make
	find /Volumes/L/bea_res/Data/Tasks/MGSEncMem/7T/1*_2*/ -iname '*_view.csv' | mkifdiff $@

.make/timing.ls: .make/mgs_task.ls
	./01_make_timing.R
	mkls $@ '/Volumes/Zeus/Orma/7T_MGS/data/1*_2*/1*_2*_cue.1D'

.make/decon.ls: .make/mgs_preproc.ls
	./02_3dDeconvolve_062719.sh subjlist
	mkls $@ '/Volumes/Zeus/Orma/7T_MGS/data/1*_2*/1*_2*_cbucket+tlrc.HEAD'

/Volumes/Zeus/Orma/7T_MGS/data/have_decon_2020-06-30.txt: .make/decon.ls
	./02.1_decon_subj_list.bash

06302020_cue_mvm_table.txt: /Volumes/Zeus/Orma/7T_MGS/data/have_decon_2020-06-30.txt
	./04_Make_MVM_Datatable.R

txt/MR_beta_clean_resp.csv: ../group_contrasts/resp_beta_clust_spheres_08042020.txt scan_IDs_ages.txt
	./model/MR_beta.R

txt/MRSI_clean_long.csv: /Volumes/Hera/Projects/7TBrainMech/scripts/mri/MRSI_roi/txt/13MP20200207_LCMv2fixidx.csv
	./model/mrsi_clean_long.R

txt/beta_resp_mrsi_GluGABA_sig05.pdf models/mrsi_beta_resp.Rdata: txt/MR_beta_clean_resp.csv txt/MRSI_clean_long.csv
	./beta_roi_model.R
