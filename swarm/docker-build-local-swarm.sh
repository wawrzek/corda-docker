#!/bin/bash
# Swarm mode using Docker Machine
# Use the --force option to create the VMs as well
managers=1
workers=12
stackName=corda-swift

if [[ "$1" = "--force" ]]; then
	echo "<===================================================================================================>"

	echo "======> Graceful shutdown..."
	# Gracefully stop and remove existing machines
	echo -e "\n======> Removing existing managers and workers ..."
	docker-machine ls | grep 'manager\|worker' | awk '{print $1}' | xargs -L1 docker-machine stop
	docker-machine ls | grep 'manager\|worker' | awk '{print $1}' | xargs -L1 docker-machine rm --f

	echo "<===================================================================================================>"

	# Create manager machines
	echo "======> Creating $managers manager machines ..."
	for node in $(seq 1 ${managers})
	do
	echo "======> Creating manager$node machine ..."
	docker-machine create --driver virtualbox --virtualbox-memory 1024 manager${node}
	done

	# Create worker machines
	echo "======> Creating $workers worker machines ..."
	for node in $(seq 1 ${workers})
	do
	echo "======> Creating worker$node machine ..."
	docker-machine create -d virtualbox --virtualbox-memory 768 worker${node};
	done

	# Initialize swarm mode with manager1
	echo "======> Initializing swarm through manager1 ..."
	docker-machine ssh manager1 "docker swarm init --listen-addr $(docker-machine ip manager1) --advertise-addr $(docker-machine ip manager1)"

	# Get manager and worker tokens
	export manager_token=`docker-machine ssh manager1 "docker swarm join-token manager -q"`
	export worker_token=`docker-machine ssh manager1 "docker swarm join-token worker -q"`
	echo "manager_token: $manager_token"
	echo "worker_token: $worker_token"

	# Add other managers to swarm if necessary
	if (($managers > 1)); then
		for node in $(seq 2 ${managers})
		do
		echo "======> manager$node joining swarm as manager ..."
		docker-machine ssh manager${node} \
		"docker swarm join \
		--token $manager_token \
		--listen-addr $(docker-machine ip manager${node}) \
		--advertise-addr $(docker-machine ip manager${node}) \
		$(docker-machine ip manager1)"
		done
	fi

	# Workers join swarm
	for node in $(seq 1 ${workers})
	do
	echo "======> worker$node joining swarm as worker ..."
	docker-machine ssh worker${node} \
	"docker swarm join \
	--token $worker_token \
	--listen-addr $(docker-machine ip worker${node}) \
	--advertise-addr $(docker-machine ip worker${node}) \
	$(docker-machine ip manager1):2377"
	done
fi

# Show members of swarm
echo "======> List of nodes ..."
docker-machine ssh manager1 "docker node ls"

echo "======> Applying Docker Swarm to 'manager1'..."
eval $(docker-machine env manager1)

if [[ "$1" != "--force" ]]; then
	echo "<===================================================================================================>"

	echo "======> Clean up..."
	echo "=========> Swarm services..."
	docker service rm ${stackName}_proxy
	docker service rm ${stackName}_swarm-listener
	docker service rm ${stackName}_example

	echo "=========> Support services..."
	docker service rm elasticsearch
	docker service rm logstash
	docker service rm logspout
	docker service rm kibana

	echo "=========> Swarm networks..."
	docker network rm ${stackName}_proxy

	echo "=========> Support networks..."
	docker network rm elk

	# Provide time for the clean up to complete
	sleep 3

fi

echo "<===================================================================================================>"

echo "======> Creating swarm..."
# Copy manager1 IP as environment variable for use with Swarm deploy later
MANAGER_IP=$(docker-machine ip manager1)
# Copy login credentials to manager1
docker-machine scp -r $HOME/.docker/config.json manager1:/home/docker/.docker
# Copy Docker Compose stack configuration to manager1
docker-machine scp ./docker-compose-stack.yml manager1:/home/docker/docker-compose-stack.yml
# Deploy the Swarm using current "docker login" credentials
docker-machine ssh manager1 "env MANAGER_IP=$MANAGER_IP docker stack deploy --with-registry-auth -c docker-compose-stack.yml $stackName"

# Provide time for stack deployment to start
sleep 3

echo "<===================================================================================================>"

# Add local centralised logging with ELK using the primary manager
# Typically this is provided in the cloud so isn't part of stack configuration
echo "======> Installing local ELK services..."
# Require overlay network for ELK machines to see all nodes
docker network create --driver overlay elk

# Install Elasticsearch as a service
echo "=========> Installing Elasticsearch..."
docker service create --name elasticsearch \
		--network elk \
		--reserve-memory 500m \
		elasticsearch:2.4

# Install LogStash to parse node logs for Elasticsearch
echo "=========> Installing LogStash..."
# Use project LogStash configuration (./docker/logstash.conf)
docker service create --name logstash \
		--network elk \
		--mount "type=bind,source=$PWD/docker,target=/conf" \
		-e LOGSPOUT=ignore \
		--reserve-memory 100m \
		logstash:2.4 \
		logstash -f /conf/logstash.conf

# Install LogSpout to extract node logs to LogStash (ignoring LogStash itself)
echo "=========> Installing LogSpout..."
docker service create --name logspout \
    --network elk --network ${stackName}_corda \
    --mode global \
    --mount "type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock" \
    -e SYSLOG_FORMAT=rfc3164 \
		gliderlabs/logspout \
		syslog://logstash:51415

# Install Kibana to provide UI to Elasticsearch for debugging nodes
echo "=========> Installing Kibana..."
docker service create --name kibana \
		--network elk --network ${stackName}_proxy \
		-e ELASTICSEARCH_URL=http://elasticsearch:9200 \
		--reserve-memory 50m \
		--label com.df.notify=true \
		--label com.df.distribute=true \
		--label com.df.servicePath=/app/kibana,/status,/bundles,/elasticsearch \
		--label com.df.port=5601 \
		kibana:4.6

echo "<===================================================================================================>"

docker service ls

echo "======> Opening Kibana..."
open "http://$(docker-machine ip manager1)/app/kibana"

echo "<===================================================================================================>"

echo "Use 'eval \$(docker-machine env manager1); watch docker stack ps --no-trunc example-stack' to monitor swarm progress."
echo "Expect around 5 minutes on single machine for all workers to be provisioned and running."
echo "Done."