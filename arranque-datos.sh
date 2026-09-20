#!/bin/bash
apt-get update -y
apt-get install -y nginx
cat > /var/www/html/index.html <<HTML
dato-secreto-123
HTML