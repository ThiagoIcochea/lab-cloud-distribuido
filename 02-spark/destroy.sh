#!/usr/bin/env bash
# Autor: Thiago Paolo Icochea Rodriguez · github.com/ThiagoIcochea
source "$(dirname "$0")/../config.sh"
titulo "Eliminando bucket y lotes de Dataproc"
gcloud storage rm -r "gs://${PROJECT_ID}-${PREFIJO}-iot" --quiet || true
for b in $(gcloud dataproc batches list --region="${REGION}" --format="value(name.basename())" 2>/dev/null | grep "^${PREFIJO}-iot" || true); do
  gcloud dataproc batches delete "$b" --region="${REGION}" --quiet || true
done
