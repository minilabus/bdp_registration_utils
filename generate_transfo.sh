# Internal use only

# The pre-generated transformation are available at: https://zenodo.org/records/11192915
for i in 02 10 17 19; do antsRegistrationSyN.sh -d 3 -m mni_masked_left.nii.gz -f sub-${i}/*-ACPC_brain_t1.nii.gz -o sub-${i}/to_specimen -n 4; done
for i in 01 04 16 18; do antsRegistrationSyN.sh -d 3 -m mni_masked_right.nii.gz -f sub-${i}/*-ACPC_brain_t1.nii.gz -o sub-${i}/to_specimen -n 4; done

exit 1

# Alternative (FS) Left
for i in 02 10 17 19;
	do echo ${i}
	HEMI="left"
	# Doing it reverse to apply it from MNI later
	mri_synthmorph register -m affine -t sub-${i}/init.lta -o sub-${i}/tmp.nii.gz mni_masked_${HEMI}.nii.gz sub-${i}/*-ACPC_brain_t1.nii.gz -j 8
	mri_synthmorph register -m deform -t sub-${i}/freesurfer_warp.mgz -o ${OUTPUT} sub-${i}/tmp.nii.gz sub-${i}/*-ACPC_brain_t1.nii.gz -j 8

	# Convert to ANTs
	lta_convert --inlta sub-${i}/init.lta --outitk sub-${i}/to_specimen0GenericAffine.txt
	mri_warp_convert -g sub-${i}/*-ACPC_brain_t1.nii.gz --inras sub-${i}/freesurfer_warp.mgz --outlps sub-${i}/to_specimen0Warp.nii.gz


	# Testing
	antsApplyTransforms -d 3 -i mni_masked_${HEMI}.nii.gz -r sub-${i}/*-ACPC_brain_t1.nii.gz \
	    -t sub-${i}/to_specimen0Warp.nii.gz -t sub-${i}/to_specimen0GenericAffine.txt -o sub-${i}/to_specimenWarped.nii.gz
	rm sub-${i}/init.lta sub-${i}/freesurfer_warp.mgz sub-${i}/tmp.nii.gz
done

# Alternative (FS) Right
for i in 01 04 16 18;
	do echo ${i}
	HEMI="right"
	# Doing it reverse to apply it from MNI later
	mri_synthmorph register -m affine -t sub-${i}/init.lta -o sub-${i}/tmp.nii.gz mni_masked_${HEMI}.nii.gz sub-${i}/*-ACPC_brain_t1.nii.gz -j 8
	mri_synthmorph register -m deform -t sub-${i}/freesurfer_warp.mgz -o ${OUTPUT} sub-${i}/tmp.nii.gz sub-${i}/*-ACPC_brain_t1.nii.gz -j 8

	# Convert to ANTs
	lta_convert --inlta sub-${i}/init.lta --outitk sub-${i}/to_specimen0GenericAffine.txt
	mri_warp_convert -g sub-${i}/*-ACPC_brain_t1.nii.gz --inras sub-${i}/freesurfer_warp.mgz --outlps sub-${i}/to_specimen0Warp.nii.gz


	# Testing
	antsApplyTransforms -d 3 -i mni_masked_${HEMI}.nii.gz -r sub-${i}/*-ACPC_brain_t1.nii.gz \
	    -t sub-${i}/to_specimen0Warp.nii.gz -t sub-${i}/to_specimen0GenericAffine.txt -o sub-${i}/to_specimenWarped.nii.gz
	rm sub-${i}/init.lta sub-${i}/freesurfer_warp.mgz sub-${i}/tmp.nii.gz
done

