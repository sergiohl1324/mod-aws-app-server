#!/bin/bash
set -euxo pipefail
exec > >(tee /var/log/user-data.log) 2>&1
export DEBIAN_FRONTEND=noninteractive

echo "=== POC App Server bootstrap ==="

apt-get update -y
apt-get install -y nginx

mkdir -p /var/www/poc

cat > /var/www/poc/index.html <<'HTML'
<!DOCTYPE html>
<html>
<head><title>${title}</title></head>
<body>
  <h1>${title}</h1>
  <p>${message}</p>
  <p>Served via: %{ if enable_uwsgi }nginx + uWSGI%{ else }nginx static%{ endif }</p>
  <p>Host: $(hostname)</p>
</body>
</html>
HTML

%{ if enable_uwsgi }
echo "=== Modo uWSGI: compilando e instalando uWSGI ==="
apt-get install -y build-essential python3-dev python3-venv

mkdir -p /opt/poc-app
python3 -m venv /opt/poc-app/venv
/opt/poc-app/venv/bin/pip install --upgrade pip
/opt/poc-app/venv/bin/pip install uwsgi

cat > /opt/poc-app/app.py <<'PYAPP'
def application(environ, start_response):
    start_response('200 OK', [('Content-Type', 'text/html')])
    with open('/var/www/poc/index.html', 'rb') as f:
        return [f.read()]
PYAPP

cat > /opt/poc-app/uwsgi.ini <<'UWSGICFG'
[uwsgi]
chdir = /opt/poc-app
module = app:application
master = true
processes = 2
socket = /run/uwsgi/app.sock
chmod-socket = 666
vacuum = true
die-on-term = true
UWSGICFG

cat > /etc/systemd/system/uwsgi.service <<'UNIT'
[Unit]
Description=uWSGI instance for POC app
After=network.target

[Service]
User=www-data
Group=www-data
RuntimeDirectory=uwsgi
WorkingDirectory=/opt/poc-app
ExecStart=/opt/poc-app/venv/bin/uwsgi --ini /opt/poc-app/uwsgi.ini
Restart=always

[Install]
WantedBy=multi-user.target
UNIT

cat > /etc/nginx/sites-available/default <<'NGINXCFG'
server {
    listen 80 default_server;

    location / {
        include uwsgi_params;
        uwsgi_pass unix:///run/uwsgi/app.sock;
    }
}
NGINXCFG

systemctl daemon-reload
systemctl enable --now uwsgi
%{ else }
echo "=== Modo estatico: nginx sirve el HTML directamente ==="
cat > /etc/nginx/sites-available/default <<'NGINXCFG'
server {
    listen 80 default_server;
    root /var/www/poc;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
NGINXCFG
%{ endif }

systemctl restart nginx
systemctl enable nginx

echo "=== Bootstrap completo ==="
