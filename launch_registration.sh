#!/usr/bin/env bash

TARGET_DIR=${1}
TMP_DIR="tmp/"
OUT_DIR="output/"
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SUBJ=${2}

rm -rf ${TMP_DIR}/ ${OUT_DIR}/
mkdir -p ${TMP_DIR}/ ${OUT_DIR}/specimen ${OUT_DIR}/polylines ${OUT_DIR}/tubes

# List all files with the .nii or .nii.gz extension in the target folder
FILE_LIST=()
while IFS= read -r -d '' FILE; do
    FILE_LIST+=("${FILE}")
done < <(find "$TARGET_DIR" -type f \( -name "*.nii*" \) -print0)

# Check if there are any files with thels  specified extension
if [ ${#FILE_LIST[@]} -eq 0 ]; then
    # To avoid header problem (matching in MNI), if .trk convert to .tck and back with known --reference
    for BUNDLE in $(find "${TARGET_DIR}" -type f \( -name "*.trk" -o -name "*.tck" \));
        do EXT=$(basename "${BUNDLE}" | awk -F . '{print $NF}')
        if [ ${EXT} == "trk" ]; then
            scil_tractogram_convert.py ${BUNDLE} tmp.tck
            scil_tractogram_convert.py tmp.tck ${TMP_DIR}/$(basename ${BUNDLE}) -f --reference ${SCRIPT_DIR}/mni_masked.nii.gz
            rm tmp.tck
        fi
    done
else
    # Pick the first file with the specified extension
    FIRST_FILE="${FILE_LIST[0]}"

    # Registration from native to MNI space 
    # Use antsRegistrationSyN.sh for improved registration
    antsRegistrationSyNQuick.sh -d 3 -m ${FIRST_FILE} -f ${SCRIPT_DIR}/mni_masked.nii.gz -t s -o ${TMP_DIR}/to_mni -n 1

    # Apply to every bundle
    for BUNDLE in $(find "${TARGET_DIR}" -type f \( -name "*.trk" -o -name "*.tck" \));
        do scil_tractogram_apply_transform.py ${BUNDLE} ${SCRIPT_DIR}/mni_masked.nii.gz ${TMP_DIR}/to_mni0GenericAffine.mat ${TMP_DIR}/$(basename ${BUNDLE}) --inverse --in_deformation ${TMP_DIR}/to_mni1InverseWarp.nii.gz --cut_invalid --reference ${FIRST_FILE};
    done
fi

# Using a known transform (MNI->specimen) move all bundles to specimen space (.trk)
for BUNDLE in $(find "${TMP_DIR}" -type f \( -name "*.trk" -o -name "*.tck" \));
    do scil_tractogram_apply_transform.py ${BUNDLE} ${SCRIPT_DIR}/${SUBJ}/to_specimenWarped.nii.gz ${SCRIPT_DIR}/${SUBJ}/to_specimen0GenericAffine.mat ${OUT_DIR}/specimen/$(basename ${BUNDLE}) --inverse --in_deformation ${SCRIPT_DIR}/${SUBJ}/to_specimen1InverseWarp.nii.gz --cut_invalid --reference ${SCRIPT_DIR}/mni_masked.nii.gz;
done

# Generate both the polylines (.vtk) and tubes (.ply) in photogrammetry space
for BUNDLE in $(find "${OUT_DIR}/specimen/" -type f \( -name "*.trk" -o -name "*.tck" \));
    do EXT=$(basename "${BUNDLE}" | awk -F . '{print $NF}')
    bdp_scale_tractography_file.py ${BUNDLE} ${OUT_DIR}/polylines/$(basename ${BUNDLE} .${EXT}).vtk
    bdp_generate_tubes_from_streamlines.py ${OUT_DIR}/polylines/$(basename ${BUNDLE} .${EXT}).vtk 0.00025 ${OUT_DIR}/tubes/$(basename ${BUNDLE} .${EXT}).ply --color 255 255 255 --tol_error 0.0005 --reference ${SCRIPT_DIR}/${SUBJ}/to_specimenWarped.nii.gz
done

# rm ${TMP_DIR} -r
