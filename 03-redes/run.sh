#!/usr/bin/env bash
# Autor: Thiago Paolo Icochea Rodriguez · github.com/ThiagoIcochea
# Lab 3 · Redes privadas y públicas: VPC con subred pública (web) y privada (app interna), firewall, IAP y Cloud NAT.
source "$(dirname "$0")/../config.sh"
VPC="${PREFIJO}-vpc"
titulo "VPC ${VPC} en modo personalizado"
gcloud compute networks describe "${VPC}" >/dev/null 2>&1 || gcloud compute networks create "${VPC}" --subnet-mode=custom
gcloud compute networks subnets describe "${PREFIJO}-publica" --region="${REGION}" >/dev/null 2>&1 || \
  gcloud compute networks subnets create "${PREFIJO}-publica" --network="${VPC}" --region="${REGION}" --range=10.10.1.0/24
gcloud compute networks subnets describe "${PREFIJO}-privada" --region="${REGION}" >/dev/null 2>&1 || \
  gcloud compute networks subnets create "${PREFIJO}-privada" --network="${VPC}" --region="${REGION}" --range=10.10.2.0/24 \
    --enable-private-ip-google-access

titulo "Reglas de firewall (denegación por defecto + flujos permitidos)"
fw() { gcloud compute firewall-rules describe "$1" >/dev/null 2>&1 || gcloud compute firewall-rules create "$@"; }
fw "${PREFIJO}-allow-http"     --network="${VPC}" --allow=tcp:80   --source-ranges=0.0.0.0/0        --target-tags=web
fw "${PREFIJO}-allow-iap-ssh"  --network="${VPC}" --allow=tcp:22   --source-ranges=35.235.240.0/20  --target-tags=web,app
fw "${PREFIJO}-allow-web-app"  --network="${VPC}" --allow=tcp:8080 --source-tags=web                --target-tags=app

titulo "Cloud Router + Cloud NAT (salida a Internet de la subred privada sin IP pública)"
gcloud compute routers describe "${PREFIJO}-router" --region="${REGION}" >/dev/null 2>&1 || \
  gcloud compute routers create "${PREFIJO}-router" --network="${VPC}" --region="${REGION}"
gcloud compute routers nats describe "${PREFIJO}-nat" --router="${PREFIJO}-router" --region="${REGION}" >/dev/null 2>&1 || \
  gcloud compute routers nats create "${PREFIJO}-nat" --router="${PREFIJO}-router" --region="${REGION}" \
    --nat-custom-subnet-ip-ranges="${PREFIJO}-privada" --auto-allocate-nat-external-ips

titulo "VM interna (subred privada, sin IP pública)"
gcloud compute instances describe "${PREFIJO}-app" --zone="${ZONE}" >/dev/null 2>&1 || \
  gcloud compute instances create "${PREFIJO}-app" --zone="${ZONE}" --machine-type=e2-small \
    --subnet="${PREFIJO}-privada" --private-network-ip=10.10.2.10 --no-address --tags=app \
    --image-family=debian-12 --image-project=debian-cloud --shielded-secure-boot \
    --metadata=startup-script='#!/bin/bash
mkdir -p /srv/app
echo "{\"servicio\":\"aplicacion interna\",\"red\":\"privada 10.10.2.0/24\",\"host\":\"$(hostname)\"}" > /srv/app/index.html
cat >/etc/systemd/system/app-interna.service <<UNIT
[Unit]
Description=Aplicacion interna de prueba
After=network-online.target
[Service]
WorkingDirectory=/srv/app
ExecStart=/usr/bin/python3 -m http.server 8080
Restart=always
[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload && systemctl enable --now app-interna'

titulo "VM web (subred pública, con IP externa) como proxy inverso hacia la app interna"
gcloud compute instances describe "${PREFIJO}-web" --zone="${ZONE}" >/dev/null 2>&1 || \
  gcloud compute instances create "${PREFIJO}-web" --zone="${ZONE}" --machine-type=e2-small \
    --subnet="${PREFIJO}-publica" --private-network-ip=10.10.1.10 --tags=web \
    --image-family=debian-12 --image-project=debian-cloud --shielded-secure-boot \
    --metadata=startup-script='#!/bin/bash
apt-get update -y && apt-get install -y nginx
cat >/etc/nginx/sites-available/default <<CONF
server {
  listen 80 default_server;
  location /interno/ { proxy_pass http://10.10.2.10:8080/; }
  location / { default_type text/plain; return 200 "Servicio web publico (subred 10.10.1.0/24)\n"; }
}
CONF
systemctl restart nginx'

IP=$(gcloud compute instances describe "${PREFIJO}-web" --zone="${ZONE}" --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
titulo "Comprobando (la VM web tarda ~1 min en instalar nginx)"
for _ in $(seq 1 30); do curl -s -m 5 "http://${IP}/" && break; sleep 10; done
curl -s -m 5 "http://${IP}/interno/"; echo
echo "Público:  http://${IP}/      ·  Interno a través del proxy: http://${IP}/interno/"
echo "La VM ${PREFIJO}-app NO tiene IP pública: solo se llega desde la subred pública o por IAP:"
echo "  gcloud compute ssh ${PREFIJO}-app --zone ${ZONE} --tunnel-through-iap"
gcloud compute instances list --filter="name~^${PREFIJO}-(web|app)$" \
  --format="table(name,networkInterfaces[0].networkIP:label=IP_INTERNA,networkInterfaces[0].accessConfigs[0].natIP:label=IP_EXTERNA,tags.items.list())"
