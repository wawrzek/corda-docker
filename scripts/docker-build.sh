#!/usr/bin/env bash

# Build with Gradle
gradle clean shadowJar

# Build the containers using the resident VM (default)
docker-compose build

# Open the default browser to view the app
#open "http://$(docker-machine ip default)"
