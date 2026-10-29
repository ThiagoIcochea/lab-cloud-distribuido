#!/usr/bin/env bash
# Autor: Thiago Paolo Icochea Rodriguez · github.com/ThiagoIcochea
source "$(dirname "$0")/../config.sh"
titulo "Eliminando lab de monitoreo"
gcloud compute instances delete "${PREFIJO}-monitor" --zone="${ZONE}" --quiet || true
gcloud compute firewall-rules delete "${PREFIJO}-allow-iap-monitor" --quiet || true
for u in $(gcloud monitoring uptime list-configs --filter="displayName=${PREFIJO}-web-uptime" --format="value(name)" 2>/dev/null); do
  gcloud monitoring uptime delete "$u" --quiet || true
done
for d in $(gcloud monitoring dashboards list --filter='displayName="Lab · Monitoreo de infraestructura"' --format="value(name)" 2>/dev/null); do
  gcloud monitoring dashboards delete "$d" --quiet || true
done
