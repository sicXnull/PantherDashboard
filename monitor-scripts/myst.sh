#!/bin/bash

# Check if the Docker container myst exists
if docker ps -a --format '{{.Names}}' | grep -q "^myst$"; then
    echo "Container 'myst' exists."
    
    # Check if the Docker container myst is running
    if docker ps --format '{{.Names}}' | grep -q "^myst$"; then
        echo "Container 'myst' is running. No action needed."
        exit 0
    else
        echo "Container 'myst' is stopped. Removing container..."
        docker rm myst
        exit $?
    fi
else
    echo "Container 'myst' does not exist. Creating and starting container..."
    docker run --cap-add NET_ADMIN -d -p 4449:4449 --name myst \
               -v /opt/myst:/var/lib/mysterium-node --restart unless-stopped \
               mysteriumnetwork/myst:latest service --agreed-terms-and-conditions
    exit $?
fi