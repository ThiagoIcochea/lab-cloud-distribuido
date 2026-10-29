#!/usr/bin/env bash
# Autor: Thiago Paolo Icochea Rodriguez · github.com/ThiagoIcochea
source "$(dirname "$0")/../config.sh"
titulo "Eliminando clúster ${PREFIJO}-gke"
gcloud container clusters delete "${PREFIJO}-gke" --region "${REGION}" --quiet || true
