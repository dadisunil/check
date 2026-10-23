#!/usr/bin/env bash
set -euo pipefail
LAB="$(cd "$(dirname "$0")/.." && pwd)"
kubectl apply -f "$(cygpath -w "$LAB/manifests/deps.yaml")"

# Datadog stand-in: Prometheus + Grafana (trimmed to save RAM)
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install kps prometheus-community/kube-prometheus-stack -n observability \
  --set alertmanager.enabled=false --set prometheus.prometheusSpec.resources.requests.memory=400Mi \
  --set grafana.adminPassword=admin --wait --timeout 10m

echo "Grafana:  kubectl -n observability port-forward svc/kps-grafana 3000:80  (admin/admin)"
echo "Postgres: kubectl -n deps port-forward svc/postgres 5432   (postgres/labpass)"
