#!/bin/bash

name="miner-update"
service=$(cat /var/dashboard/services/$name | tr -d '\n')
version=$(cat /var/dashboard/statuses/latest_miner_version | tr -d '\n')
pantherx_ver=$(cat /var/dashboard/statuses/pantherx_ver)

if [[ "$pantherx_ver" = "X1" ]]; then
    miner_data_path="/opt/miner_data"
elif [[ "$pantherx_ver" = "X2" ]]; then
    miner_data_path="/opt/panther-x2/miner_data"
fi

# Fix invalid status when boot finish
if [ "$service" = 'running' ]; then
  if [ ! -f /tmp/dashboard-$name-flag ]; then
    echo 'stopped' > /var/dashboard/services/$name
  fi
fi

if [ "$service" = 'start' ]; then
  touch /tmp/dashboard-$name-flag
  echo 'running' > /var/dashboard/services/$name
  echo 'Stopping currently running docker...' > /var/dashboard/logs/$name.log
  docker stop helium-miner >> /var/dashboard/logs/$name.log 2>&1
  docker rm helium-miner >> /var/dashboard/logs/$name.log 2>&1

  echo 'Acquiring and starting latest docker version...' >> /var/dashboard/logs/$name.log
  docker image pull quay.io/team-helium/miner:$version >> /var/dashboard/logs/$name.log 2>&1
  mkdir -p ${miner_data_path}/log

  # Copy settings file if it doesn't exist
  [ ! -f /root/helium/overlay/settings.toml ] && cp -f /var/dashboard/config/settings.toml /root/helium/overlay/settings.toml

  # Start the new container
  docker run -d --init --restart always \
    --env GW_KEYPAIR=ecc://i2c-1:96?slot=0 \
    --env GW_API=0.0.0.0:4467 \
    --publish 127.0.0.1:1680:1680/udp \
    --publish 127.0.0.1:4467:4467/tcp \
    --device /dev/i2c-1 --privileged \
    -v /etc/timezone:/etc/timezone:ro \
    -v /etc/localtime:/etc/localtime:ro \
    --name helium-miner \
    --mount type=bind,source=/root/helium/overlay/settings.toml,target=/etc/helium_gateway/settings.toml \
    quay.io/team-helium/miner:$version >> /var/dashboard/logs/$name.log 2>&1

  if [ $? -eq 0 ]; then
    echo 'Container started successfully.'
    echo 'running' > /var/dashboard/services/$name
    echo $version > /var/dashboard/statuses/current_miner_version
    echo "DISTRIB_RELEASE=$(echo $version | sed -e 's/gateway-//')" > /etc/lsb_release
    echo 'Update complete.' >> /var/dashboard/logs/$name.log
  else
    echo 'Miner docker failed to start. Check logs to investigate.'
    echo 'stopped' > /var/dashboard/services/$name
  fi
fi
