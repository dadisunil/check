#!/usr/bin/env bash
# Publishes this folder as a GitHub repo and bootstraps Flux on the kind cluster against it.
# Usage: bash scripts/04-github-flux.sh <your-github-username> [repo-name]
# Use your PERSONAL account for lab content, not the uniphore org.
# NOTE: `flux bootstrap` changes Flux in the cluster - fine on this throwaway kind cluster ONLY.
set -euo pipefail
OWNER="${1:?usage: 04-github-flux.sh <github-user> [repo]}"; REPO="${2:-uniphore-lab}"
cd "$(cd "$(dirname "$0")/.." && pwd)"
kubectl config use-context kind-uniphore-lab

# Fill in the owner placeholder (image paths, CODEOWNERS)
# (placeholder is split so this script doesn't match itself; scripts/ and README are skipped)
PH="OWNER_""PLACEHOLDER"
grep -rl "$PH" --exclude-dir=.git --exclude-dir=scripts --exclude=README.md . | xargs -r sed -i "s/$PH/$OWNER/g"

[ -d .git ] || git init -b main
git add -A
git commit -m "Initial lab platform" || true
# Public so the kind cluster can pull ghcr.io images without a pull secret (lab content only!)
gh repo create "$OWNER/$REPO" --public --source . --remote origin --push

export GITHUB_TOKEN="$(gh auth token)"
flux bootstrap github --owner="$OWNER" --repository="$REPO" --branch=main --path=flux/clusters/lab --personal
git pull --rebase origin main

echo
echo "Next in GitHub: protect main (PR + required 'ci' check); create Environments prod-canary and prod with required reviewers."
echo "Make sure Actions > ci passes once so the image exists, then: flux get kustomizations -w"
