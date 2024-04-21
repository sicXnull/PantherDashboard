#!/bin/bash

# Check if the Docker container crankk exists
if docker ps -a --format '{{.Names}}' | grep -q "^crankk$"; then
    echo "Container 'crankk' exists."
    
    # Check if the Docker container crankk is running
    if docker ps --format '{{.Names}}' | grep -q "^crankk$"; then
        echo "Container 'crankk' is running. No action needed."
    else
        echo "Container 'crankk' is stopped. Removing container..."
        # Remove the stopped container named 'crankk'
        docker rm crankk
    fi
else
    echo "Container 'crankk' does not exist. Creating and starting container..."
    docker run --name crankk --network host --privileged --restart always \
               -v /data:/crankk_data -v /:/host crankkster/crankk
fi
