# Using ubuntu image as base
FROM ubuntu:20.04
LABEL Author: spalomino@pucp.edu.pe

# Set working directory
WORKDIR /home

# Copy all files from current directory to working dir in image
COPY . .

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/London

#apt get install
RUN apt-get update && yes | apt-get upgrade
RUN apt install -y git
RUN apt-get install -y wget
RUN apt install -y build-essential
RUN apt-get install -y python3-pip
RUN apt install -y nginx

#Python 3.7
RUN apt-get install -y software-properties-common
RUN add-apt-repository ppa:deadsnakes/ppa -y
RUN apt install python3.7 -y
#---python3.7 --version
RUN update-alternatives --install /usr/bin/python3 python /usr/bin/python3.8 1
RUN update-alternatives --install /usr/bin/python3 python /usr/bin/python3.7 2
RUN ln -sv /usr/bin/python3.7 python
RUN apt-get install -y python3.7-distutils
RUN alias python=python3.7
#---python --version    

#MySQL Dependencies
RUN apt install -y mysql-client-core-8.0
RUN apt-get install -y libmysqlclient-dev
RUN apt install -y libpython3.7-dev

#Cmake
RUN apt-get install -y cmake

RUN mkdir data && mkdir algPrograms

#--------------------------------------DATABASE--------------------------------------
WORKDIR /home/data
#RUN wget https://wwwuser.gwdg.de/~compbiol/data/hhsuite/databases/hhsuite_dbs/pfamA_35.0.tar.gz -o outputPfam.txt
#RUN tar -xzvf pfamA_35.0.tar.gz

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
RUN yes | /bin/bash Miniconda3-latest-Linux-x86_64.sh -b -p /home/miniconda
ENV PATH=/home/miniconda/condabin:/home/miniconda/bin:$PATH

#Modeller  
ARG MODELLERLICENSE=MODELIRANJE
ENV KEY_MODELLER=${MODELLERLICENSE}
RUN echo "Valor MODELLERLICENSE= ${MODELLERLICENSE}"
RUN conda install -y modeller -c salilab  

#Blast-Legacy 
RUN conda install -y -c bioconda blast-legacy 
#--RUN BLASTDIR=$(ls /home/miniconda/pkgs | grep -P '^(blast).*[^(.tar)(.bz2)]$')

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
#---------csh , source cns_solve_env , make install
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
#---------csh , make cns_solve
#---------csh , source cns_solve_env , make clean , make no-fastm , exit 
RUN csh -c "make cns_solve && cd /home/algPrograms/cns_solve_1.3 && source cns_solve_env && make clean && make no-fastm && exit"
WORKDIR /home/algPrograms/cns_solve_1.3
RUN chmod +x cns_solve_env.sh
RUN ./cns_solve_env.sh
ENV PATH=$PATH:/home/algPrograms/cns_solve_1.3/bin:/home/algPrograms/cns_solve_1.3/intel-x86_64bit-linux/bin:/home/algPrograms/cns_solve_1.3/intel-x86_64bit-linux/utils

WORKDIR /home/algPrograms/DMPfold/cnsfiles
RUN chmod +x installscripts.sh
RUN ./installscripts.sh

#--------------------------------DEEPRESPRED CONFIGURATION--------------------------------

#DeepReSPred pip Dependencies
WORKDIR /home/back_project
RUN pip install -r requirements.txt 
#RUN python3.7 -m pip install -r requirements.txt #si se comenta la linea 31

#Mapping Fasta file 
WORKDIR /home/back_project/deepReSPred
RUN echo "Defining PFAM Download type with PFAM_MODE ARG: seed (default) or full"
ARG PFAM_MODE=seed
RUN echo "Valor PFAM_MODE=${PFAM_MODE}"
#RUN echo "Choose PFAM Download type with PFAMTYPE ARG: seed (default) or full"
#ARG PFAMTYPE=full
#RUN echo "Valor PFAMTYPE=${PFAMTYPE}"
#RUN sed -i "s/alnType=seed/alnType=${PFAMTYPE}/" MappingFasta.py

ARG LOCAL_AWS_FLAG=True

#DMPfold files
ARG NCPU=4
ARG DMPFOLDDIR="\/home\/algPrograms\/DMPfold"
ARG HHBIN="\/home\/algPrograms\/hh-suite\/build\/bin"
ARG HHDB="\/home\/data\/pfam"
ARG CCMPREDDIR="\/home\/algPrograms\/CCMpred\/bin"
ARG FREECONTACTCMD="\/usr\/bin\/freecontact"
ARG NCBIDIR="\/home\/miniconda\/pkgs\/blast-legacy-2.2.26-h9ee0642_3\/bin"

WORKDIR /home/algPrograms/DMPfold
#---------seq2maps.csh
RUN sed -i "s/ncpu =.*/ncpu = ${NCPU}/" seq2maps.csh
RUN sed -i "s/dmpfolddir =.*/dmpfolddir = ${DMPFOLDDIR}/" seq2maps.csh
RUN sed -i "s/setenv HHBIN.*/setenv HHBIN ${HHBIN}/" seq2maps.csh
RUN sed -i "s/setenv HHDB.*/setenv HHDB ${HHDB}/" seq2maps.csh
RUN sed -i "s/ccmpreddir =.*/ccmpreddir = ${CCMPREDDIR}/" seq2maps.csh
RUN sed -i "s/freecontactcmd =.*/freecontactcmd = ${FREECONTACTCMD}/" seq2maps.csh
RUN sed -i "s/ncbidir =.*/ncbidir = ${NCBIDIR}/" seq2maps.csh
#---------aln2maps.csh
RUN sed -i "s/ncpu =.*/ncpu = ${NCPU}/" aln2maps.csh
RUN sed -i "s/dmpfolddir =.*/dmpfolddir = ${DMPFOLDDIR}/" aln2maps.csh
RUN sed -i "s/ccmpreddir =.*/ccmpreddir = ${CCMPREDDIR}/" aln2maps.csh
RUN sed -i "s/freecontactcmd =.*/freecontactcmd = ${FREECONTACTCMD}/" aln2maps.csh
RUN sed -i "s/ncbidir =.*/ncbidir = ${NCBIDIR}/" aln2maps.csh
#---------predict_tmscore.sh
RUN sed -i "s/dmpfolddir=.*/dmpfolddir=${DMPFOLDDIR}/" predict_tmscore.sh
#---------bin/runpsipredandsolvwithdb
WORKDIR /home/algPrograms/DMPfold/bin
RUN sed -i "s/dmpfolddir =.*/dmpfolddir = ${DMPFOLDDIR}/" runpsipredandsolvwithdb
RUN sed -i "s/ncbidir =.*/ncbidir = ${NCBIDIR}/" runpsipredandsolvwithdb

# Startup to be executable nginx
#COPY ./nginx-config/startup.sh ./startup.sh
WORKDIR /home/nginx-config

# Startup to be executable
RUN chmod +x startup.sh
ENTRYPOINT ["./startup.sh"]