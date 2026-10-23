#!/usr/bin/env bash
# Cluster + local "Harbor" registry (localhost:5001) + namespaces. Run in Git Bash.
set -euo pipefail
export MSYS_NO_PATHCONV=1   # stop Git Bash rewriting /etc/... paths passed to docker
LAB="$(cd "$(dirname "$0")/.." && pwd)"
REG=harbor-lite
CLUSTER=uniphore-lab

docker ps -a --format '{{.Names}}' | grep -qx "$REG" || \
  docker run -d --restart=always -p 127.0.0.1:5001:5000 --name "$REG" registry:2
docker start "$REG" >/dev/null 2>&1 || true

kind get clusters 2>/dev/null | grep -qx "$CLUSTER" || \
  kind create cluster --config "$(cygpath -w "$LAB/kind-config.yaml")"

# Let nodes pull localhost:5001/... from the registry container
docker network connect kind "$REG" 2>/dev/null || true
for n in $(kind get nodes --name "$CLUSTER"); do
  docker exec "$n" mkdir -p /etc/containerd/certs.d/localhost:5001
  printf '[host."http://%s:5000"]\n' "$REG" | docker exec -i "$n" sh -c 'cat > /etc/containerd/certs.d/localhost:5001/hosts.toml'
done

DEV="dev-$(echo "${USERNAME:-$USER}" | tr '[:upper:]' '[:lower:]')"
for ns in "$DEV" staging prod-canary prod deps observability; do
  kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f -
done
# Pod Security Admission: enforce "restricted" on workload namespaces
for ns in staging prod-canary prod; do
  kubectl label namespace "$ns" pod-security.kubernetes.io/enforce=restricted --overwrite
done
kubectl config use-context kind-$CLUSTER
echo "Cluster ready. Your dev namespace: $DEV"
