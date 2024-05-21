FROM scilus/scilus:2.0.2 as bradipho

RUN apt-get update
RUN apt-get -y install wget unzip git

WORKDIR /
RUN git clone https://github.com/minilabus/bdp_registration_utils.git


RUN git clone https://github.com/minilabus/bradiphopy.git
WORKDIR /bradiphopy
RUN pip3 install setuptools==65.*
RUN pip3 install -e .

WORKDIR /
