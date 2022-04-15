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

RUN git clone https://github.com/SolangePalominoSol123/hh-suite.git && mkdir -p hh-suite/build 
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

#DMPfold
WORKDIR /home/algPrograms
RUN git clone https://github.com/SolangePalominoSol123/DMPfold.git

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
RUN apt-get install -y csh
RUN apt-get install -y gfortran
RUN cp ./cns_solve_1.3_all_intel-mac_linux.tar.gz /home/algPrograms
WORKDIR /home/algPrograms
RUN gunzip cns_solve_1.3_all_intel-mac_linux.tar.gz
RUN tar xvf cns_solve_1.3_all_intel-mac_linux.tar
WORKDIR /home/algPrograms/cns_solve_1.3
RUN mv .cns_solve_env_sh cns_solve_env.sh
RUN sed -i "s/CNS_SOLVE=_.*/CNS_SOLVE=\/home\/algPrograms\/cns_solve_1.3/" cns_solve_env.sh
RUN sed -i "s/CNS_SOLVE '_CNS.*/CNS_SOLVE '\/home\/algPrograms\/cns_solve_1.3'/" cns_solve_env 
#-------------csh , source cns_solve_env , make install
RUN csh -c "source cns_solve_env && make install"

WORKDIR /home/algPrograms/cns_solve_1.3/source
RUN sed -i "s/MXFPEPS2=.*/MXFPEPS2=8192)/" machvar.inc
RUN sed -i "s/MXRTP=.*/MXRTP=4000)/" rtf.inc
RUN sed -i "s/IF (ONE .EQ. ONE.*/IF (ONE .EQ. ONEP .OR. ONE .EQ. ONEM) THEN\n\t    WRITE (6,'(I6,E10.3,E10.3)') I, ONEP, ONEM/" machvar.f
WORKDIR /home/algPrograms/cns_solve_1.3/modules/nmr
RUN sed -i "s/nrestraints =.*/nrestraints = 50000/" readdata
RUN sed -i "s/nassign.*/nassign 3000/" readdata
WORKDIR /home/algPrograms/cns_solve_1.3/intel-x86_64bit-linux/source
RUN sed -i "s/-funroll-loops.*/-funroll-loops/" Makefile
#-----------csh , make cns_solve
#---------csh , source cns_solve_env , make clean , make no-fastm , exit 
RUN csh -c "make cns_solve && cd /home/algPrograms/cns_solve_1.3 && source cns_solve_env && make clean && make no-fastm && exit"
WORKDIR /home/algPrograms/cns_solve_1.3
RUN chmod +x cns_solve_env.sh
RUN ./cns_solve_env.sh
ENV PATH=$PATH:/home/algPrograms/cns_solve_1.3/bin:/home/algPrograms/cns_solve_1.3/intel-x86_64bit-linux/bin:/home/algPrograms/cns_solve_1.3/intel-x86_64bit-linux/utils

WORKDIR /home/algPrograms/DMPfold/cnsfiles
RUN chmod +x installscripts.sh
RUN ./installscripts.sh

# Startup to be executable
#ENTRYPOINT ["nginx", "-g", "daemon off;"]