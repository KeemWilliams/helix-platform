# Rollout Sequence: Phase 1 (Helm & External State)

This guide documents the revised process for installing the Devtron platform via Helm, correctly pointing it to our external, highly available (HA) cluster services, and bypassing embedded ArgoCD/state conflicts.

## Prerequisites

1. **HA Services**: Confirm `platform-db-cluster-rw` (CNPG Postgres), NATS, and Redis are running and reachable in the cluster.
2. **Ingress**: Traefik must be correctly configured for `devtron.example.com`.
3. **SOPS / Secrets**: You must decrypt and populate the connection passwords inside `gitops/platform/devtron/values.devtron.custom.yaml` before running Helm.

---

## 1. Install Devtron via Helm

We install Devtron natively through Helm, passing our custom `values.yaml` to ensure it integrates seamlessly with our existing platform primitives.

```bash
# Add the Devtron repository
helm repo add devtron https://helm.devtron.ai
helm repo update

# Install Devtron with custom values overriding internal states
helm upgrade --install devtron devtron/devtron \
  --namespace devtroncd \
  --create-namespace \
  --values gitops/platform/devtron/values.devtron.custom.yaml
```

## 2. Post-Install Checks

Run the provided validation script to ensure Devtron successfully wired into the external databases and that no duplicate embedded components were created.

```bash
chmod +x ci/validation/devtron-post-install-checks.sh
./ci/validation/devtron-post-install-checks.sh
```

## 3. Verify Devtron SSO / Ingress

Do not expose the Dashboard on a raw LoadBalancer endpoint. Wait for the Traefik Ingress to reconcile.

```bash
# Verify the Route exists
kubectl -n devtroncd get ingress

# Check redirection to your OIDC provider
curl -fsS -I https://devtron.example.com
# Expected: HTTP 302 Redirect to your Auth Issuer
```

## 4. Rollback and Emergency

If Devtron fails to reconcile, repeatedly crash-loops parsing the database connection, or brings down existing GitOps synchronization:

```bash
# Helm Rollback
helm rollback devtron -n devtroncd

# Network Lockout:
# If you are completely locked out of GitOps deployment, apply the emergency policy:
kubectl apply -f gitops/platform/network-policies/emergency-allow.yaml
```
