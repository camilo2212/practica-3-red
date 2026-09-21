cat > arranque.sh << 'EOF'
#!/bin/bash
apt-get update -y
apt-get install -y nginx
INTERNA=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)
DATO=$(curl -s -m 5 http://${ip_datos})
cat > /var/www/html/index.html <<HTML
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"></head>
<body>
<h1>ali - juancamiloum</h1>
<p>Servidor de aplicación. IP interna: $INTERNA</p>
<p>Dato desde la máquina privada: $DATO</p>
</body>
</html>
HTML
EOF