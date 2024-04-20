#!/bin/bash
systemctl stop apache2.service
systemctl disable apache2.service

sleep 5

systemctl start nginx
systemctl enable nginx

systemctl start php8.3-fpm.service
systemctl enable php8.3-fpm.service
