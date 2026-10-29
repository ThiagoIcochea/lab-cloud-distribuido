#!/usr/bin/env bash
# Autor: Thiago Paolo Icochea Rodriguez · github.com/ThiagoIcochea
source "$(dirname "$0")/../config.sh"
titulo "Eliminando lab de redes"
gcloud compute instances delete "${PREFIJO}-web" "${PREFIJO}-app" --zone="${ZONE}" --quiet || true
gcloud compute routers nats delete "${PREFIJO}-nat" --router="${PREFIJO}-router" --region="${REGION}" --quiet || true
gcloud compute routers delete "${PREFIJO}-router" --region="${REGION}" --quiet || true
for r in http iap-ssh web-app; do gcloud compute firewall-rules delete "${PREFIJO}-allow-${r}" --quiet || true; done
gcloud compute networks subnets delete "${PREFIJO}-publica" "${PREFIJO}-privada" --region="${REGION}" --quiet || true
gcloud compute networks delete "${PREFIJO}-vpc" --quiet || true
