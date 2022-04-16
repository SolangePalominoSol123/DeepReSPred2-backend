# Using ubuntu image as base
FROM ubuntu:20.04
LABEL Author: spalomino@pucp.edu.pe

# Set working directory
WORKDIR /home

# Copy all files from current directory to working dir in image
COPY . .

#apt get install
RUN apt-get update && yes | apt-get upgrade
RUN apt install -y git
RUN apt-get install -y wget
RUN apt install -y build-essential
RUN apt-get install -y python3-pip

#Python 3.7
RUN apt-get install -y software-properties-common
RUN add-apt-repository ppa:deadsnakes/ppa -y
RUN apt install python3.7 -y
#---python3.7 --version
RUN update-alternatives --install /usr/bin/python3 python /usr/bin/python3.8 1
RUN update-alternatives --install /usr/bin/python3 python /usr/bin/python3.7 2
RUN ln -sv /usr/bin/python3.7 python
#---python --version

#MySQL Dependencies
RUN apt install -y mysql-client-core-8.0
RUN apt-get install -y libmysqlclient-dev
RUN apt install -y libpython3.7-dev

#BD Config