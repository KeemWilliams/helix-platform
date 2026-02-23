# Devtron Custom Helm Values Guide

# Owner: @platform-owner

# Reviewers: @db-owner, @security-lead

This repository uses a carefully constructed `values.devtron.custom.yaml` file to deploy Devtron via Helm, preventing it from consuming redundant compute resources by spinning up embedded Databases (Postgres), Caches (Redis), and Message Queues (NATS).

Instead, Devtron is natively wired to our high-availability (HA) platform endpoints.

## 1. Secrets and SOPS Placeholders

Never commit plaintext passwords to this repository!

The `values.devtron.custom.yaml` file contains placeholders like `<SOPS_ENCRYPTED_DB_PASSWORD>`. During CI/CD or before running Helm manually, you must decrypt the injected SOPS `egress-values.yaml` or use your platform's Vault injector to replace these placeholders.

### Secret Rotation

If the CloudNativePG (CNPG) password rotates, or the OIDC Client Secret is refreshed:

1. Update the centralized SOPS/Vault values.
2. Re-run `helm upgrade devtron devtron/devtron -f values.devtron.custom.yaml`.
3. The Devtron operator will reconcile the new configurations automatically.

## 2. The ArgoCD Toggle

By default in our infrastructure, `argo-cd.enabled` is set to `true` inside `values.devtron.custom.yaml`, empowering the Devtron Operator to natively spin up ArgoCD managed under its umbrella.

**CRITICAL RULE:** Do NOT apply raw ArgoCD manifests (e.g., `argoproj/argo-cd/stable/manifests/install.yaml`) if you are leveraging this Helm chart. Doing so will cause severe overlapping controller conflicts.

## 3. OIDC & Ingress Shielding

The Devtron Dashboard handles profound control over our Kubernetes clusters.

We enforce:

- `ingress.allowPublic: false`
- `auth.oidc.enabled: true`

This guarantees that the dashboard `frontend` will instantly issue an HTTP 302 redirect to our centralized identity provider before passing any traffic into the app.

For temporary troubleshooting or break-glass scenarios where SSO is unavailable, a PR must be opened and approved by `@security-lead` to temporarily toggle `allowPublic: true`.
