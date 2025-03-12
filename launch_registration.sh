#!/usr/bin/env bash

# Bash script to run the registration procedure

TARGET_DIR=${1}
TMP_DIR="tmp_$((1 + $RANDOM % 100))/"
OUT_DIR=${3}
SCRIPT_DIR="/bdp_registration_utils/"
# SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd ) # For local testing
SUBJ=${2}
IS_ONLINE=false

# Check if the target directory exists
if [ ! -d ${TARGET_DIR} ]; then
    echo "The target directory does not exist."
    exit 1
fi

# Check if the subject directory exists
if [ ! -d ${SCRIPT_DIR}/${SUBJ} ]; then
    echo "The subject directory does not exist."
    exit 1
fi

echo "Prepare input data and organize by file format..."
    if [ ${IS_ONLINE} = true ] ; then
        ANTS_OPTS=""
    else
        MKDIR_OPTS="${OUT_DIR}/cloud_compare/polylines"
    fi

rm -rf ${OUT_DIR}/ ${TMP_DIR}/
mkdir -p ${TMP_DIR}/images ${TMP_DIR}/labels_masks ${TMP_DIR}/streamlines \
    ${TMP_DIR}/meshes_point_clouds
mkdir -p ${OUT_DIR}/native/images ${OUT_DIR}/native/labels_masks \
    ${OUT_DIR}/native/streamlines ${OUT_DIR}/native/meshes_point_clouds
mkdir -p ${OUT_DIR}/cloud_compare/tubes ${MKDIR_OPTS} \
    ${OUT_DIR}/cloud_compare/meshes_point_clouds

python ${SCRIPT_DIR}/reorganize_files.py ${TARGET_DIR} ${TMP_DIR}/reorganized/ -f
REFERENCE=${TMP_DIR}/reorganized/reference.nii*

shopt -s nullglob
# Check if there are any files with the  specified extension
if [ ! -f ${REFERENCE} ]; then
    cp ${SCRIPT_DIR}/mni_masked.nii.gz ${TMP_DIR}/reorganized/reference.nii.gz
fi

