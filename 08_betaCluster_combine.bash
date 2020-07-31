#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT
cd $(dirname $0)

#
# combine outputs from 07_extractBeta_{cue,delay,resp}_cluster.bash
# restrict to just what we have in the MVM table
#
#  20200731WF - extract from bottom of 07*delay scripts

MVM_table="./07212020_mvm_table.txt" # see 04_Make_MVM_Datatable.R
subj1dDir="../group_contrasts/indiv"

# make sure we have only cue, delay, or resp
usage(){ echo "USAGE: $0 <cue|delay|resp>" && exit 1;}
[ $# -ne 1 ] && usage
case $1 in
   cue|delay|resp) epoch="$1";; 
   *) echo "don't know what to do with $1; want cue delay or resp"; usage;;
esac


# second column is ld8 (cut -f2), first row is header (remove w/sed 1d)
ALLIDS=($(cut -f2 $MVM_table|sed 1d|sort -u))

group_outfile=$(pwd)/../group_contrasts/${epoch}_beta_clust_07312020_nooutliers.txt
echo "roi,subj,epoch,event,beta" > ${group_outfile}
echo "# createing $group_outfile using ${#ALLIDS[@]} ids from $MVM_table"
for ld8 in ${ALLIDS[@]}; do
   cat $subj1dDir/${ld8}*-${epoch}.1d 
done >> ${group_outfile}
echo "# have $(wc -l $group_outfile) rows"
