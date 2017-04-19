# Deployment with Docker Swarm

Docker Swarm provides a platform-neutral method of deploying many containers to a production grade stack. The 
script includes load balancing and creation of sub-networks with bridges and gateways as required.

[Full documentation can be found on the Docker website](https://docs.docker.com/engine/swarm/)

## Background reading

It is assumed that the reader has familiarity with running Docker locally against a single host machine.

Docker Swarm expands upon the Docker Compose file format (version 3+) and introduces a host of new entries to 
describe how a container is to be deployed and managed in a remote environment. A service is a particular container 
configuration and comes with its own load balancer. This makes it trivial to scale out multiple copies of a service.

Docker Swarm also allows for rapid updating of containers with automatic rollback according to failure rules and 
built-in healthcheck configuration. Therefore it becomes trivial to push a new image to, say, a private Docker 
Hub repository and issue an update command to the running system. Docker Swarm will then manage the process of 
downloading the fresh image and deploying across the network of running services. This gives tremendous leverage to a
 single system administrator who can now easily upgrade thousands of nodes just by issuing a single standard command.
 
A Docker Swarm normally spans multiple host machines, separated into managers and workers. The managers (usually 1,3 
or 5 in number for failover) have access to the low level Docker APIs so can react to events such as nodes entering 
or leaving the system or a service needing to be restarted afresh. The workers are simply there to execute containers. 
Typically there are far more workers than managers in a swarm.
 
## Creating the Swarm (AWS)

Docker Swarm comes with a project called Docker for AWS which provides an AWS JSON template stored in AWS S3. Using 
this template enables a production grade swarm to be created using machine images that are optimised for Docker with
 the latest version of the engine pre-installed. Suitable AWS keys for SSH are attached in line with security groups.
 
This collection of supporting components (security groups, load balancers, virtual networks etc) is called a stack.
 
You will need a local copy of the Lab SSH key (e.g. `~/.ssh/lab2-eu-west1-kp.pem`) to enable SSH access to the 
Manager machines in the stack.
 
### Create the stack

1. Login to AWS using a suitable login account. 

2. Locate the Cloud Formation service from the sidebar/drop down and click "Create Stack"

3. Select the S3 template and supply the Docker for AWS template URL

https://editions-us-east-1.s3.amazonaws.com/aws/stable/Docker.tmpl 

4. Click Next and choose a name for the stack. Keep it short, lowercase and hyphenated (e.g. `corda-swift`).

5. Fill in various fields:

* The number of Managers/Workers you require 
* Enable daily resource clean up
* Select the instance type (t2.micro is good for many low powered services, m4.4xlarge is good for a small number of 
high powered services). For a trial just 1 manager and 2 workers with t2.micro are sufficient (1Gb RAM)
* Defaults in other fields are fine

6. Click Next - for a demo you can ignore these additional configurations
 
7. Click Next - remember to check the box at the foot of the page

8. Click Create - the process can take a while (10-30 minutes) depending on the size of the stack and AWS activity

9. Select the "Outputs" tab and make a note of the "DefaultDNSTarget" for the public DNS to the stack. Copy this to 
your local machine in the `docker-build-aws-swarm.sh` script for this project. Make sure it is all in lowercase in 
the script to avoid DNS issues. You should also enter the swarm name.

10. Use the Managers link in the "Outputs" tab to locate the Managers for your swarm in the EC2 dashboard.

11. Select the Manager in region 1a and click "Connect".

12. Make a note of the public host for SSH connections later.

### Configure the leading manager 

At least one Manager node will need access to the private Docker Hub repository where your images reside. Do the 
following to configure it via an SSH shell:

1. Open an SSH connection to the box, using a command similar to this (note the use of the `docker` user):

```
ssh -i "~/.ssh/user-eu-west1-kp.pem" docker@ec2-1-2-3-4.eu-west-1.compute.amazonaws.com
```

2. Once login is complete, enter the following command to enable access to upstream images from Docker Hub. You 
should create a private repository for your images prior to this.

```
docker login
U: username
P: <the password>
```

### Deploy the Swarm to AWS

Each project comes with its own deployment script for AWS called `docker-build-aws-swarm.sh` where appropriate. 
Simply edit the script with the details from the stack creation process or EC2 connect to allow connectivity. You may
 wish to run a reduced scale deployment for demonstrations, in which case it is generally best to just deploy the 
 components defined in the `docker-compose-swarm.yml` file only. The others are typically to segregate larger scale 
 deployments.

1. Execute the script:

```
./docker-build-aws-swarm.sh
```

2. Switch to the manager shell and observe progress using

```
watch docker stack ps <stack-name>
```

3. Use a browser and navigate to the "DefaultDNSTarget" URL:

```
http://example.eu-west-1.elb.amazonaws.com/
```

### Creating AWS access keys for AWS CLI interaction

If you need to use the AWS CLI you will need to create access keys consisting of an ID and a secret. These will need 
to be held on your local machine and can be generated as follows: 

1. Select your user name in the top-right corner drop down
2. Select "My security credentials"
3. Select "Users" from the sidebar
4. Select your user name
5. Select "Security Credentials" tab
6. Click "Create Access Keys"
7. Click Show to reveal the secret access code - this is only available once
8. Copy both the ID and secret to your local machine (under `~/.ssh`) and protect the file with `chmod 400`
9. Dismiss the dialog

