# The pre-generated transformation are available at: https://zenodo.org/records/11192915
for i in 02 10 17 19; do antsRegistrationSyN.sh -d 3 -m mni_masked_left.nii.gz -f sub-${i}/*.nii.gz -o sub-${i}/to_specimen -n 4; done
for i in 01 04 16 18; do antsRegistrationSyN.sh -d 3 -m mni_masked_right.nii.gz -f sub-${i}/*.nii.gz -o sub-${i}/to_specimen -n 4; done
