################################################################################
# author: Connor Natzke
# Creation Date: July 2019
# Last Update: Nov  2020
# purpose: Multi-stage docker file for building a GEANT4 simulation stack
################################################################################ 

################################################################################ 
# BUILD CONTAINER
################################################################################ 

# using OSG approved base container
FROM opensciencegrid/osgvo-ubuntu-18.04:latest as stage_1

# versions of installed software
ARG version_clhep="2.2.0.4"
ARG version_geant4="geant4.10.01.p03"

# labeling information
LABEL description="Framework for running GEANT4 Simulations across non-homogenous environments"
LABEL version="0.0.1"

# Updating 
RUN apt-get update && \
    apt-get install --no-install-recommends -yy build-essential && \
    rm -rf /var/lib/apt/lists/*

# make software path
RUN mkdir /softwares

#-------------------------------------------------------------------------------
# CLHEP BUILD
#-------------------------------------------------------------------------------
RUN mkdir /softwares/CLHEP
WORKDIR /softwares/CLHEP

RUN wget https://proj-clhep.web.cern.ch/proj-clhep/dist1/clhep-${version_clhep}.tgz
RUN tar xzvf clhep-${version_clhep}.tgz && rm clhep-${version_clhep}.tgz
RUN mkdir /softwares/CLHEP/${version_clhep}/build 
WORKDIR /softwares/CLHEP/${version_clhep}/build 

RUN cmake -DCMAKE_INSTALL_PREFIX=/softwares/CLHEP/${version_clhep}/CLHEP /softwares/CLHEP/${version_clhep}/CLHEP && \
   make && make install && \
   rm -rf /softwares/CLHEP/${version_clhep}/build 

# set CLHEP environment
ENV CLHEP_BASE_DIR "/softwares/CLHEP/${version_clhep}/CLHEP"

#-------------------------------------------------------------------------------
# GEANT4 BUILD
#-------------------------------------------------------------------------------
RUN mkdir /softwares/geant4-src /softwares/geant4-src/build /softwares/${version_geant4}

# Downloads clean geant4 from internet
RUN wget https://geant4-data.web.cern.ch/geant4-data/releases/${version_geant4}.tar.gz --output-document /var/tmp/geant4.tar.gz && \
   tar zxf /var/tmp/geant4.tar.gz -C /softwares/geant4-src && rm /var/tmp/geant4.tar.gz

WORKDIR /softwares

# Clone gamma-gamma libraries
RUN git clone https://github.com/GRIFFINCollaboration/Geant4GammaGammaAngularCorrelations10.01.p01.git && \
    rsync -avh Geant4GammaGammaAngularCorrelations10.01.p01/radioactive_decay /softwares/geant4-src/${version_geant4}/source/processes/hadronic/models/ && \
    rsync -avh Geant4GammaGammaAngularCorrelations10.01.p01/photon_evaporation /softwares/geant4-src/${version_geant4}/source/processes/hadronic/models/de_excitation/ && \
    rm -rf Geant4GammaGammaAngularCorrelations10.01.p01


RUN cd /softwares/geant4-src/build && \
    cmake -DCMAKE_INSTALL_PREFIX=/softwares/${version_geant4} \ 
          -DGEANT4_INSTALL_DATA=ON \
          -DCLHEP_ROOT_DIR=/softwares/CLHEP/${version_clhep}/CLHEP \
          -DGEANT4_USE_OPENGL_X11=OFF \
          -DGEANT4_USE_GDML=OFF \
          -DGEANT4_USE_QT=OFF \
          /softwares/geant4-src/${version_geant4} && \
          make -j 4 && make install && \ 
          rm -rf /softwares/geant4-src

################################################################################ 
# STAGE 2 CONTAINER
################################################################################ 
FROM opensciencegrid/osgvo-ubuntu-18.04:latest

COPY --from=stage_1 /softwares /softwares

