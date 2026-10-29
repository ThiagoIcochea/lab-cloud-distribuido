#!/usr/bin/env bash
# Autor: Thiago Paolo Icochea Rodriguez · github.com/ThiagoIcochea
# Lab 5 · Escalabilidad horizontal (grupo de instancias con autoescalado + programación de picos)
# y escalabilidad vertical (cambio de tipo de máquina).
source "$(dirname "$0")/../config.sh"
NET="${NET:-default}"
gcloud compute networks describe "${NET}" >/dev/null 2>&1 || gcloud compute networks create "${NET}" --subnet-mode=auto
fw() { gcloud compute firewall-rules describe "$1" >/dev/null 2>&1 || gcloud compute firewall-rules create "$@"; }
fw "${PREFIJO}-esc-allow-http" --network="${NET}" --allow=tcp:80 --source-ranges=0.0.0.0/0 --target-tags=esc
fw "${PREFIJO}-esc-allow-iap"  --network="${NET}" --allow=tcp:22 --source-ranges=35.235.240.0/20 --target-tags=esc

titulo "Plantilla de instancia (nginx + stress-ng)"
gcloud compute instance-templates describe "${PREFIJO}-esc-tpl" >/dev/null 2>&1 || \
  gcloud compute instance-templates create "${PREFIJO}-esc-tpl" --machine-type=e2-small --network="${NET}" --tags=esc \
    --image-family=debian-12 --image-project=debian-cloud \
    --metadata=startup-script='#!/bin/bash
apt-get update -y && apt-get install -y nginx stress-ng
echo "Nodo de streaming: $(hostname)" > /var/www/html/index.html'

titulo "Grupo de instancias administrado con autoescalado horizontal (1 a 5 VM, CPU objetivo 60 %)"
gcloud compute instance-groups managed describe "${PREFIJO}-esc-mig" --zone="${ZONE}" >/dev/null 2>&1 || \
  gcloud compute instance-groups managed create "${PREFIJO}-esc-mig" --zone="${ZONE}" \
    --template="${PREFIJO}-esc-tpl" --size=1
gcloud compute instance-groups managed set-autoscaling "${PREFIJO}-esc-mig" --zone="${ZONE}" \
  --min-num-replicas=1 --max-num-replicas=5 --target-cpu-utilization=0.60 --cool-down-period=60 \
  --scale-in-control=max-scaled-in-replicas=1,time-window=300

titulo "Scheduling: capacidad programada para el evento en vivo (20:00 a 22:00, hora de Lima, mínimo 3 VM)"
gcloud compute instance-groups managed update-autoscaling "${PREFIJO}-esc-mig" --zone="${ZONE}" \
  --set-schedule=evento-en-vivo --schedule-cron="0 20 * * *" --schedule-duration-sec=7200 \
  --schedule-min-required-replicas=3 --schedule-time-zone="America/Lima" \
  --schedule-description="Precalentamiento antes del evento en vivo" || true

gcloud compute instance-groups managed wait-until "${PREFIJO}-esc-mig" --zone="${ZONE}" --stable
gcloud compute instance-groups managed describe "${PREFIJO}-esc-mig" --zone="${ZONE}" \
  --format="yaml(autoscaler.autoscalingPolicy)" 2>/dev/null || true
gcloud compute instance-groups managed list-instances "${PREFIJO}-esc-mig" --zone="${ZONE}"
echo
echo "Siguiente paso: bash $(dirname "$0")/pico.sh      (simula el pico y observa el escalado horizontal)"
echo "               bash $(dirname "$0")/vertical.sh  (escalado vertical: cambia el tipo de máquina)"