# To avoid header problem (ALL TRK matching all NIFTI)
# If the header is not compatible, attempt to fix it by converting to .tck
# and then back to .trk
echo "Harmonize headers to all match a reference image..."
for BUNDLE in ${TMP_DIR}/reorganized/streamlines/*.trk;
    do EXT=$(basename "${BUNDLE}" | awk -F . '{print $NF}')
    scil_header_validate_compatibility.py ${BUNDLE} ${REFERENCE} > ${TMP_DIR}/log.txt 2>&1
    if grep -q "All input files have compatible headers" ${TMP_DIR}/log.txt; then
        continue
    fi
    echo "Fixing header for ${BUNDLE}"
    scil_tractogram_convert.py ${BUNDLE} ${TMP_DIR}/tmp.tck -f
    scil_tractogram_convert.py ${TMP_DIR}/tmp.tck ${BUNDLE} --reference ${REFERENCE} -f
done
rm ${TMP_DIR}/tmp.tck -rf

scil_header_validate_compatibility.py ${SCRIPT_DIR}/mni_masked.nii.gz ${REFERENCE} \
    ${TMP_DIR}/streamlines/* ${TMP_DIR}/reorganized/labels_masks/* \
    ${TMP_DIR}/reorganized/images/* > ${TMP_DIR}/log.txt 2>&1

# Sneak in nifti as surfaces (useful only for actual binary data)
for NIFTI in ${TMP_DIR}/reorganized/images/* ${TMP_DIR}/reorganized/labels_masks/*;
    do FILENAME="${NIFTI%%.*}"
    scil_volume_math.py lower_threshold ${NIFTI} 0.001 ${TMP_DIR}/tmp.nii.gz \
        --data_type uint8 -f;
    bdp_convert_nifti_to_surface.py ${TMP_DIR}/tmp.nii.gz \
        ${TMP_DIR}/reorganized/meshes_point_clouds/$(basename ${FILENAME}).ply
done
rm ${TMP_DIR}/tmp.nii.gz -rf

if ! grep -q "All input files have compatible headers" ${TMP_DIR}/log.txt; then
    echo "Registration to MNI in case the provided data does not match our MNI template..."
    # Registration from native to MNI space 
    # Use antsRegistrationSyN.sh for improved registration
    if [ ${IS_ONLINE} = true ] ; then
        ANTS_OPTS="-t a"
    else
        ANTS_OPTS="-t s"
    fi

    antsRegistrationSyNQuick.sh -d 3 -m ${REFERENCE} \
        -f ${SCRIPT_DIR}/mni_masked.nii.gz ${ANTS_OPTS} -o ${TMP_DIR}/to_mni -n 1 > ${TMP_DIR}/log.txt

    # Apply to every bundle (after validation of header, the files are not in
    # the reorganized folder anymore). That's why we use -f, to overwrite files
    echo "Apply transform to our MNI template..."
    echo " - To streamlines"
    if [ ${IS_ONLINE} = true ] ; then
        WARP_OPTS=""
    else
        WARP_OPTS="--in_deformation ${TMP_DIR}/to_mni1InverseWarp.nii.gz"
    fi
    for BUNDLE in ${TMP_DIR}/reorganized/streamlines/*;
        do scil_tractogram_apply_transform.py ${BUNDLE} ${SCRIPT_DIR}/mni_masked.nii.gz \
            ${TMP_DIR}/to_mni0GenericAffine.mat ${TMP_DIR}/streamlines/$(basename ${BUNDLE}) \
            --inverse ${WARP_OPTS} --cut_invalid -f;
    done

    echo " - To meshes and points clouds"
    for MESH in ${TMP_DIR}/reorganized/meshes_point_clouds/*;
        do scil_surface_apply_transform.py ${MESH} \
            ${TMP_DIR}/to_mni0GenericAffine.mat ${TMP_DIR}/meshes_point_clouds/$(basename ${MESH}) \
            --inverse ${WARP_OPTS};
    done

    echo " - To images"
    if [ ${IS_ONLINE} = true ] ; then
        WARP_OPTS=""
    else
        WARP_OPTS="-t ${TMP_DIR}/to_mni1Warp.nii.gz"
    fi

    for IMAGE in ${TMP_DIR}/reorganized/images/*;
        do antsApplyTransforms -d 3 -i ${IMAGE} -r ${SCRIPT_DIR}/mni_masked.nii.gz \
            -o ${TMP_DIR}/images/$(basename ${IMAGE}) \
            ${WARP_OPTS} -t ${TMP_DIR}/to_mni0GenericAffine.mat \
            --interpolation Linear;
    done

    echo " - To labels and masks"
    for LABEL in ${TMP_DIR}/reorganized/labels_masks/*;
        do antsApplyTransforms -d 3 -i ${LABEL} -r ${SCRIPT_DIR}/mni_masked.nii.gz \
            -o ${TMP_DIR}/labels_masks/$(basename ${LABEL}) \
            ${WARP_OPTS} -t ${TMP_DIR}/to_mni0GenericAffine.mat \
            --interpolation NearestNeighbor -u short;
    done
else
    cp ${TMP_DIR}/reorganized/* ${TMP_DIR}/ -r
fi
rm ${TMP_DIR}/reorganized/ -rf

echo "Apply transform from our MNI template to the desired specimen..."
# Using a known transform (MNI->specimen) move all bundles to specimen space (.trk)
echo " - To streamlines"
for BUNDLE in ${TMP_DIR}/streamlines/*;
    do scil_tractogram_apply_transform.py ${BUNDLE} \
        ${SCRIPT_DIR}/${SUBJ}/to_specimenWarped.nii.gz \
        ${SCRIPT_DIR}/${SUBJ}/to_specimen0GenericAffine.mat \
        ${OUT_DIR}/native/streamlines/$(basename ${BUNDLE}) --inverse \
        --in_deformation ${SCRIPT_DIR}/${SUBJ}/to_specimen1InverseWarp.nii.gz \
        --cut_invalid --reference ${SCRIPT_DIR}/mni_masked.nii.gz &> ${TMP_DIR}/log.txt;
done

echo " - To meshes and points clouds"
for MESH in ${TMP_DIR}/meshes_point_clouds/*;
    do scil_surface_apply_transform.py ${MESH} \
        ${SCRIPT_DIR}/${SUBJ}/to_specimen0GenericAffine.mat \
        ${OUT_DIR}/native/meshes_point_clouds/$(basename ${MESH}) --inverse \
        --in_deformation ${SCRIPT_DIR}/${SUBJ}/to_specimen1InverseWarp.nii.gz;
done

echo " - To images"
for IMAGE in ${TMP_DIR}/images/*;
    do antsApplyTransforms -d 3 -i ${IMAGE} -r ${SCRIPT_DIR}/${SUBJ}/to_specimenWarped.nii.gz \
        -o ${OUT_DIR}/native/images/$(basename ${IMAGE}) \
        -t ${SCRIPT_DIR}/${SUBJ}/to_specimen1Warp.nii.gz \
        -t ${SCRIPT_DIR}/${SUBJ}/to_specimen0GenericAffine.mat \
        --interpolation Linear;
done

echo " - To labels and masks"
for LABEL in ${TMP_DIR}/labels_masks/*;
    do antsApplyTransforms -d 3 -i ${LABEL} -r ${SCRIPT_DIR}/${SUBJ}/to_specimenWarped.nii.gz \
        -o ${OUT_DIR}/native/labels_masks/$(basename ${LABEL}) \
        -t ${SCRIPT_DIR}/${SUBJ}/to_specimen1Warp.nii.gz \
        -t ${SCRIPT_DIR}/${SUBJ}/to_specimen0GenericAffine.mat \
        --interpolation NearestNeighbor;
done

# Generate meshes, polylines (.vtk), tubes (.ply) in photogrammetry space
echo "Generate meshes, polylines and tubes in photogrammetry space..."
for BUNDLE in ${OUT_DIR}/native/streamlines/*
    do EXT=$(basename "${BUNDLE}" | awk -F . '{print $NF}')

    if [ ${IS_ONLINE} = false ];
        then bdp_scale_tractography_file.py ${BUNDLE} \
            ${OUT_DIR}/cloud_compare/polylines/$(basename ${BUNDLE} .${EXT}).vtk
    fi

    bdp_generate_tubes_from_streamlines.py ${BUNDLE} 0.00025 \
        ${OUT_DIR}/cloud_compare/tubes/$(basename ${BUNDLE} .${EXT}).ply \
        --color 255 255 255 --tol_error 0.0005 --scaling 0.001 \
        --reference ${SCRIPT_DIR}/${SUBJ}/to_specimenWarped.nii.gz
done

echo "Scale for CloudCompare..."
for MESH in ${OUT_DIR}/native/meshes_point_clouds/*
    do bdp_scale_surface_file.py ${MESH} \
        ${OUT_DIR}/cloud_compare/meshes_point_clouds/$(basename ${MESH}) --to_lps
done

rm ${TMP_DIR} -rf
