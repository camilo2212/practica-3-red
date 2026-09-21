#!/bin/bash
apt-get update -y
apt-get install -y nginx

sed -i 's/80 default_server/8080 default_server/g' /etc/nginx/sites-available/default
INTERNA=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)
echo "Registro servido por $(hostname) (IP interna $INTERNA)" > /var/www/html/index.html
systemctl restart nginx