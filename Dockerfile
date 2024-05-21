FROM scilus/scilus:1.5.0 as bradipho

RUN apt-get update
RUN apt-get -y install wget unzip git

WORKDIR /
RUN wget -O bdp_registration_utils.zip "https://www.dropbox.com/s/ccsvtjijdicn1qv/bdp_registration_utils.zip?dl=0d?download=1"
RUN unzip bdp_registration_utils.zip
RUN rm bdp_registration_utils.zip


RUN git clone https://github.com/minilabus/bradiphopy.git
WORKDIR /bradiphopy
RUN pip3 install setuptools==65.*
RUN pip3 install -e .

WORKDIR /
