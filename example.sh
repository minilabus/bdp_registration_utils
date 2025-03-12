# How to build the Docker/Singularity
docker build . -t "bradipho" --rm --no-cache
singularity build bradipho.sif docker-daemon://bradipho:latest

# Example command to launch
# singularity exec bradipho.sif bash /bdp_registration_utils/launch_registration.sh ${PATH_TO_DATA}/ sub-01  out_dir/
