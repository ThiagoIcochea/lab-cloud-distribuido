#!/usr/bin/env bash
# Autor: Thiago Paolo Icochea Rodriguez · github.com/ThiagoIcochea
# Inventario rápido de lo que está encendido (para no gastar créditos sin querer).
source "$(dirname "$0")/config.sh"
titulo "VM";            gcloud compute instances list --format="table(name,zone.basename(),status,machineType.basename())"
titulo "Grupos de VM";  gcloud compute instance-groups managed list --format="table(name,zone.basename(),size)"
titulo "GKE";           gcloud container clusters list --format="table(name,location,status)"
titulo "Redes";         gcloud compute networks list --format="table(name,subnetMode)"
titulo "Buckets";       gcloud storage ls 2>/dev/null | grep -- "-${PREFIJO}-" || echo "(ninguno del lab)"
