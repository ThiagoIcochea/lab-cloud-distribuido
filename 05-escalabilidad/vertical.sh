#!/usr/bin/env bash
# Autor: Thiago Paolo Icochea Rodriguez · github.com/ThiagoIcochea
# Escalado vertical: aumenta CPU/RAM de una sola VM. Requiere detenerla (hay tiempo fuera de servicio).
source "$(dirname "$0")/../config.sh"
VM="${PREFIJO}-vertical"
gcloud compute instances describe "${VM}" --zone="${ZONE}" >/dev/null 2>&1 || \
  gcloud compute instances create "${VM}" --zone="${ZONE}" --machine-type=e2-small --tags=esc \
    --image-family=debian-12 --image-project=debian-cloud
gcloud compute instances describe "${VM}" --zone="${ZONE}" --format="value(machineType.basename())"
INICIO=$(date +%s)
titulo "Deteniendo, cambiando a e2-standard-2 (2 vCPU, 8 GB) y arrancando"
gcloud compute instances stop "${VM}" --zone="${ZONE}"
gcloud compute instances set-machine-type "${VM}" --zone="${ZONE}" --machine-type=e2-standard-2
gcloud compute instances start "${VM}" --zone="${ZONE}"
echo "Tipo actual: $(gcloud compute instances describe "${VM}" --zone="${ZONE}" --format='value(machineType.basename())')"
echo "Tiempo sin servicio durante el cambio vertical: $(( $(date +%s) - INICIO )) s"
