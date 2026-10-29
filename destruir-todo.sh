#!/usr/bin/env bash
# Autor: Thiago Paolo Icochea Rodriguez · github.com/ThiagoIcochea
# Elimina todos los recursos creados por los laboratorios (en orden inverso de dependencias).
D="$(cd "$(dirname "$0")" && pwd)"
for lab in 05-escalabilidad 04-monitoreo 03-redes 02-spark 01-kubernetes; do bash "${D}/${lab}/destroy.sh"; done
echo "Recursos de laboratorio eliminados."
