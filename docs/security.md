# Security Posture & Governance (v1.1)

This platform implements a **Defense-in-Depth** strategy tailored for autonomous AI workloads and stateful applications.

## 🛡️ Core Security Architecture

### 1. Zero-Trust Access

- **Private Mesh**: All administrative traffic requires **NetBird VPN** connectivity.
- **Identity-First**: **Authentik** acts as the unified OIDC/SAML provider.
- **Micro-segmentation**: **Cilium** enforces `default-deny` between namespaces.
- **Devtron Hardening**: UI restricted to VPN; SSO+MFA required; Least-privilege RBAC.

### 2. Supply Chain Integrity

- **Image Signing**: All images must be signed by **Cosign** in the CI pipeline.
- **SBOM**: Artifact provenance is tracked via **Syft** and stored in the **SBOM Store**.
- **Immutable Host**: **Talos Linux** provides a read-only rootfs and no SSH access.

### 3. Secret Management

- **SOPS**: All Git-stored secrets are encrypted with `age`.
- **Vault**: Dynamic, short-lived credentials for databases and AI providers.
- **GitOps Flow**: Devtron reads SOPS placeholders; Vault agent handles runtime injection.

## 🛠️ Devtron Hardening Checklist

- [ ] **RBAC**: Use dedicated service account with `devtron-app-controller` role.
- [ ] **Network**: Restrict `/dashboard` access to NetBird/VPN CIDRs.
- [ ] **Auth**: Enforce Authentik SSO with MFA for all admins.
- [ ] **Promotion**: Require signed CI commits for `gitops/` updates.
- [ ] **Audit**: Forward all GitOps sync events to Grafana Loki.

## 🆘 Threat Model & Scenarios

| Asset | Threat | Mitigation |
| :--- | :--- | :--- |
| **User Data** | SQL Injection / Data Exfiltration | WAF + Cilium Egress Policies + PgBouncer |
| **AI Models** | Prompt Injection / Unauthorized Access | Webhook HMAC verification + RBAC |
| **Infra** | Control Plane Compromise | API LB CIDR restriction + Talos Immutability |

## 📜 Incident Playbook

1. **Isolate**: Apply `default-deny` Cilium policy to suspicious namespace.
2. **Revoke**: Invalidate Authentik sessions and rotate Vault tokens.
3. **Audit**: Review Loki logs and K8s audit trail.
4. **Restore**: Wipe compromised nodes and re-provision via Terraform.

See [runbook.md](./runbook.md) for emergency commands.
