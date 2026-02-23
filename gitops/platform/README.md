# Platform Components Documentation

This directory contains the configurations for the cluster-level platform services.

## 🛠️ Key Services

| Service | Purpose | Path |
| :--- | :--- | :--- |
| **Cilium** | eBPF Networking & Gateway API | `./cilium/` |
| **Longhorn** | Block-level HA Storage | `./longhorn/` |
| **Authentik** | Identity Provider (OIDC/SAML) | `./authentik/` |
| **Vault** | Secrets Management | `./vault/` |

## 🔄 Upgrade Procedure

1. **Check Compatibility**: Verify the new version is compatible with the current Talos/K8s release.
2. **Update Values**: Modify `values.yaml` in the respective directory.
3. **Verified Sync**: Use `devtron sync --dry-run` to preview changes.

## ✅ Verification Commands

- `kubectl get ciliumnodes` — Check network health.
- `kubectl get volumes.longhorn.io` — Check storage health.
- `talosctl health --nodes <IP>` — Check OS health.
