#!/usr/bin/env bash
# Autor: Thiago Paolo Icochea Rodriguez · github.com/ThiagoIcochea
# Simula un pico de demanda cargando la CPU de las VM del grupo y muestra cómo el autoescalador agrega réplicas.
source "$(dirname "$0")/../config.sh"
DUR="${DUR:-420}"
for vm in $(gcloud compute instance-groups managed list-instances "${PREFIJO}-esc-mig" --zone="${ZONE}" --format="value(name.basename())"); do
  titulo "Cargando CPU de ${vm} durante ${DUR}s"
  gcloud compute ssh "${vm}" --zone="${ZONE}" --tunnel-through-iap --quiet \
    --command="nohup stress-ng --cpu 0 --timeout ${DUR}s >/dev/null 2>&1 &" || true
done
for _ in $(seq 1 $((DUR/30))); do
  date +%T
  gcloud compute instance-groups managed list-instances "${PREFIJO}-esc-mig" --zone="${ZONE}" --format="table(name.basename(),status)"
  sleep 30
done
