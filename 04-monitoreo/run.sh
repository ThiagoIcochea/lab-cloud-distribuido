#!/usr/bin/env bash
# Autor: Thiago Paolo Icochea Rodriguez · github.com/ThiagoIcochea
# Lab 4 · Orquestación y monitoreo: Cloud Monitoring (uptime check + dashboard) y pila abierta
# Prometheus + Grafana, aplicable a AWS, Azure y nube privada. Requiere el Lab 3 (VM web).
source "$(dirname "$0")/../config.sh"
D="$(cd "$(dirname "$0")" && pwd)"
WEB_IP=$(gcloud compute instances describe "${PREFIJO}-web" --zone="${ZONE}" \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)' 2>/dev/null || true)
[[ -z "${WEB_IP}" ]] && { echo "Primero ejecuta 03-redes/run.sh" >&2; exit 1; }

titulo "Cloud Monitoring: uptime check sobre http://${WEB_IP}/"
gcloud monitoring uptime list-configs --format="value(displayName)" 2>/dev/null | grep -qx "${PREFIJO}-web-uptime" || \
  gcloud monitoring uptime create "${PREFIJO}-web-uptime" --resource-type=uptime-url \
    --resource-labels="host=${WEB_IP},project_id=${PROJECT_ID}" --protocol=http --port=80 --path=/ --period=1
titulo "Cloud Monitoring: dashboard de infraestructura"
gcloud monitoring dashboards list --format="value(displayName)" | grep -qx "Lab · Monitoreo de infraestructura" || \
  gcloud monitoring dashboards create --config-from-file="${D}/dashboard-cloud-monitoring.json"

titulo "Pila Prometheus + Grafana en la VM ${PREFIJO}-monitor"
TMP=$(mktemp -d); cp -r "${D}/docker-compose.yml" "${D}/grafana" "${TMP}/"
sed "s/WEB_IP/${WEB_IP}/" "${D}/prometheus.yml.tpl" > "${TMP}/prometheus.yml"
tar -czf "${TMP}/stack.tgz" -C "${TMP}" docker-compose.yml prometheus.yml grafana
base64 -w0 "${TMP}/stack.tgz" > "${TMP}/stack.b64"
gcloud compute firewall-rules describe "${PREFIJO}-allow-iap-monitor" >/dev/null 2>&1 || \
  gcloud compute firewall-rules create "${PREFIJO}-allow-iap-monitor" --network="${PREFIJO}-vpc" \
    --allow=tcp:22,tcp:3000,tcp:9090 --source-ranges=35.235.240.0/20 --target-tags=monitor
gcloud compute instances describe "${PREFIJO}-monitor" --zone="${ZONE}" >/dev/null 2>&1 || \
  gcloud compute instances create "${PREFIJO}-monitor" --zone="${ZONE}" --machine-type=e2-medium \
    --subnet="${PREFIJO}-privada" --no-address --tags=monitor \
    --image-family=debian-12 --image-project=debian-cloud \
    --metadata-from-file=stack="${TMP}/stack.b64" \
    --metadata=startup-script='#!/bin/bash
set -e
command -v docker >/dev/null || { apt-get update -y; apt-get install -y docker.io docker-compose; }
mkdir -p /opt/monitoreo && cd /opt/monitoreo
curl -s -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/attributes/stack" | base64 -d | tar -xz
docker-compose up -d'
echo
echo "La VM de monitoreo no tiene IP pública. Para ver Grafana desde Cloud Shell (tarda ~3 min en arrancar):"
echo "  gcloud compute start-iap-tunnel ${PREFIJO}-monitor 3000 --local-host-port=localhost:8080 --zone ${ZONE}"
echo "  y abre 'Vista previa en la Web' → puerto 8080 (dashboard 'Monitoreo multinube')."
echo "Dashboard de Cloud Monitoring: https://console.cloud.google.com/monitoring/dashboards?project=${PROJECT_ID}"
