#!/usr/bin/env bash

TARGET_DIR=${1}
TMP_DIR="tmp/"
OUT_DIR="output/"
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SUBJ=${2}

rm -rf ${OUT_DIR}/ ${TMP_DIR}/
mkdir -p ${TMP_DIR}/images ${TMP_DIR}/labels_masks ${TMP_DIR}/streamlines \
    ${TMP_DIR}/meshes
mkdir -p ${OUT_DIR}/native/images ${OUT_DIR}/native/labels_masks \
    ${OUT_DIR}/native/streamlines ${OUT_DIR}/native/meshes
mkdir -p ${OUT_DIR}/cloud_compare/tubes ${OUT_DIR}/cloud_compare/polylines \
    ${OUT_DIR}/cloud_compare/meshes

python reorganize_files.py ${TARGET_DIR} ${TMP_DIR}/reorganized/ -f
REFERENCE=${TMP_DIR}/reorganized/reference.nii.gz
shopt -s nullglob
# Check if there are any files with the  specified extension
if [ ! -f ${REFERENCE} ]; then
    REFERENCE=${SCRIPT_DIR}/mni_masked.nii.gz
fi

# To avoid header problem (ALL TRK matching all NIFTI)
# If the header is not compatible, attempt to fix it by converting to .tck
# and then back to .trk
for BUNDLE in ${TMP_DIR}/reorganized/bundles/*.trk;
    do EXT=$(basename "${BUNDLE}" | awk -F . '{print $NF}')
    scil_header_validate_compatibility.py ${BUNDLE} ${REFERENCE} > ${TMP_DIR}/log.txt
    if grep -q "All input files have compatible headers" ${TMP_DIR}/log.txt; then
        cp ${BUNDLE} ${TMP_DIR}/streamlines/$(basename ${BUNDLE})
        continue
    fi
    echo "Fixing header for ${BUNDLE}"
    scil_tractogram_convert.py ${BUNDLE} tmp.tck
    scil_tractogram_convert.py tmp.tck ${TMP_DIR}/streamlines/$(basename ${BUNDLE}) \
        --reference ${REFERENCE} -f
    rm tmp.tck
done

REFERENCE=${TMP_DIR}/reorganized/reference.nii.gz
if [ -f ${REFERENCE} ]; then
    # Registration from native to MNI space 
    # Use antsRegistrationSyN.sh for improved registration
    antsRegistrationSyNQuick.sh -d 3 -m ${REFERENCE} \
        -f ${SCRIPT_DIR}/mni_masked.nii.gz -t s -o ${TMP_DIR}/to_mni -n 1

    # Apply to every bundle (after validation of header, the files are not in
    # the reorganized folder anymore). That's why we use -f, to overwrite files
    for BUNDLE in ${TMP_DIR}/streamlines/*;
        do scil_tractogram_apply_transform.py ${BUNDLE} ${SCRIPT_DIR}/mni_masked.nii.gz \
            ${TMP_DIR}/to_mni0GenericAffine.mat ${TMP_DIR}/streamlines/$(basename ${BUNDLE}) \
            --inverse --in_deformation ${TMP_DIR}/to_mni1InverseWarp.nii.gz \
            --cut_invalid -f;
    done

    for MESH in ${TMP_DIR}/reorganized/meshes_points_clouds/*;
        do scil_surface_apply_transform.py ${MESH} \
            ${TMP_DIR}/to_mni0GenericAffine.mat ${TMP_DIR}/meshes/$(basename ${MESH}) \
            --in_deformation ${TMP_DIR}/to_mni1InverseWarp.nii.gz;
    done

    for IMAGE in ${TMP_DIR}/reorganized/images/*;
        do antsApplyTransforms -d 3 -i ${IMAGE} -r ${SCRIPT_DIR}/mni_masked.nii.gz \
            -o ${TMP_DIR}/images/$(basename ${IMAGE}) -t ${TMP_DIR}/to_mni0GenericAffine.mat \
            -t ${TMP_DIR}/to_mni1InverseWarp.nii.gz --interpolation Linear;
    done

    for LABEL in ${TMP_DIR}/reorganized/labels_masks/*;
        do antsApplyTransforms -d 3 -i ${LABEL} -r ${SCRIPT_DIR}/mni_masked.nii.gz \
            -o ${TMP_DIR}/labels_masks/$(basename ${LABEL}) -t ${TMP_DIR}/to_mni0GenericAffine.mat \
            -t ${TMP_DIR}/to_mni1InverseWarp.nii.gz --interpolation NearestNeighbor -u short;
    done
fi

# Using a known transform (MNI->specimen) move all bundles to specimen space (.trk)
for BUNDLE in ${TMP_DIR}/streamlines/*;
    do scil_tractogram_apply_transform.py ${BUNDLE} \
        ${SCRIPT_DIR}/${SUBJ}/to_specimenWarped.nii.gz \
        ${SCRIPT_DIR}/${SUBJ}/to_specimen0GenericAffine.mat \
        ${OUT_DIR}/native/streamlines/$(basename ${BUNDLE}) --inverse \
        --in_deformation ${SCRIPT_DIR}/${SUBJ}/to_specimen1InverseWarp.nii.gz \
        --cut_invalid --reference ${SCRIPT_DIR}/mni_masked.nii.gz;
done

for MESH in ${TMP_DIR}/meshes/*;
    do scil_surface_apply_transform.py ${MESH} \
        ${SCRIPT_DIR}/${SUBJ}/to_specimen0GenericAffine.mat \
        ${OUT_DIR}/native/meshes/$(basename ${MESH}) --inverse \
        --in_deformation ${SCRIPT_DIR}/${SUBJ}/to_specimen1InverseWarp.nii.gz;
done

for IMAGE in ${TMP_DIR}/images/*;
    do antsApplyTransforms -d 3 -i ${IMAGE} -r ${SCRIPT_DIR}/${SUBJ}/to_specimenWarped.nii.gz \
        -o ${OUT_DIR}/native/images/$(basename ${IMAGE}) \
        -t ${SCRIPT_DIR}/${SUBJ}/to_specimen0GenericAffine.mat \
        -t ${SCRIPT_DIR}/${SUBJ}/to_specimen1InverseWarp.nii.gz --interpolation Linear;
done

for LABEL in ${TMP_DIR}/labels_masks/*;
    do antsApplyTransforms -d 3 -i ${LABEL} -r ${SCRIPT_DIR}/${SUBJ}/to_specimenWarped.nii.gz \
        -o ${OUT_DIR}/native/labels_masks/$(basename ${LABEL}) \
        -t ${SCRIPT_DIR}/${SUBJ}/to_specimen0GenericAffine.mat \
        -t ${SCRIPT_DIR}/${SUBJ}/to_specimen1InverseWarp.nii.gz --interpolation NearestNeighbor;
done

# Generate meshes, polylines (.vtk), tubes (.ply) in photogrammetry space
for BUNDLE in ${OUT_DIR}/native/streamlines/*
    do EXT=$(basename "${BUNDLE}" | awk -F . '{print $NF}')
    bdp_scale_tractography_file.py ${BUNDLE} \
        ${OUT_DIR}/cloud_compare/polylines/$(basename ${BUNDLE} .${EXT}).vtk
    bdp_generate_tubes_from_streamlines.py ${OUT_DIR}/cloud_compare/polylines/$(basename \
        ${BUNDLE} .${EXT}).vtk 0.00025 \
        ${OUT_DIR}/cloud_compare/tubes/$(basename ${BUNDLE} .${EXT}).ply \
        --color 255 255 255 --tol_error 0.0005 \
        --reference ${SCRIPT_DIR}/${SUBJ}/to_specimenWarped.nii.gz
done

for MESH in ${OUT_DIR}/native/meshes/*
    do bdp_scale_surface_file.py ${MESH} ${OUT_DIR}/cloud_compare/meshes/$(basename ${MESH}) --to_lps
done

rm ${TMP_DIR} -r
