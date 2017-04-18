#!/bin/bash
# Docker compose mode using single VM
# Use the --force option to create the VM
echo "<===================================================================================================>"

if [[ "$1" = "--force" ]]; then
	echo "======> Building VM 'default'..."
  docker-machine create --driver virtualbox --virtualbox-memory 4096 default
fi

	echo "======> Applying Docker Compose to 'default'..."
export DEFAULT_IP=$(docker-machine ip default)
docker-compose up
