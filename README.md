# Deployment with Docker

Docker provides an easy way to create lightweight virtual machines called containers. It is a vast subject area, with many 
nuances for different build platforms.

## Prerequisits

- Docker installed on local or remote machine(s)


# Content 

- **Dockerfile** - instruction to build your own flavour of Corda docker
- **compose** - directory with an example of Corda network create with the Docker Compose
- **swarm** - directory with an example of Corda network create with the Docker Swarm
- **scripts** - directory additional scripts


## Build the Docker image

In the _scripts_ directory there  is the `./docker-build.sh` script that will clean and build the image. Just run
it to create your Docker image appropriately tagged. If you need to make your own, just copy what's
already there and modify.

# Further Reading

## Background 

We collect some backgrkound information about Docker [here](Background.md).

## Docker Compose

Docker Compose builds your complete network consisting of multiple linked containers. 
You can find and example of compse definition for Corda with some furter [information](compose/README.md) in the _comopse_ directory.

## Swarm

Please refer to the Docker Swarm information for using Docker at scale with multiple host machines. 
You can find and example of swarm definition for Corda with some furter [information](swarm/README.md) in the _swarm_ directory.



