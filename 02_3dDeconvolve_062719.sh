#!/usr/bin/env bash
set -euo pipefail
# USAGE:
#  ./02_3dDeconvolve_062719.sh
#  DRYRUN=1 ./02_3dDeconvolve_062719.sh
#
#Name: 02_3dDeconvolve_062719.sh
#Author:Maria and Julia
#Date: 4/19/19
#Purpose: use 3dDeconvolve to model timecourses from saccade tasks
#
# 20200306WF - updated to use lunaid_date instead of just lunaid in subjlist

# use DRYRUN to echo deconvolve instead of actually running
# will still mess with regressor and 1D files
env |grep -q "^DRYRUN=" && DRYRUN=echo || DYRUN=""

workdir=/Volumes/Zeus/Orma/7T_MGS/data
datadir=/Volumes/Zeus/preproc/7TBrainMech_mgsencmem/MHTask_nost
subjlist="$workdir/subjects_03062020.txt"
[ ! -r $subjlist ] && echo "DNE: $subjlist" && exit 1
for s in `cat $subjlist`; do
   ld8=$(basename $s)
   # skip if doesn't exist
   if test -e $workdir/$ld8/${ld8}_bucket+tlrc.HEAD; then
      echo "# already have $_"
      continue
   fi
   runs=($datadir/${ld8}/0[0-9]/nfswdkm_func_4.nii.gz)
   regs=($datadir/${ld8}/0[0-9]/nuisance_regressors.txt)
   nruns=${#runs[@]}
   # TODO: don't have to stop if less than 3 runs. could continue. first pass: only take full
   [ $nruns -lt 3 ] && echo "ERR: $ld8 has $nruns != 4 runs [TODO: allow continue] (${runs[@]})" && continue
   [ $nruns != ${#regs[@]} ] && echo "ERR: $ld8 has $nruns and ${#regs[@]} reg files (${regs[@]})" && continue

   # write all regs to one place
   cat ${regs[@]} > $workdir/$ld8/${ld8}_nuisance_regressors.txt

   # check 1D files
   for tfile in $workdir/$s/${ld8}_{cue,delay,resp}.1D; do
      [ ! -r $tfile ] && echo "ERR: $ld8 missing timing file $tfile" && continue 2

      # TODO: find missing runs. remove lines with sed
      #    sed -ie "$ns/.*/\*/" $s/${ld8}_delay.1D

      # check 1D count matches number of runs
      n1Druns=$(sed '/^\*$/d' $tfile |wc -l) 
      [ $n1Druns -ne $nruns ]  && echo "ERR: $ld8 $tfile has $n1Druns != $nruns runs" && continue 2
   done
   # if [ -e $workdir/$ld8/"$ld8"_nuisance_regressors.txt ]; then
   #    rm $workdir/$ld8/"$ld8"_nuisance_regressors.txt
   #    touch $workdir/$ld8/"$ld8"_nuisance_regressors.txt
   # fi
   # if [ -e $datadir/"$ld8"_*/01/nfswdkm_func_4.nii.gz ]; then
   #    run1=$datadir/"$ld8"_*/01/nfswdkm_func_4.nii.gz
   #    cat $datadir/"$ld8"_*/01/nuisance_regressors.txt >> $workdir/$ld8/"$ld8"_nuisance_regressors.txt
   # else
   #    run1=""
   #    sed -ie '1s/.*/\*/' $s/"$ld8"_cue.1D
   #    sed -ie '1s/.*/\*/' $s/"$ld8"_delay.1D
   #    sed -ie '1s/.*/\*/' $s/"$ld8"_resp.1D
   # fi
   # if [ -e $datadir/"$ld8"_*/02/nfswdkm_func_4.nii.gz ]; then
   #    run2=$datadir/"$ld8"_*/02/nfswdkm_func_4.nii.gz
   #    cat $datadir/"$ld8"_*/02/nuisance_regressors.txt >> $workdir/$ld8/"$ld8"_nuisance_regressors.txt
   # else
   #    run2=""
   #    sed -ie '2s/.*/\*/' $s/"$ld8"_cue.1D
   #    sed -ie '2s/.*/\*/' $s/"$ld8"_delay.1D
   #    sed -ie '2s/.*/\*/' $s/"$ld8"_resp.1D
   # fi
   # if [ -e $datadir/"$ld8"_*/03/nfswdkm_func_4.nii.gz ]; then
   #    run3=$datadir/"$ld8"_*/03/nfswdkm_func_4.nii.gz
   #    cat $datadir/"$ld8"_*/03/nuisance_regressors.txt >> $workdir/$ld8/"$ld8"_nuisance_regressors.txt
   # else
   #    run3=""
   #    sed -ie '3s/.*/\*/' $s/"$ld8"_cue.1D
   #    sed -ie '3s/.*/\*/' $s/"$ld8"_delay.1D
   #    sed -ie '3s/.*/\*/' $s/"$ld8"_resp.1D
   # fi
   cd $s
   $DRYRUN 3dDeconvolve \
    -input $run1 $run2 $run3 \
    -polort 3 \
    -jobs 12 \
   -local_times \
   -xjpeg "$ld8"_matrix \
   -num_stimts 19 \
    -stim_times 1 $workdir/$ld8/"$ld8"_cue.1D 'GAM' \
   -stim_label 1 cue \
    -stim_times_AM2 2 $workdir/$ld8/"$ld8"_delay.1D 'dmBLOCK' \
   -stim_label 2 delay \
    -stim_times 3 $workdir/$ld8/"$ld8"_resp.1D 'GAM' \
    -stim_label 3 resp \
    -stim_file 4 $workdir/$ld8/"$ld8"_nuisance_regressors.txt'[0]' \
    -stim_base 4 \
    -stim_label 4 motion_param_1 \
    -stim_file 5 $workdir/$ld8/"$ld8"_nuisance_regressors.txt'[1]' \
    -stim_base 5 \
    -stim_label 5 motion_param_2 \
    -stim_file 6 $workdir/$ld8/"$ld8"_nuisance_regressors.txt'[2]' \
    -stim_base 6 \
    -stim_label 6 motion_param_3 \
    -stim_file 7 $workdir/$ld8/"$ld8"_nuisance_regressors.txt'[3]' \
    -stim_base 7 \
    -stim_label 7 motion_param_4 \
    -stim_file 8 $workdir/$ld8/"$ld8"_nuisance_regressors.txt'[4]' \
    -stim_base 8 \
    -stim_label 8 motion_param_5 \
    -stim_file 9 $workdir/$ld8/"$ld8"_nuisance_regressors.txt'[5]' \
    -stim_base 9 \
    -stim_label 9 motion_param_6 \
    -stim_file 10 $workdir/$ld8/"$ld8"_nuisance_regressors.txt'[6]' \
    -stim_base 10 \
    -stim_label 10 motion_deriv_1 \
    -stim_file 11 $workdir/$ld8/"$ld8"_nuisance_regressors.txt'[7]' \
    -stim_base 11 \
    -stim_label 11 motion_deriv_2 \
    -stim_file 12 $workdir/$ld8/"$ld8"_nuisance_regressors.txt'[8]' \
    -stim_base 12 \
    -stim_label 12 motion_deriv_3 \
    -stim_file 13 $workdir/$ld8/"$ld8"_nuisance_regressors.txt'[9]' \
    -stim_base 13 \
    -stim_label 13 motion_deriv_4 \
    -stim_file 14 $workdir/$ld8/"$ld8"_nuisance_regressors.txt'[10]' \
    -stim_base 14 \
    -stim_label 14 motion_deriv_5 \
    -stim_file 15 $workdir/$ld8/"$ld8"_nuisance_regressors.txt'[11]' \
    -stim_base 15 \
    -stim_label 15 motion_deriv_6 \
    -stim_file 16 $workdir/$ld8/"$ld8"_nuisance_regressors.txt'[12]' \
    -stim_base 16 \
    -stim_label 16 csf \
    -stim_file 17 $workdir/$ld8/"$ld8"_nuisance_regressors.txt'[13]' \
    -stim_base 17 \
    -stim_label 17 csf_deriv \
    -stim_file 18 $workdir/$ld8/"$ld8"_nuisance_regressors.txt'[14]' \
    -stim_base 18 \
    -stim_label 18 wm \
    -stim_file 19 $workdir/$ld8/"$ld8"_nuisance_regressors.txt'[15]' \
    -stim_base 19 \
    -stim_label 19 wm_deriv \
    -iresp 1 cue_iresp \
    -iresp 2 resp_iresp \
    -fout \
    -rout \
    -bout \
    -fitts "$ld8"_fitts \
    -errts "$ld8"_errts \
    -bucket "$ld8"_bucket \
    -cbucket "$ld8"_cbucket \
    -GOFORIT 7
    cd $workdir
done
