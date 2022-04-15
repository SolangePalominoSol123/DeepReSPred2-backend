# Using ubuntu image as base
#FROM alpine:3.15.0
FROM ubuntu:20.04

# Set working directory
WORKDIR /home

# Copy all files from current directory to working dir in image
COPY . .

#apt get install
RUN apt-get update && yes | apt-get upgrade
RUN apt install -y git
RUN apt-get install -y wget
RUN apt install -y build-essential

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/London
RUN apt-get install -y cmake

RUN mkdir data && mkdir algPrograms

#--------------------------------------DATABASE--------------------------------------

#RUN wget https://wwwuser.gwdg.de/~compbiol/data/hhsuite/databases/hhsuite_dbs/pfamA_35.0.tar.gz -o ./data/outputPfam.txt -P ./data/
#RUN tar -xzvf home/data/pfamA_35.0.tar.gz

#--------------------------------ALGORITHMS COMPONENTS--------------------------------

#hh-suite
WORKDIR /home/algPrograms

RUN git clone https://github.com/SolangePalominoSol123/hh-suite.git && \
    mkdir -p hh-suite/build 
WORKDIR /home/algPrograms/hh-suite/build
RUN cmake -DCMAKE_INSTALL_PREFIX=. ..  
RUN make -j 4 && make install

ENV PATH=/home/algPrograms/hh-suite/build/bin:/home/algPrograms/hh-suite/build/scripts:$PATH

#free-contact
RUN apt-get install -y freecontact

#CCMPred
WORKDIR /home/algPrograms
RUN git clone --recursive https://github.com/SolangePalominoSol123/CCMpred.git
WORKDIR /home/algPrograms/CCMpred
RUN cmake -DWITH_CUDA=off -DWITH_OMP=off .
RUN make
RUN cp ./bin/ccmpred /bin/ccmpred

#miniconda
WORKDIR /home/auxiliarPrograms
RUN yes | /bin/bash Miniconda3-latest-Linux-x86_64.sh -b -p $HOME/miniconda
ENV PATH=/root/miniconda/condabin:/root/miniconda/bin:$PATH

#Modeller  
ARG MODELLERLICENSE=MODELIRANJE
ENV KEY_MODELLER=${MODELLERLICENSE}
RUN echo "Valor MODELLERLICENSE= ${MODELLERLICENSE}"
RUN conda install -y modeller -c salilab  

#Blast-Legacy 
RUN conda install -y -c bioconda blast-legacy 

#TM-align
RUN apt-get install -y tm-align

#CNS
RUN apt-get install -y flex

# Startup to be executable
#ENTRYPOINT ["nginx", "-g", "daemon off;"]