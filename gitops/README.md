# GitOps Repository Structure & Promotion Flow

This directory contains the declarative state of the cluster. We use **Devtron/ArgoCD** to reconcile this state into the live environment.

## 📂 Directory Layout

- `platform/`: Core cluster services (Ingress, Storage, Security).
- `apps/`: Customer-facing workloads and AI services.
- `secrets/`: **SOPS encrypted** sensitive data. Decrypt locally with `sops -d`.
- `config/`: Shared configuration and global manifests.

## 🚀 Promotion Flow (The Golden Path)

1. **CI Build**: GitHub Actions builds the image, generates an SBOM, and scans for vulnerabilities.
2. **Sign**: The image is signed with **Cosign**.
3. **Commit**: The CI bot updates the `gitops/` manifests with the new image tag.
4. **Sync**: Devtron detects the Git change and performs an automated rollout.

## 🔑 Secret Management

- **Rule**: Never commit plaintext secrets.
- **Tool**: Use `sops` with `age-keygen`.
- **Placeholder**: Reference SOPS-decrypted values in your application charts.

## 🛑 Branch Protection

- `main`: Only the CI bot and authorized platform leads can push.
- Requires 2 approvals and a passing `Build & Verify` check.

---
**Primary Owner**: GitOps Lead
