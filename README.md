# Getting Started
This is a containerized version of Geant4.10.01.p03 with the gamma-gamma
angulare correlation hack installed. 

## Building 
To build the docker image, run the below command:
```
docker build --tag <tag> .
```
in the directory containing the files `Dockerfile`

## Running 
To run the container as root user:
```
docker run -it --rm=true cnatzke/geant4.10.01:latest
```
To run similar to the OSG implementation (recommended)
```
docker run --user $(id -u):$(id -g) --rm=true -it -v $(pwd):/scratch -w
/scratch cnatzke/geant4.10.01:latest /bin/bash 
```
