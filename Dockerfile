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

ARG DEBIAN_FRONTEND=noninteractive

RUN mkdir data && mkdir algPrograms


#miniconda
WORKDIR /home/auxiliarPrograms


#CNS
RUN apt-get install -y flex
RUN apt-get install -y csh
RUN cp ./cns_solve_1.3_all_intel-mac_linux.tar.gz /home/algPrograms
WORKDIR /home/algPrograms
RUN gunzip cns_solve_1.3_all_intel-mac_linux.tar.gz
RUN tar xvf cns_solve_1.3_all_intel-mac_linux.tar
WORKDIR /home/algPrograms/cns_solve_1.3
RUN mv .cns_solve_env_sh cns_solve_env.sh
RUN sed -i "s/CNS_SOLVE=_.*/CNS_SOLVE=\/home\/algPrograms\/cns_solve_1.3/" cns_solve_env.sh
RUN sed -i "s/CNS_SOLVE '_CNS.*/CNS_SOLVE '\/home\/algPrograms\/cns_solve_1.3'/" cns_solve_env
RUN csh && source cns_solve_env && make install

# Startup to be executable
#ENTRYPOINT ["nginx", "-g", "daemon off;"]