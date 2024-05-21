sudo docker build . -t "bradipho"
sudo singularity build bradipho.sif docker-daemon://bradipho:latest
singularity exec ~/Libraries/bradipho/bdp_registration_utils/bradipho.sif bash /bdp_registration_utils/launch_registration.sh ${PATH_TO_DATA}/ sub-01