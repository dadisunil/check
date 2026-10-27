#!/usr/bin/env bash
# Runs the same gates as .github/workflows/ci.yml locally, before you push. Needs Docker running.
# Usage: bash scripts/05-local-checks.sh
set -uo pipefail
export MSYS_NO_PATHCONV=1
cd "$(cd "$(dirname "$0")/.." && pwd)"
HERE="$(pwd -W)"; fail=0
run() { echo; echo "=== $1"; shift; "$@" || { echo "!!! FAILED: $*"; fail=1; }; }

run "hadolint (Dockerfile lint)"   docker run --rm -i hadolint/hadolint < apps/hello-world-go/Dockerfile
run "helm lint"                    helm lint apps/hello-world-go/chart
run "trivy config (IaC/manifests)" docker run --rm -v "$HERE:/src" -w /src aquasec/trivy:latest config \
    --severity HIGH,CRITICAL --skip-dirs flux/clusters/lab/flux-system,manifests --exit-code 1 .
run "trivy secrets"                docker run --rm -v "$HERE:/src" -w /src aquasec/trivy:latest fs \
    --scanners secret --skip-dirs .git --exit-code 1 .
run "docker build"                 docker build -t hello-world-go:local apps/hello-world-go
run "trivy image scan"             docker run --rm -v //var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image \
    --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 hello-world-go:local

echo; [ "$fail" -eq 0 ] && echo "ALL CHECKS PASSED" || { echo "SOME CHECKS FAILED (see !!! lines)"; exit 1; }
