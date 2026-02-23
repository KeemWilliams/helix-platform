# Platform GitOps (gitops/platform)

**Purpose:** Reconcile platform Kubernetes manifests (network, observability, DB, queue, egress) via Devtron/Argo.

## Canonical diagram and map

- Diagram: `../../docs/diagrams/overview-full.mmd` (rendered SVG: `../../docs/diagrams/overview-full.svg`)
- Node map: `../../docs/diagrams/MAP.md`

## Key files in this directory

- `network-policies/` — CiliumNetworkPolicy and CiliumEgressNATPolicy manifests
- `observability/prometheusrules/queue.rules.yaml` — queue alert rules
- `egress/egress-values.yaml` — SOPS-encrypted Terraform outputs (egress IPs, LB IPs)
- `devtron/platform-application.yaml` — Argo Application manifest (if applicable)

## Owners

- Platform: **@platform-owner**
- Network: **@network-lead**
- Observability: **@sre-lead**
- GitOps: **@gitops-owner**

## How to change (PR checklist)

1. Update manifests under `gitops/platform/...`.
2. Update `../../docs/diagrams/MAP.md` if nodes or owners change.
3. Ensure `egress/egress-values.yaml` is updated by infra CI (SOPS-encrypted).
4. Open PR using `.github/PULL_REQUEST_TEMPLATE.md`.
5. Request approvals from owners listed above.

## Verification (staging)

```bash
# Confirm Devtron/Argo app is synced
kubectl -n argocd get applications platform-manifests -o yaml

# Check network policies applied
kubectl -n platform get ciliumnetworkpolicies

# Check Prometheus rule loaded
kubectl -n monitoring get prometheusrules platform-queue-rules -o yaml

# Validate egress values (decrypt locally)
sops --decrypt gitops/platform/egress/egress-values.yaml | yq .
```

## CI and automation

- Terraform → GitOps export script: `../../infra/ci/scripts/tf-export-to-gitops.sh`
- CI job: `../../.github/workflows/export-tf-outputs.yml` (produces branch `chore/tf-outputs-*`)

## Runbooks

- Stuck webhook job: `../../docs/runbook.md#stuck-webhook-job`
- Postgres restore: `../../docs/runbook.md#postgres-restore`

## Notes

- All secrets must be SOPS-encrypted. See `../../infra/ci/README-tf-outputs-to-gitops.md` for SOPS/KMS setup.
