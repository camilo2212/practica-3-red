#!/bin/bash
#!/bin/bash
INTERNA=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)

cat > /opt/app.py <<PY
from http.server import BaseHTTPRequestHandler, HTTPServer
import urllib.request

DATOS = "http://${ip_datos}:8080/"

class App(BaseHTTPRequestHandler):
    def do_GET(self):
        try:
            dato = urllib.request.urlopen(DATOS, timeout=3).read().decode()
        except Exception as e:
            self.send_response(503)
            self.end_headers()
            self.wfile.write(f"La maquina de datos no responde: {e}".encode())
            return
        html = (f"<h1><tu identificación></h1>"
                f"<p>Servidor de aplicación. IP interna: $INTERNA</p>"
                f"<p>Dato de la máquina privada: {dato}</p>")
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.end_headers()
        self.wfile.write(html.encode())

HTTPServer(("", 80), App).serve_forever()
PY

cat > /etc/systemd/system/app.service <<'UNIT'
[Unit]
Description=Aplicacion
After=network-online.target
[Service]
ExecStart=/usr/bin/python3 /opt/app.py
Restart=always
[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now app