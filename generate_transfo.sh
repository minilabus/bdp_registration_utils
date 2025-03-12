# Internal use only

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd ${SCRIPT_DIR}

# The pre-generated transformation are available at: https://zenodo.org/records/11192915
for i in 02,left 10,left 17,left 19,left 01,right 04,right 16,right 18,right;
	do IFS=","; set -- $i;
	SUBJ=${1}
	HEMI=${2}
	cd sub-${SUBJ}/
	antsRegistration \
		--verbose 1 --dimensionality 3 --float 0 \
		--interpolation Linear --use-histogram-matching 0 \
		--winsorize-image-intensities [0.005,0.995] --collapse-output-transforms 1  \
		--output [to_specimen,to_specimenWarped.nii.gz,to_specimenInverseWarped.nii.gz] \
		--initial-moving-transform [sub-${SUBJ}_epo-00_ref-ACPC_brain_t1.nii.gz,../mni_masked_${HEMI}.nii.gz,1] \
		--transform Translation[0.1] \
		--metric mattes[sub-${SUBJ}_epo-00_ref-ACPC_brain_t1.nii.gz,../mni_masked_${HEMI}.nii.gz,1,32,Regular,0.3] \
		--convergence [10000x10000x10000x1000,1e-8,20] \
		--shrink-factors 8x4x2x1 \
		--smoothing-sigmas 2x1x0.5x0vox \
		--transform Rigid[0.1]  \
		--metric mattes[sub-${SUBJ}_epo-00_ref-ACPC_brain_t1.nii.gz,../mni_masked_${HEMI}.nii.gz,1,32,Regular,0.3] \
		--convergence [110000x10000x10000x1000,1e-8,20] \
		--shrink-factors 8x4x2x1  \
		--smoothing-sigmas 2x1x0.5x0vox \
		--transform Affine[0.1]  \
		--metric mattes[sub-${SUBJ}_epo-00_ref-ACPC_brain_t1.nii.gz,../mni_masked_${HEMI}.nii.gz,1,32,Regular,0.3] \
		--convergence [10000x10000x10000x1000,1e-8,20] \
		--shrink-factors 8x4x2x1 \
		--smoothing-sigmas 2x1x0.5x0vox \
		--transform SyN[0.2,3,0] \
		--metric mattes[sub-${SUBJ}_epo-00_ref-ACPC_brain_t1.nii.gz,../mni_masked_${HEMI}.nii.gz,1,32,Regular,0.3] \
		--metric CC[sub-${SUBJ}_epo-00_ref-ACPC_brain_t1.nii.gz,../mni_masked_${HEMI}.nii.gz,0.5,4] \
		--convergence [10000x10000x10000x1000,1e-8,20] \
		--shrink-factors 8x4x2x1 \
		--smoothing-sigmas 2x1x0.5x0vox 
	cd ../
done

exit 1

# Alternative (FS)
for i in 02,left 10,left 17,left 19,left 01,right 04,right 16,right 18,right;
	do IFS=","; set -- $i;
	SUBJ=${1}
	HEMI=${2}
	# Doing it reverse to apply it from MNI later
	mri_synthmorph register -m affine -t sub-${SUBJ}/init.lta -o sub-${SUBJ}/tmp.nii.gz mni_masked_${HEMI}.nii.gz sub-${SUBJ}/*-ACPC_brain_t1.nii.gz -j 8
	mri_synthmorph register -m deform -t sub-${SUBJ}/freesurfer_warp.mgz -o ${OUTPUT} sub-${SUBJ}/tmp.nii.gz sub-${SUBJ}/*-ACPC_brain_t1.nii.gz -j 8

	# Convert to ANTs
	lta_convert --inlta sub-${SUBJ}/init.lta --outitk sub-${SUBJ}/to_specimen0GenericAffine.txt
	mri_warp_convert -g sub-${SUBJ}/*-ACPC_brain_t1.nii.gz --inras sub-${SUBJ}/freesurfer_warp.mgz --outlps sub-${SUBJ}/to_specimen0Warp.nii.gz


	# Testing
	antsApplyTransforms -d 3 -i mni_masked_${HEMI}.nii.gz -r sub-${SUBJ}/*-ACPC_brain_t1.nii.gz \
	    -t sub-${SUBJ}/to_specimen0Warp.nii.gz -t sub-${SUBJ}/to_specimen0GenericAffine.txt -o sub-${SUBJ}/to_specimenWarped.nii.gz
	rm sub-${SUBJ}/init.lta sub-${SUBJ}/freesurfer_warp.mgz sub-${SUBJ}/tmp.nii.gz
done
