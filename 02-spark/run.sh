#!/usr/bin/env bash
# Autor: Thiago Paolo Icochea Rodriguez · github.com/ThiagoIcochea
# Lab 2 · Sistemas de archivos y programación distribuida: datos IoT en Cloud Storage procesados con Spark (Dataproc Serverless).
source "$(dirname "$0")/../config.sh"
D="$(cd "$(dirname "$0")" && pwd)"
BUCKET="gs://${PROJECT_ID}-${PREFIJO}-iot"
N="${N:-500000}"
titulo "Bucket ${BUCKET} (data lake)"
gcloud storage buckets describe "${BUCKET}" >/dev/null 2>&1 || gcloud storage buckets create "${BUCKET}" --location="${REGION}"
titulo "Generando ${N} lecturas simuladas"
python3 "${D}/generar_datos.py" "${N}" /tmp/lecturas.csv
gcloud storage cp /tmp/lecturas.csv "${BUCKET}/raw/lecturas.csv"
gcloud storage cp "${D}/iot_spark.py" "${BUCKET}/jobs/iot_spark.py"
titulo "Habilitando Private Google Access en la subred default (requisito de Dataproc Serverless)"
gcloud compute networks subnets update default --region="${REGION}" --enable-private-ip-google-access
titulo "Ejecutando PySpark en Dataproc Serverless (≈3-5 min)"
gcloud dataproc batches submit pyspark "${BUCKET}/jobs/iot_spark.py" --region="${REGION}" \
  --batch="${PREFIJO}-iot-$(date +%H%M%S)" --version=2.2 \
  -- "${BUCKET}/raw/" "${BUCKET}/procesado"
titulo "Resultados en ${BUCKET}/procesado"
gcloud storage ls -r "${BUCKET}/procesado/" | head -20
