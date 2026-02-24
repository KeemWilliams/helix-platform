# Platform Engineer Architecture — GitOps, CI/CD, Secrets, Policy

## GitOps model

- **Source of truth:** GitOps repo.
- **Engine:** ArgoCD.
- **Surface:** Devtron UI.
- Flow:
  1. Developer pushes to GitHub.
  2. CI builds, scans, signs, and opens PR to GitOps repo.
  3. ArgoCD syncs GitOps repo to cluster.
  4. Devtron provides app‑level visibility and controls.

## CI/CD and supply chain

- **CI:** GitHub Actions.
- **Build:** container images.
- **SBOM:** Syft.
- **Vuln scanning:** Trivy.
- **Signing:** cosign (keyless or KMS‑backed).
- **Policy:** Kyverno `verifyImages` enforces cosign signatures.

Recommended pattern:

- Build + scan + sign in CI.
- CI updates image tags in GitOps repo via PR.
- ArgoCD syncs only after PR approval and required checks pass.

## Secrets and configuration

- **Secrets:** SOPS + KMS.
- Encrypted secrets stored in GitOps repo.
- CI uses OIDC to assume a role with `kms:Decrypt` only.
- Decryption happens only during `helm template` / `kubectl apply` in controlled contexts.

## Data plane

- **Postgres:** CloudNativePG HA cluster.
- **Pooling:** CNPG Pooler (PgBouncer).
- **Redis:** in‑cluster HA cache.
- **Storage:** Longhorn CSI on gp3‑backed volumes.

## Policy and safety

- **Kyverno:** verify images, enforce namespace policies, guardrails.
- **Cilium:** network policies for zero‑trust.
- **Remediation service:** opens rollback PRs when alerts fire (e.g., failed rollout, SLO breach).

This gives you a **repeatable, auditable, and secure** platform for app teams.
