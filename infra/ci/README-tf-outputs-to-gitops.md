# Terraform outputs → GitOps CI job

**Purpose:** Export Terraform outputs (egress IPs, LB IP, backup bucket) and publish them to `gitops/platform/egress/egress-values.yaml` (SOPS-encrypted).

## Script

- `scripts/tf-export-to-gitops.sh` (repo: infra)

## Required secrets (CI)

- Terraform cloud/provider credentials
- SOPS KMS/GPG keys configured for the runner
- `GIT_TOKEN` (or use `GITHUB_TOKEN`) with repo write permission

## Outputs written

- `gitops/platform/egress/egress-values.yaml` (SOPS-encrypted)

## Verification

1. Confirm branch pushed: `gh pr list --author github-actions[bot]`
2. Decrypt locally: `sops --decrypt gitops/platform/egress/egress-values.yaml | yq .`
3. Confirm Devtron reconciles: `kubectl -n argocd get app platform-manifests -o yaml`

## Owners

- Infra: **@infra-owner**
- Platform: **@platform-owner**

## Troubleshooting

- SOPS errors: verify KMS/GPG keys and SOPS config.
- Git push errors: check token permissions and branch protection rules.
