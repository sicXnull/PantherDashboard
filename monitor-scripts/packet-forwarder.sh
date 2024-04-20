#!/bin/bash

# Check if the Docker container "crankk-pktfwd" is running
if ! docker ps | grep -q "crankk-pktfwd"; then
    # If the container is not running, make the file blank
    > /var/dashboard/statuses/packet-forwarder
else
    # If the container is running, copy the log to the status file
    sudo cat /var/log/packet-forwarder/packet_forwarder.log > /var/dashboard/statuses/packet-forwarder
fi
