cat > arranque-datos.sh << 'EOF'
#!/bin/bash
apt-get update -y
apt-get install -y nginx
FECHA=$(date)
cat > /var/www/html/index.html <<HTML
dato-secreto-123 generado el: $FECHA
HTML
EOF