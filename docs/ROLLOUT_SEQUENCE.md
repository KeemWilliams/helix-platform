# Rollout Sequence: Phase 1 & 2

This sequence details the exact execution paths and order of applied manifests required to safely provision the core GitOps automation and the platform primitives prior to enabling default-deny policies.

## Prerequisites (Phase 0)

Ensure Terraform output exports have successfully completed:

```bash
# Decrypt and verify egress-values are populated
sops --decrypt gitops/platform/egress/egress-values.yaml | yq .
```

---

## Phase 1: Devtron Core (Helm Based)

See `docs/ROLLOUT_SEQUENCE_PHASE1_HELM.md` for explicit prerequisites and step-by-step commands to properly integrate the Devtron Operator along with its embedded ArgoCD controller instance.

**CRITICAL WARNING:** We are no longer applying raw ArgoCD manifests from `argoproj/argo-cd`. Ensure you rely strictly on the custom Devtron Helm chart `values.devtron.custom.yaml` installation pattern to avoid infrastructure overlap.

1. **Apply Network Pre-requisites**
Ensure Devtron components can communicate before any restrictions:

```bash
# Apply Argo to API server allow rule
kubectl apply -f gitops/platform/network-policies/allow-argocd-to-apiserver.yaml

# Apply Repo Server Egress allow rule
kubectl apply -f gitops/platform/network-policies/allow-repo-server-egress.yaml

# Apply Traefik to ArgoCD allow rule
kubectl apply -f gitops/platform/network-policies/allow-traefik-to-argocd.yaml
```

1. **Deploy the GitOps Application Manifest**
Tell Argo CD to begin polling the `gitops/platform` path in this repository:

```bash
kubectl apply -f gitops/platform/devtron/platform-application.yaml
```

1. **Verify Rollout**

```bash
# Ensure sync is progressing
kubectl -n argocd get applications -o wide

# Check logs for potential repo authentication errors
kubectl -n argocd logs deploy/argocd-repo-server | tail -n 50
```

---

## Phase 2: Platform Primitives

Once Phase 1 successfully completes, Devtron will implicitly begin provisioning all manifests placed in the `gitops/platform` directory structure.

Wait for Devtron to deploy the following components:

1. **Ingress (Traefik) / Load Balancing**
2. **PostgreSQL HA Clusters (CNPG)**
3. **PgBouncer Connection Pools**
4. **Message Queues (NATS/RabbitMQ)**

### Verification

Manually verify that the platform primitives resolved successfully from the GitOps pull:

```bash
# Check LoadBalancer IP allocation
kubectl -n platform get svc,ingress

# Verify Database and Pooler readiness
kubectl -n platform get pods -l 'app in (pgbouncer, postgres)' -o wide

# Monitor Application Controller for synchronization status
kubectl -n argocd logs deploy/argocd-application-controller --tail=200
```
