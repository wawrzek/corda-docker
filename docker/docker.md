# Deployment with Docker

Docker provides an easy way to create lightweight virtual machines called containers. It is a vast subject area, with many 
nuances for different build platforms. In our case we need to focus on MongoDB and Node to support Meteor applications. 

## Background reading

A container is an instance of a Docker image running on a host virtual machine.

Typically a developer machine will be running a virtual machine dedicated to Docker (the host). On OSX this is likely
 to be a  VirtualBox image based on `boot2docker.iso`. The Docker command line interface (CLI) will talk to this image 
 (usually named `default`) and manage Docker containers on it. This means that there are a few layers between the 
 developer and their Docker containers.

Think of a container as a set of diffs from a standard VM image. Because they're just diffs they are very lightweight. This
means that you can run thousands on a single developer machine. Each container behaves like a full VM so this is a great way
to simulate large networks with minimal overhead.

The general approach with Docker is to create a container per process. Therefore in the case of Meteor, we'd need a container
for the MongoDB database server, and another for the Node execution environment.

Docker supports the concept of linking and maintains its own virtual network between containers. Therefore it is possible for
one container to find another using a `hosts` entry. Configuring this can get a bit complex, so Docker Compose is used to create
suitable network topology descriptors (in YAML). Different environments (such as AWS Elastic Beanstalk) can read these files, or
a conversion of them, to allow Docker images to be deployed with a minimum of fuss.

Supporting articles with more information. You should definitely read these:

* [First steps with Docker, MongoDB and Node](http://www.ifdattic.com/how-to-mongodb-nodejs-docker/)
* [AWS ECS deployment strategy](http://www.ybrikman.com/writing/2015/11/11/running-docker-aws-ground-up/)

## The `Dockerfile`

The `Dockerfile` is the image build script. Think of it as the instructions you'd need to supply to a VM to fully deploy
your application (but not its supporting services). You might need to install a JVM or perform a build.

## Installing Docker (single host)

Due to the excessive amount of bandwidth you'll need to build Docker containers, it's generally a good idea to use a remote
instance to do the work. Developer machines are OK but don't lend themselves to consistent environments and having an EC2
instance available means you can work in coffee shops, trains etc.

It's assumed that you've already got a clean instance of Ubuntu 16.04 LTS or similar and have just opened a shell:
 
### Install `docker-engine` and `docker-compose`

Always go for the latest version you can, and refer to the Docker website in case of difficulties.

#### Install on Ubuntu

```
sudo apt-get update

sudo apt-get install apt-transport-https ca-certificates

sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D

echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" | sudo tee /etc/apt/sources.list.d/docker.list

sudo apt-get update

# Verify repository
apt-cache policy docker-engine

sudo apt-get update

sudo apt-get install linux-image-extra-$(uname -r) linux-image-extra-virtual

# Install Docker engine (require 1.12+)
sudo apt-get install docker-engine

# Install Docker Compose (require 1.8.1+)
sudo curl -o /usr/local/bin/docker-compose -L "https://github.com/docker/compose/releases/download/1.8.1/docker-compose-$(uname -s)-$(uname -m)"
sudo chmod +x /usr/local/bin/docker-compose

# Start daemon
sudo service docker start

# Set up Docker user
sudo groupadd docker
sudo gpasswd -a ${USER} docker
sudo service docker restart
newgrp docker

# Verify (expect pleasant messages)
sudo docker run hello-world
``` 

#### Install on OS X

```
# Install Cask
brew install caskroom/cask/brew-cask

# Install docker toolbox
brew cask install docker docker-toolbox

# Create the docker machine (use "default" to support common options)
docker-machine create -d virtualbox --virtualbox-memory 4096 default

# Start the docker machine
docker-machine start default

# This command allows the docker commands to be used in the terminal
eval "$(docker-machine env default)"

```

### Install Meteor, Node, `npm`

```
curl https://install.meteor.com/ | sh
sudo apt-get install nodejs npm
```

### Install Gradle

```
sudo apt-get install gradle
```

## Build the Docker image

Each project comes with its own `./docker-build.sh` that will clean and build the image. Just run
it to create your Docker image appropriately tagged. If you need to make your own, just copy what's
already there and modify.

### Special requirements on OSX

You may need to run some extra commands on OSX

```
docker-machine start default
eval "$(docker-machine env default)"
```

### Run up your containers

Docker Compose builds your complete network consisting of multiple linked containers.
```
docker-compose up &
```

The `Dockerfile` exposes the application ports, and `docker-compose.yml` provides a mapping
between the host machine (your EC2 instance) and the running Docker container so that, say, 
Docker port 3000 is mapped to host port 80. Therefore you get to see your application's output 
in your browser.

The `docker-compose.yml` also contains information for tagging your images to make them easier to
push to an upstream repository (such as Docker Hub).

### Stop your containers

Docker Compose will also ensure all containers are shut down gracefully.
```
docker-compose stop
```

## Docker environment management (single host)

Here are some useful Docker commands to keep your build environment from getting out of control.
Images tend to be quite large so you can run out of space quickly if you're a busy bee.

* List all Docker processes:
```
docker ps -a 
```
* Remove single image:
```
docker rmi --force <imageId>
```
 
* Remove *all* containers: 
```
docker ps -a | sed '1 d' | awk '{print $1}' | xargs -L1 docker rm
```
* Remove *all* images:
```
docker images -a | sed '1 d' | awk '{print $3}' | xargs -L1 docker rmi -f
```

Please refer to the Docker Swarm information for using Docker at scale with multiple host machines.