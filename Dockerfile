FROM scilus/scilus:2.0.2 AS bradipho

RUN apt-get update
RUN apt-get -y install wget unzip git rsync
RUN apt-get -y install libgl1-mesa-glx

WORKDIR /
RUN rm -rf scilpy
RUN git clone https://github.com/minilabus/bdp_registration_utils.git
RUN git clone https://github.com/scilus/scilpy.git
RUN git clone https://github.com/minilabus/bradiphopy.git

WORKDIR /bdp_registration_utils/
RUN git checkout b7b88c002bfcab60f6159ea3231259fdd203f005
WORKDIR /scilpy/
RUN git checkout tags/2.1.1
WORKDIR /bradiphopy
RUN git checkout bd3ad9e67071836357dc0cf8f483261cf2fe84c3

WORKDIR /
RUN wget -O bdp_registration_utils.zip "https://zenodo.org/records/15014896/files/bdp_registration_utils.zip?download=1"
RUN unzip bdp_registration_utils.zip -d bdp_registration_utils_tmp/
RUN rsync -av --ignore-existing bdp_registration_utils_tmp/* bdp_registration_utils/
RUN rm -rf bdp_registration_utils.zip bdp_registration_utils_tmp/

WORKDIR /scilpy
RUN pip install -r requirements.txt
RUN pip3 install -e .

WORKDIR /bradiphopy
RUN pip3 install -e .

WORKDIR /
