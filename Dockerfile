FROM scilus/scilus:2.0.2 as bradipho

RUN apt-get update
RUN apt-get -y install wget unzip git

WORKDIR /
RUN git clone https://github.com/minilabus/bdp_registration_utils.git
RUN wget -O bdp_registration_utils.zip "https://zenodo.org/records/11192915/files/bdp_registration_utils.zip?download=1"
RUN unzip bdp_registration_utils.zip -d bdp_registration_utils_tmp/
RUN cp -r bdp_registration_utils_tmp/ bdp_registration_utils/
RUN rm -rf bdp_registration_utils.zip bdp_registration_utils_tmp/

RUN git clone https://github.com/minilabus/bradiphopy.git
WORKDIR /bradiphopy
RUN pip3 install setuptools==65.*
RUN pip3 install -e .

WORKDIR /
