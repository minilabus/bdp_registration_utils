# How to build the Docker/Singularity
sudo docker build . -t "bradipho" --rm --no-cache
sudo singularity build bradipho.sif docker-daemon://bradipho:latest

# Example command to launch
# singularity exec ~/Libraries/bradipho/bdp_registration_utils/bradipho.sif bash /bdp_registration_utils/launch_registration.sh ${PATH_TO_DATA}/ sub-01
