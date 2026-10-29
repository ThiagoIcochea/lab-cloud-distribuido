#!/usr/bin/env bash
# Autor: Thiago Paolo Icochea Rodriguez · github.com/ThiagoIcochea
# Lab 1 · Contenedores y Kubernetes: microservicios en GKE Autopilot con autoescalado (HPA).
source "$(dirname "$0")/../config.sh"
C="${PREFIJO}-gke"
titulo "Creando clúster GKE Autopilot ${C} (≈8 min)"
gcloud container clusters describe "${C}" --region "${REGION}" >/dev/null 2>&1 || \
  gcloud container clusters create-auto "${C}" --region "${REGION}"
gcloud container clusters get-credentials "${C}" --region "${REGION}"
titulo "Desplegando microservicios"
kubectl apply -f "$(dirname "$0")/k8s/microservicios.yaml"
kubectl -n tienda rollout status deploy/frontend --timeout=600s
kubectl -n tienda rollout status deploy/catalogo --timeout=600s
kubectl -n tienda rollout status deploy/pedidos --timeout=600s
titulo "Esperando IP pública del frontend"
for _ in $(seq 1 60); do
  IP=$(kubectl -n tienda get svc frontend -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
  [[ -n "${IP}" ]] && break; sleep 10
done
echo "Frontend: http://${IP}"
curl -s "http://${IP}/"; curl -s "http://${IP}/api/catalogo"; echo; curl -s "http://${IP}/api/pedidos"; echo
kubectl -n tienda get pods,svc,hpa
echo
echo "Para simular una campaña de ventas: bash $(dirname "$0")/carga.sh"
