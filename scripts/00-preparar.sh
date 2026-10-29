#!/usr/bin/env bash
# Autor: Thiago Paolo Icochea Rodriguez · github.com/ThiagoIcochea
# Habilita las API necesarias y, opcionalmente, da acceso de Editor a otras personas.
#   EMAILS="a@gmail.com b@gmail.com" bash scripts/00-preparar.sh
source "$(dirname "$0")/../config.sh"
titulo "Habilitando API en ${PROJECT_ID}"
gcloud services enable compute.googleapis.com container.googleapis.com dataproc.googleapis.com \
  storage.googleapis.com monitoring.googleapis.com logging.googleapis.com iap.googleapis.com
for e in ${EMAILS:-}; do
  titulo "Rol Editor para ${e}"
  gcloud projects add-iam-policy-binding "${PROJECT_ID}" --member="user:${e}" --role="roles/editor" \
    --condition=None --format="value(etag)" || echo "No se pudo agregar ${e} (¿tiene cuenta de Google?)"
done
echo "Listo. Proyecto: ${PROJECT_ID} · región: ${REGION}"
