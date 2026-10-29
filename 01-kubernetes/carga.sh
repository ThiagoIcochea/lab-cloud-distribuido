#!/usr/bin/env bash
# Autor: Thiago Paolo Icochea Rodriguez · github.com/ThiagoIcochea
# Genera carga sobre el frontend para observar el escalado horizontal (HPA).
source "$(dirname "$0")/../config.sh"
gcloud container clusters get-credentials "${PREFIJO}-gke" --region "${REGION}" >/dev/null
DURACION="${DURACION:-180}"
titulo "Carga durante ${DURACION}s con 4 generadores"
for i in 1 2 3 4; do
  kubectl -n tienda run "carga-${i}" --image=busybox:1.36 --restart=Never --requests='cpu=250m' -- \
    /bin/sh -c "end=\$((\$(date +%s)+${DURACION})); while [ \$(date +%s) -lt \$end ]; do wget -q -O- http://frontend/api/catalogo >/dev/null; done" \
    >/dev/null 2>&1 || true
done
for _ in $(seq 1 $((DURACION/20))); do kubectl -n tienda get hpa; sleep 20; done
kubectl -n tienda delete pod carga-1 carga-2 carga-3 carga-4 --ignore-not-found
kubectl -n tienda get hpa,deploy
