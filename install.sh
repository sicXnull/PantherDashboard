#!/bin/bash
rm /tmp/latest.tar.gz
bash /var/dashboard/uninstall.sh

if test -f /var/dashboard/branch; then
  BRANCH=$(cat /var/dashboard/branch)
else
  BRANCH='stock-firmware'
fi

if id -nG admin | grep -qw "sudo"; then
    LATEST_COMMIT=$(curl -s https://api.github.com/repos/sicXnull/PantherDashboard/git/refs/heads/${BRANCH} | jq -r '.object.sha')
    wget https://github.com/sicXnull/PantherDashboard/archive/${LATEST_COMMIT}.tar.gz -O /tmp/latest.tar.gz
    cd /tmp
    if test -s latest.tar.gz; then
      rm -rf /tmp/PantherDashboard-*
	  
	  mkdir -p /tmp/PantherDashboard
    
      tar -xzf latest.tar.gz -C /tmp/PantherDashboard --strip-components=1
      cd PantherDashboard
      apt-get update
      apt-get --assume-yes install nginx php-fpm php7.3-fpm ngrep gawk php-cli logrotate netcat jq

      # Remove it first if the /var/dashboard is invalid
      if test -e /var/dashboard; then
        rm -f /var/dashboard
      fi
      mkdir -p /var/dashboard
      mkdir -p /var/dashboard/logs
      mkdir -p /etc/monitor-scripts
      mkdir -p /var/log/packet-forwarder/
      mkdir -p /opt/panther-x2/miner_data/
      mkdir -p /root/helium/overlay


      cp -r dashboard/* /var/dashboard/
      cp version /var/dashboard/
      cp monitor-scripts/* /etc/monitor-scripts/
      cp -r logrotate.d/* /etc/logrotate.d/
       
      cp nginx/snippets/* /etc/nginx/snippets/
      cp nginx/default /etc/nginx/sites-enabled
      cp settings/* /root/helium/overlay
    
      if ! test -f /var/dashboard/.htpasswd; then
        cp nginx/.htpasswd /var/dashboard/.htpasswd
      fi

      [ -f /etc/sudoers.d/www-data ] && rm -f /etc/sudoers.d/www-data
      if ! test -f /etc/sudoers.d/www-data; then
        sh -c 'echo www-data ALL=\(ALL\) NOPASSWD: /etc/monitor-scripts/helium-miner-log.sh > /etc/sudoers.d/www-data'
        sh -c 'echo www-data ALL=\(ALL\) NOPASSWD: /etc/monitor-scripts/first-load.sh >> /etc/sudoers.d/www-data'
      fi

      # Check if the DH parameters file already exists
	if [ ! -f /etc/ssl/certs/dhparam.pem ]; then
		openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
	fi

	# Check if the self-signed certificate and key files already exist
	if [ ! -f /etc/ssl/certs/nginx-selfsigned.crt ] || [ ! -f /etc/ssl/private/nginx-selfsigned.key ]; then
		openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -subj "/C=CN/ST=Panther/L=Panther/O=Panther/CN=localhost" -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt
	fi
    
      cp systemd/* /etc/systemd/system/

      chmod 755 /etc/monitor-scripts/*
      chown root:www-data /var/dashboard/services/*
      chown root:www-data /var/dashboard/statuses/*
      chmod 775 /var/dashboard/services/*
      chmod 775 /var/dashboard/statuses/*
      chown root:root /etc/ssl/private/nginx-selfsigned.key
      chmod 600 /etc/ssl/private/nginx-selfsigned.key
      chown root:root /etc/ssl/certs/nginx-selfsigned.crt
      chmod 777 /etc/ssl/certs/nginx-selfsigned.crt
      chown root:www-data /var/dashboard/.htpasswd
      chmod 775 /var/dashboard/.htpasswd
      chown root:www-data /var/dashboard
      chmod 775 /var/dashboard
      chmod 775 /var/dashboard/logs
	  systemctl daemon-reload
	  
	  
      if [ condition ]; then
          bash /etc/monitor-scripts/pantherx-ver-check.sh
          FILES="systemd/*.timer"
          for f in $FILES;
          do
             name=$(echo $f | sed 's/.timer//' | sed 's/systemd\///')
             systemctl start $name.timer
             systemctl enable $name.timer
             systemctl start $name.service
          done

          systemctl daemon-reload
          systemctl enable packet-forwarder-sniffer.service
          systemctl start packet-forwarder-sniffer.service

          systemctl enable nginx
          systemctl restart nginx
          bash /etc/monitor-scripts/pubkeys.sh

          echo 'Success.'
      elif [ another_condition ]; then
          echo 'No installation archive found.  No changes made.'
      else
          echo 'Error checking if admin user exists.  No changes made.'
      fi
    else
      echo 'No installation archive found.  No changes made.'
    fi
else
    echo 'Error checking if admin user exists.  No changes made.'
fi
