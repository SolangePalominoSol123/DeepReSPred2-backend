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
#RUN apt install -y build-essential
#RUN apt-get install -y cmake
#RUN apt-get install -y build-essential cmake xxd ninja-build


RUN mkdir data && mkdir algPrograms

#--------------------------------------DATABASE--------------------------------------

RUN wget https://wwwuser.gwdg.de/~compbiol/data/hhsuite/databases/hhsuite_dbs/pfamA_35.0.tar.gz -o ./data/outputPfam.txt -P ./data/
#RUN tar -xzvf ./data/pfamA_35.0.tar.gz

#--------------------------------ALGORITHMS COMPONENTS--------------------------------

#hh-suite
RUN cd ./algPrograms && git clone https://github.com/SolangePalominoSol123/hh-suite.git ./algPrograms && \
    mkdir -p hh-suite/build && cd hh-suite/build
#RUN cmake -DCMAKE_INSTALL_PREFIX=. ..  
#RUN make -j 4 && make install






# Startup to be executable
#ENTRYPOINT ["nginx", "-g", "daemon off;"]