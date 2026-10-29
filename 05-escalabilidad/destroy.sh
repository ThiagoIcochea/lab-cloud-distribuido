#!/usr/bin/env bash
# Autor: Thiago Paolo Icochea Rodriguez · github.com/ThiagoIcochea
source "$(dirname "$0")/../config.sh"
titulo "Eliminando lab de escalabilidad"
gcloud compute instance-groups managed delete "${PREFIJO}-esc-mig" --zone="${ZONE}" --quiet || true
gcloud compute instance-templates delete "${PREFIJO}-esc-tpl" --quiet || true
gcloud compute instances delete "${PREFIJO}-vertical" --zone="${ZONE}" --quiet || true
gcloud compute firewall-rules delete "${PREFIJO}-esc-allow-http" "${PREFIJO}-esc-allow-iap" --quiet || true
