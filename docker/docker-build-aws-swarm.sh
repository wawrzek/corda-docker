#!/bin/bash
# Get this from the EC2 Connect window for the Manager in zone 1a
awsHost=ec2-1-2-3-4.eu-west-1.compute.amazonaws.com
# Get this from the CloudFormation Outputs for the cluster (all lowercase!)
stackDns=example.eu-west-1.elb.amazonaws.com
# Get this from the CloudFormation main page
stackName=example-stack

# SSH does not support environment variables so must use token replacement via sed
echo "Processing docker-compose-stack.yml (MANAGER_IP etc)..."
sed -e "s/\${MANAGER_IP}/${stackDns}/g" docker-compose-stack.yml > docker-compose-stack.yml.tmp
scp -i "~/.ssh/lab2-eu-west1-kp.pem" docker-compose-stack.yml.tmp docker@${awsHost}:~/docker-compose-stack.yml
rm -f docker-compose-stack.yml.tmp

echo "Deploy baseline swarm (network mapper, notary etc) - requires 'docker login' on manager..."
ssh -i "~/.ssh/example-eu-west1-kp.pem" docker@${awsHost} \
 "docker stack deploy --with-registry-auth -c docker-compose-stack.yml ${stackName}"

echo "Done"
