#!/usr/bin/env bash

3dUndump -prefix delay_coordinates2.nii.gz -master 03g_MVM_delay_rdlpfc_glu_n115.nii.gz -mask mni_icbm152_gm_tal_nlin_asym_09c_2mm_mask.nii.gz -xyz -orient RAI coordinates2.txt -overwrite 

maskdir=.

events=(14 17 20)
event_names=(cue delay resp)
numEv=${#events[@]}
let numEv--
forceWrite=0
subj1dDir=../group_contrasts/indiv
mkdir -p $subj1dDir



while read maskname maskfile mrangelow mrangehigh; do

	[ -z $maskname ] && continue

	for cfile in /Volumes/Zeus/Orma/7T_MGS/data/*/*_bucket+tlrc.HEAD; do
		cdir=$(dirname $cfile)
		subj=$(echo $cfile | cut -d "/" -f7)
		outfile="$subj-$maskname.1d"
		[ -r $subj1dDir/$outfile -a $forceWrite -eq 0 ] && continue
		[ -r $subj1dDir/$outfile ] && rm $subj1dDir/$outfile
		for i in $(seq 0 $numEv); do
	     		evName=${event_names[$i]}
	     		evNum=${events[$i]}
	     		

			cmd="3dmaskave -quiet -mask '${maskdir}/${maskfile}' -mrange $mrangelow $mrangehigh $cfile[${evNum}..${evNum}]"
			echo $cmd
			val=$(eval $cmd)
			echo "${maskname},${subj},${evName},${val}" >> $subj1dDir/$outfile

		done

	done

   let ++ct || echo count err

done <<EOF
roi1 delay_coordinates2.nii.gz 1 1
roi2 delay_coordinates2.nii.gz 2 2
roi3 delay_coordinates2.nii.gz 3 3
roi4 delay_coordinates2.nii.gz 4 4
roi5 delay_coordinates2.nii.gz 5 5
roi6 delay_coordinates2.nii.gz 6 6
roi7 delay_coordinates2.nii.gz 7 7
roi8 delay_coordinates2.nii.gz 8 8
roi9 delay_coordinates2.nii.gz 9 9
roi10 delay_coordinates2.nii.gz 10 10
roi11 delay_coordinates2.nii.gz 11 11
roi12 delay_coordinates2.nii.gz 12 12
roi13 delay_coordinates2.nii.gz 13 13
roi14 delay_coordinates2.nii.gz 14 14
roi15 delay_coordinates2.nii.gz 15 15
roi16 delay_coordinates2.nii.gz 16 16
roi17 delay_coordinates2.nii.gz 17 17
roi18 delay_coordinates2.nii.gz 18 18
roi19 delay_coordinates2.nii.gz 19 19
roi20 delay_coordinates2.nii.gz 20 20
roi21 delay_coordinates2.nii.gz 21 21
roi22 delay_coordinates2.nii.gz 22 22
roi23 delay_coordinates2.nii.gz 23 23
EOF

group_outfile=$(pwd)/../group_contrasts/beta_clust2.txt
echo "roi,subj,event,beta" > ${group_outfile}
cat $subj1dDir/*1d >> ${group_outfile}
