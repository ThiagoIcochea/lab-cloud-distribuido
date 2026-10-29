#!/usr/bin/env bash
# Autor: Thiago Paolo Icochea Rodriguez · github.com/ThiagoIcochea
# Configuración común de los laboratorios. Se puede sobrescribir con variables de entorno:
#   PROJECT_ID=mi-proyecto REGION=us-central1 bash 01-kubernetes/run.sh
set -euo pipefail
PROJECT_ID="${PROJECT_ID:-$(gcloud config get-value project 2>/dev/null)}"
REGION="${REGION:-us-central1}"
ZONE="${ZONE:-${REGION}-a}"
PREFIJO="${PREFIJO:-lab}"
if [[ -z "${PROJECT_ID}" ]]; then
  echo "Define el proyecto: gcloud config set project <ID> o PROJECT_ID=<ID>" >&2; exit 1
fi
gcloud config set project "${PROJECT_ID}" >/dev/null
gcloud config set compute/region "${REGION}" >/dev/null
gcloud config set compute/zone "${ZONE}" >/dev/null
titulo() { printf '\n\033[1;35m== %s ==\033[0m\n' "$*"; }
