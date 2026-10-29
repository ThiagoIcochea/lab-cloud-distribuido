# Laboratorios de computación distribuida en Google Cloud

Autor: **Thiago Paolo Icochea Rodriguez** · [github.com/ThiagoIcochea](https://github.com/ThiagoIcochea)

Cinco laboratorios cortos y reproducibles en Google Cloud para practicar los temas de la guía:
contenedores y Kubernetes, Hadoop/Spark, redes públicas y privadas, monitoreo y escalabilidad.
Cada laboratorio tiene un `run.sh` que lo levanta y un `destroy.sh` que lo elimina.

| Lab | Tema | Qué se despliega | Tiempo aprox. |
|---|---|---|---|
| [01-kubernetes](01-kubernetes) | Contenedores y Kubernetes | GKE Autopilot con 3 microservicios (frontend, catálogo, pedidos), balanceador y autoescalado HPA | 10 min |
| [02-spark](02-spark) | Archivos y programación distribuida | Data lake en Cloud Storage + PySpark en Dataproc Serverless (agregación de lecturas IoT y anomalías) | 6 min |
| [03-redes](03-redes) | Redes privadas y públicas | VPC con subred pública y privada, firewall, IAP, Cloud NAT, VM web (proxy) y VM interna sin IP pública | 3 min |
| [04-monitoreo](04-monitoreo) | Orquestación y monitoreo | Uptime check y dashboard en Cloud Monitoring + Prometheus (series temporales) y Grafana | 5 min |
| [05-escalabilidad](05-escalabilidad) | Escalabilidad y scheduling | Grupo de instancias con autoescalado horizontal, capacidad programada para picos y cambio vertical de máquina | 5 min |

## Uso rápido (Cloud Shell)

```bash
git clone https://github.com/ThiagoIcochea/lab-cloud-distribuido.git && cd lab-cloud-distribuido
gcloud config set project <PROJECT_ID>
bash scripts/00-preparar.sh          # habilita las API (una sola vez)

bash 03-redes/run.sh                 # cualquier lab de forma independiente
bash 04-monitoreo/run.sh             # este usa la VM web del lab 03
bash estado.sh                       # qué está encendido
bash destruir-todo.sh                # eliminar todo al terminar
```

Variables opcionales: `REGION` (por defecto `us-central1`), `ZONE`, `PREFIJO` (por defecto `lab`).
Para dar acceso de Editor a otras cuentas de Google: `EMAILS="a@gmail.com b@gmail.com" bash scripts/00-preparar.sh`.

## Detalles por laboratorio

**01 · Kubernetes.** `run.sh` crea el clúster, aplica [`k8s/microservicios.yaml`](01-kubernetes/k8s/microservicios.yaml)
y muestra la IP pública. `carga.sh` simula una campaña de ventas; con `kubectl -n tienda get hpa -w` se ve cómo
aumentan las réplicas.

**02 · Spark.** Genera lecturas simuladas de sensores, las sube a Cloud Storage (el equivalente gestionado a HDFS)
y ejecuta [`iot_spark.py`](02-spark/iot_spark.py), que agrega por región y día (Parquet particionado) y detecta
anomalías (media + 3σ). Con `N=2000000 bash 02-spark/run.sh` se procesa más volumen.

**03 · Redes.** Dos subredes en la VPC `lab-vpc`: `10.10.1.0/24` (pública) y `10.10.2.0/24` (privada).
La VM web publica el puerto 80 y reenvía `/interno/` a la VM privada (`10.10.2.10:8080`), que no tiene IP pública,
sale a Internet por Cloud NAT y solo se administra por IAP.

**04 · Monitoreo.** Crea un uptime check y un dashboard en Cloud Monitoring, y una VM privada con Prometheus,
node-exporter, blackbox-exporter y Grafana (docker compose). Grafana se abre por túnel IAP y Vista previa en la Web
(el script imprime el comando).

**05 · Escalabilidad.** Grupo de instancias de 1 a 5 VM con CPU objetivo del 60 %, control de reducción gradual y
un horario de capacidad mínima (3 VM de 20:00 a 22:00, hora de Lima). `pico.sh` carga la CPU para ver el escalado
horizontal y `vertical.sh` cambia una VM de `e2-small` a `e2-standard-2` midiendo el tiempo sin servicio.

## Costos

Todo usa máquinas pequeñas. Ejecuta `bash destruir-todo.sh` al terminar: el clúster GKE, las VM y el balanceador
generan costo mientras estén encendidos.
