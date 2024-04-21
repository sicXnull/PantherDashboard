#!/bin/bash

# Check if the Docker container "crankk-pktfwd" is running
if ! docker ps | grep -q "crankk-pktfwd"; then
    > /var/dashboard/statuses/packet-forwarder
else
    echo "1" > /var/dashboard/statuses/packet-forwarder
fi
