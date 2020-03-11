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
env |grep -q "^DRYRUN=" && DRYRUN=echo || DRYRUN=""

fd_thres=0.5 # censor file creation. what is upper limit for FD motion
dpfix=cenfd${fd_thres} # where to save bucket file output
workdir=/Volumes/Zeus/Orma/7T_MGS/data
datadir=/Volumes/Zeus/preproc/7TBrainMech_mgsencmem/MHTask_nost
subjlist="$workdir/subjects_03062020.txt"
[ ! -r $subjlist ] && echo "DNE: $subjlist" && exit 1
for s in `cat $subjlist`; do
   ld8=$(basename $s)
   test ! -d $workdir/$s  && echo "ERR: no dir $_" && continue

   # skip if doesn't exist
   if test -e $workdir/$ld8/$dpfix/${ld8}_bucket+tlrc.HEAD; then
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
   nuisancefile=$workdir/$ld8/${ld8}_nuisance_regressors.txt
   cat ${regs[@]} > $nuisancefile

   # create censor file
   censorfile=$workdir/$ld8/censor_fd$fd_thres.1d
   fds=($datadir/${ld8}/0[0-9]/motion_info/fd.txt)
   [ $nruns != ${#fds[@]} ] && echo "ERR: $ld8 has $nruns and ${#fds[@]} fd motion files (${fds[@]})" && continue
   perl -lspe '$_=($_>$thres)?0:1' -- -thres=$fd_thres ${fds[@]} > $censorfile

   # check created nuisance and censor file
   [ $(wc -l < $censorfile) -ne $(wc -l < $nuisancefile) ] && echo "ERR: $ld8: 'wc -l $censorfile $nuisancefile' do not match!" && continue

   # check 1D files
   for tfile in $workdir/$s/${ld8}_{cue,delay,resp}.1D; do
      [ ! -r $tfile ] && echo "ERR: $ld8 missing timing file $tfile" && continue 2

      # TODO: find missing runs. remove lines with sed
      #    sed -ie "$ns/.*/\*/" $s/${ld8}_delay.1D

      # check 1D count matches number of runs
      n1Druns=$(sed '/^\*$/d' $tfile |wc -l) 
      [ $n1Druns -ne $nruns ]  && echo "ERR: $ld8 $tfile has $n1Druns != $nruns runs" && continue 2
   done
   
   cd $workdir/$s
   test ! -d  $dpfix && mkdir $_
   $DRYRUN 3dDeconvolve \
    -input ${runs[@]}\
    -censor $censorfile\
    -polort 3 \
    -jobs 12 \
    -local_times \
    -xjpeg $dpfix/${ld8}_matrix \
    -num_stimts 19 \
    -stim_times     1 ${ld8}_cue.1D   'GAM'      -stim_label 1 cue \
    -stim_times_AM2 2 ${ld8}_delay.1D 'dmBLOCK'  -stim_label 2 delay \
    -stim_times     3 ${ld8}_resp.1D  'GAM'      -stim_label 3 resp \
    -stim_file 4  $nuisancefile'[0]'  -stim_base 4  -stim_label 4  motion_param_1 \
    -stim_file 5  $nuisancefile'[1]'  -stim_base 5  -stim_label 5  motion_param_2 \
    -stim_file 6  $nuisancefile'[2]'  -stim_base 6  -stim_label 6  motion_param_3 \
    -stim_file 7  $nuisancefile'[3]'  -stim_base 7  -stim_label 7  motion_param_4 \
    -stim_file 8  $nuisancefile'[4]'  -stim_base 8  -stim_label 8  motion_param_5 \
    -stim_file 9  $nuisancefile'[5]'  -stim_base 9  -stim_label 9  motion_param_6 \
    -stim_file 10 $nuisancefile'[6]'  -stim_base 10 -stim_label 10 motion_deriv_1 \
    -stim_file 11 $nuisancefile'[7]'  -stim_base 11 -stim_label 11 motion_deriv_2 \
    -stim_file 12 $nuisancefile'[8]'  -stim_base 12 -stim_label 12 motion_deriv_3 \
    -stim_file 13 $nuisancefile'[9]'  -stim_base 13 -stim_label 13 motion_deriv_4 \
    -stim_file 14 $nuisancefile'[10]' -stim_base 14 -stim_label 14 motion_deriv_5 \
    -stim_file 15 $nuisancefile'[11]' -stim_base 15 -stim_label 15 motion_deriv_6 \
    -stim_file 16 $nuisancefile'[12]' -stim_base 16 -stim_label 16 csf \
    -stim_file 17 $nuisancefile'[13]' -stim_base 17 -stim_label 17 csf_deriv \
    -stim_file 18 $nuisancefile'[14]' -stim_base 18 -stim_label 18 wm \
    -stim_file 19 $nuisancefile'[15]' -stim_base 19 -stim_label 19 wm_deriv \
    -fout  -rout  -bout \
    -iresp 1 $dpfix/${ld8}_cue_iresp \
    -iresp 3 $dpfix/${ld8}_resp_iresp \
    -fitts   $dpfix/${ld8}_fitts \
    -errts   $dpfix/${ld8}_errts \
    -bucket  $dpfix/${ld8}_bucket \
    -cbucket $dpfix/${ld8}_cbucket \
    -GOFORIT 7
    # AM2 doesnt have an iresp
    cd $workdir
done
