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

#miniconda
WORKDIR /home/auxiliarPrograms

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
#csh , source cns_solve_env , make install
RUN csh cns_solve_env 
RUN make -j 4 && make install


WORKDIR /home/algPrograms/cns_solve_1.3/source
RUN sed -i "s/MXFPEPS2=.*/MXFPEPS2=8192)/" machvar.inc
RUN sed -i "s/MXRTP=.*/MXRTP=4000)/" rtf.inc
RUN sed -i "s/IF (ONE .EQ. ONE.*/IF (ONE .EQ. ONEP .OR. ONE .EQ. ONEM) THEN\n\t    WRITE (6,'(I6,E10.3,E10.3)') I, ONEP, ONEM/" machvar.f
WORKDIR /home/algPrograms/cns_solve_1.3/modules/nmr
RUN sed -i "s/nrestraints =.*/nrestraints = 50000/" readdata
RUN sed -i "s/nassign.*/nassign 3000/" readdata
WORKDIR /home/algPrograms/cns_solve_1.3/intel-x86_64bit-linux/source
RUN sed -i "s/-funroll-loops.*/-funroll-loops/" Makefile
#csh , make cns_solve
RUN csh
RUN make cns_solve
WORKDIR /home/algPrograms/cns_solve_1.3
#csh , source cns_solve_env , make clean , make no-fastm , exit 
RUN csh cns_solve_env 
RUN make -j 4 && make clean && make no-fastm

RUN chmod +x cns_solve_env.sh
RUN ./cns_solve_env.sh