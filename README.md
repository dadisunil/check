# Uniphore Platform Lab (kind + GitHub)

Local replica of the Garden -> GitHub Actions -> Flux -> staging -> canary -> prod flow. Nothing here touches real Uniphore systems. Use a PERSONAL GitHub account (the repo is public so the cluster can pull ghcr images).

## Run order (Git Bash, from this folder)
1. `bash scripts/01-install-tools.sh` (no admin; installs into ~/bin). Open a new Git Bash, then `gh auth login`.
2. Start Docker Desktop, then `bash scripts/02-cluster.sh` (cluster, local registry, namespaces with Pod Security "restricted").
3. `bash scripts/03-deps-observability.sh` (Postgres, Mongo, Redpanda, Prometheus/Grafana).
4. `bash scripts/04-github-flux.sh <github-user>` (creates the repo, pushes, bootstraps Flux).
5. In GitHub: protect `main` (PR + required `ci` check), create Environments `prod-canary` and `prod` with required reviewers.
6. Dev loop: `garden deploy` -> `k9s -n dev-<you>`.
7. Terraform: `docker run -d --name localstack -p 4566:4566 localstack/localstack`, then `cd terraform; terraform init; terraform apply`.
8. Cleanup: `bash scripts/teardown.sh`.

## The delivery flow
```
PR  -> ci: hadolint, helm lint, trivy config+secret scan, build, trivy image scan (blocks HIGH/CRITICAL)
main-> ci: push to ghcr (SBOM + provenance), cosign keyless sign, commit tag to flux/.../staging
        Flux -> staging (BLUE/GREEN via Argo Rollouts, auto)
manual: Actions > promote > prod-canary   (verifies signature, approval, opens PR; merge -> CANARY steps 25%/50%/100%)
manual: Actions > promote > prod          (only after canary healthy: Flux dependsOn)
```

## Practices covered
| Practice | Where |
|---|---|
| Containerizing, minimal approved base (Chainguard), non-root | `apps/hello-world-go/Dockerfile` |
| Image scanning, IaC + secret scanning, gated push | `.github/workflows/ci.yml` |
| SBOM, provenance, signing + verify before promote | ci.yml, promote.yml |
| GitOps (CI only commits; Flux deploys) | `flux/` |
| dev -> staging -> canary -> prod, approvals, PR review | promote.yml, Environments, CODEOWNERS |
| Blue/green (staging), canary (prod) | `flux/apps/hello/*` + Argo Rollouts |
| Hardened workloads: PSA restricted, limits, probes, PDB, NetworkPolicy | `flux/apps/hello/base/app.yaml`, 02-cluster.ps1 |
| Dependency updates | `.github/dependabot.yml` |
| Dev env per user, disposable clusters | Garden namespace `dev-<you>`, kind |

## Exercises
- Add a vulnerable base image (e.g. old `alpine:3.12`) and watch Trivy block the PR.
- Bump the version, break `/healthz`, and watch the Rollout abort; `kubectl argo rollouts get rollout hello -n staging -w` (install the plugin) or the dashboard.
- Promote a bad build to canary and confirm `prod` never reconciles.
- Roll back via `git revert`; Flux restores the old tag.
- Install the Trivy Operator or Kyverno (require signed images) as cluster-side admission.
- Practice the Harbor flow: `helm push` to `oci://ghcr.io/<you>`.
- Connect to Postgres/Mongo/Kafka in `deps` from your dev namespace; view metrics in Grafana (`kubectl -n observability port-forward svc/kps-grafana 3000:80`, admin/admin).

## Differences from real Uniphore
Not replicated: AWS SSO/Teleport, Snyk IDE plugin, multi-region, real Harbor (ghcr stands in), cluster-level canary (a namespace stands in), Datadog. kindnet doesn't enforce NetworkPolicy. Pin GitHub Actions to commit SHAs in real use. `flux bootstrap` is for this throwaway cluster only; never on real clusters.
