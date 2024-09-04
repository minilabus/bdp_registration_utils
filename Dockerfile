FROM scilus/scilus:2.0.2 as bradipho

RUN apt-get update
RUN apt-get -y install wget unzip git rsync

WORKDIR /
RUN rm -rf scilpy
RUN git clone https://github.com/minilabus/bdp_registration_utils.git
RUN git clone https://github.com/scilus/scilpy.git
RUN git clone https://github.com/minilabus/bradiphopy.git

RUN wget -O bdp_registration_utils.zip "https://zenodo.org/records/11192915/files/bdp_registration_utils.zip?download=1"
RUN unzip bdp_registration_utils.zip -d bdp_registration_utils_tmp/
RUN rsync -av --ignore-existing bdp_registration_utils_tmp/* bdp_registration_utils/
RUN rm -rf bdp_registration_utils.zip bdp_registration_utils_tmp/

WORKDIR /bradiphopy
RUN pip3 install setuptools==65.*
RUN pip3 install -e .

WORKDIR /scilpy
RUN pip3 install -e .

WORKDIR /
