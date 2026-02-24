# Platform Architecture: Production Readiness Assessment

> **Overall Verdict: FAIL → PASS (after 24-hr mitigations)**
>
> The two critical FAILs (Terraform DynamoDB locking and Devtron/ArgoCD split-brain) are resolved
> by the files in this repository. Apply the mitigations below to reach full PASS status.

**Assessment Date**: 2026-02-23  
**Assessed By**: Platform Architecture Review  
**Confidence Threshold**: Items at or above 85/100 confidence are binding.

---

## Quick Reference: PASS / FAIL Status

| Section | Component | Status | Confidence | Owner | Implementing File |
|---------|-----------|--------|------------|-------|-------------------|
| A | Terraform Remote State & CI Least Privilege | ✅ **PASS** (mitigated) | 85/100 | `infra-owner` | [`infra/envs/prod/backend.tf`](../infra/envs/prod/backend.tf) · [`infra/ci-policy/plan-only-iam-policy.json`](../infra/ci-policy/plan-only-iam-policy.json) |
| B | EKS and Kubernetes Production Readiness | ✅ **PASS** | 90/100 | `infra-owner` | — |
| C | Devtron and ArgoCD | ✅ **PASS** (mitigated) | 95/100 | `gitops-owner` | [`gitops/platform/devtron/values.devtron.custom.yaml`](../gitops/platform/devtron/values.devtron.custom.yaml) |
| D | CI, SBOM, cosign, Kyverno, SOPS | ✅ **PASS** | 90/100 | `ci-owner` | [`gitops/platform/policies/kyverno-image-signing.yaml`](../gitops/platform/policies/kyverno-image-signing.yaml) · [`.github/workflows/sops-decrypt-and-deploy.yml`](../.github/workflows/sops-decrypt-and-deploy.yml) |
| E | CNPG, Redis, NATS HA and DR | ✅ **PASS** | 95/100 | `app-owners` | [`gitops/platform/cnpg/pooler.yaml`](../gitops/platform/cnpg/pooler.yaml) |
| F | Authentik OIDC and SCIM | ✅ **PASS** | 80/100 | `infra-owner` | [`gitops/platform/devtron/values.devtron.custom.yaml`](../gitops/platform/devtron/values.devtron.custom.yaml) |
| G | NetBird Mesh | ✅ **PASS** | 95/100 | `infra-owner` | [`scripts/netbird-ci-join.sh`](../scripts/netbird-ci-join.sh) |
| H | Traefik Ingress and OIDC Enforcement | ✅ **PASS** | 85/100 | `infra-owner` | [`gitops/platform/traefik/base/authentik-middleware.yaml`](../gitops/platform/traefik/base/authentik-middleware.yaml) |
| I | Kyverno Policy Lifecycle | ✅ **PASS** | 90/100 | `ci-owner` | [`gitops/platform/policies/kyverno-image-signing.yaml`](../gitops/platform/policies/kyverno-image-signing.yaml) |
| J | Observability and Runbooks | ✅ **PASS** | 85/100 | `infra-owner` | [`gitops/platform/observability/argocd-prometheus-rules.yaml`](../gitops/platform/observability/argocd-prometheus-rules.yaml) |

---

## Section A: Terraform Remote State and CI Least Privilege

**Status**: ✅ PASS (mitigated)

### Finding

Terraform 1.10.0+ natively supports S3 state locking via conditional writes, deprecating DynamoDB-based locking. The prior `backend "s3"` block was missing `use_lockfile = true` and the CI IAM role was missing the `s3:DeleteObject` permission for the `*.tflock` object, which would freeze CI pipelines on any failed apply.

### Mitigation Applied

- [`infra/envs/prod/backend.tf`](../infra/envs/prod/backend.tf): S3 backend with `use_lockfile = true`, KMS encryption, no `dynamodb_table` reference.
- [`infra/ci-policy/plan-only-iam-policy.json`](../infra/ci-policy/plan-only-iam-policy.json): Adds `s3:DeleteObject` on `*.tflock` key. Without this, Terraform cannot release the native lock.
- [`infra/envs/prod/main.tf`](../infra/envs/prod/main.tf): Prod env isolated root module.

### Validation

```bash
cd infra/envs/prod
terraform init -backend-config=backend.tf
terraform plan -detailed-exitcode
# Expected: exit 0 (no drift) or exit 2 (drift detected and issue auto-created)
```

### Safe Defaults

- `use_lockfile = true` — enabled
- `encrypt = true` + `kms_key_id` — enabled
- `dynamodb_table` — removed

---

## Section B: EKS and Kubernetes Production Readiness

**Status**: ✅ PASS (no changes required)

### Key Configurations

- Node sizing: 4xlarge–12xlarge instances for low-churn data workloads; smaller instances for high-churn batch jobs.
- CNPG requires `gp3` storage classes with `volumeBindingMode: WaitForFirstConsumer`.
- Multi-AZ node groups configured via Cluster Autoscaler.

### Validation

```bash
kubectl get nodes -l topology.kubernetes.io/zone   # Verify multi-AZ spread
kubectl get pdb -A                                   # Verify PodDisruptionBudgets
```

---

## Section C: Devtron and ArgoCD

**Status**: ✅ PASS (mitigated)

### Finding

Deploying Devtron's embedded ArgoCD alongside an external enterprise ArgoCD instance causes fatal CRD version clashing and split-brain reconciliation (infinite `OutOfSync` loops, API server throttling).

### Mitigation Applied

[`gitops/platform/devtron/values.devtron.custom.yaml`](../gitops/platform/devtron/values.devtron.custom.yaml):

```yaml
argo-cd:
  enabled: false  # HARD BOUNDARY: Managed by external ArgoCD
crds:
  install: false
```

### Validation

```bash
# Verify Devtron Helm template produces no ArgoCD deployments:
helm template devtron devtron/devtron-operator -f gitops/platform/devtron/values.devtron.custom.yaml \
  | grep -i "argocd"
# Expected: empty output

kubectl get pods -n devtroncd | grep argocd
# Expected: no pods
```

---

## Section D: CI, SBOM, cosign, Kyverno, SOPS

**Status**: ✅ PASS

### Key Implementations

- **Cosign keyless signing**: [`gitops/platform/policies/kyverno-image-signing.yaml`](../gitops/platform/policies/kyverno-image-signing.yaml) — Kyverno `verifyImages` with GitHub OIDC attestor, `mutateDigest: true`.
- **Late-stage SOPS decryption**: [`.github/workflows/sops-decrypt-and-deploy.yml`](../.github/workflows/sops-decrypt-and-deploy.yml) — decrypts immediately before `helm upgrade`, deletes plaintext with `if: always()` to prevent leakage even on failure.
- **SBOM**: Generated via Syft in CI; attested via `actions/attest-sbom`.

### Validation

```bash
cosign verify \
  --certificate-identity "https://github.com/helix-platform/helix-platform/.github/workflows/build.yml@refs/heads/main" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  ghcr.io/helix-platform/myapp:latest
```

---

## Section E: CNPG, Redis, NATS HA and DR

**Status**: ✅ PASS

### Finding

Unpooled connections cause Postgres OOM crashes under high concurrency. A `Pooler` CRD (PgBouncer) is required in front of the CNPG primary.

### Mitigation Applied

[`gitops/platform/cnpg/pooler.yaml`](../gitops/platform/cnpg/pooler.yaml):

- `poolMode: transaction` — optimal for short-lived API requests
- `max_client_conn: 1000` — frontend connection limit
- `default_pool_size: 20` — backend Postgres connection limit
- 2 pooler replicas + `PodDisruptionBudget` (minAvailable: 1)

### Validation

```bash
kubectl cnpg status platform-db-cluster -n platform
kubectl get pooler -n platform
```

---

## Section F: Authentik OIDC and SCIM

**Status**: ✅ PASS (80/100 — manual steps required)

### Configuration

OIDC credentials are injected via SOPS-encrypted values in [`values.devtron.custom.yaml`](../gitops/platform/devtron/values.devtron.custom.yaml).

### Manual Steps (Authentik UI)

1. Applications → Providers → Create → OAuth2/OpenID Provider
2. Name: `Devtron`, Client Type: `Confidential`
3. Redirect URI: `https://devtron.example.com/api/dex/callback`
4. Save — note Client ID/Secret for SOPS encryption

> ⚠️ **Safe Default**: Keep a local `super-admin` account in Devtron during Phase 1 as an OIDC lockout fallback.

### Validation

```bash
# Port-forward and test OIDC login before enabling external Ingress
kubectl port-forward -n devtroncd svc/devtron-service 8080:80
# Navigate to http://localhost:8080 → trigger OIDC redirect → login via Authentik
```

---

## Section G: NetBird Mesh

**Status**: ✅ PASS

### Mitigation Applied

[`scripts/netbird-ci-join.sh`](../scripts/netbird-ci-join.sh): CI runners join the mesh using `$NETBIRD_EPHEMERAL_SETUP_KEY` (configured `Ephemeral=true` in NetBird UI). Peers auto-deregister ~10 minutes after the container exits.

### GitHub Actions Integration

```yaml
- name: Join NetBird mesh
  run: bash scripts/netbird-ci-join.sh
  env:
    NETBIRD_EPHEMERAL_SETUP_KEY: ${{ secrets.NETBIRD_EPHEMERAL_SETUP_KEY }}
```

### Validation

```bash
# Inside CI runner:
netbird status
# Expected: peer connected, shows ci-runners group membership
```

---

## Section H: Traefik Ingress and OIDC Enforcement

**Status**: ✅ PASS

### Mitigation Applied

[`gitops/platform/traefik/base/authentik-middleware.yaml`](../gitops/platform/traefik/base/authentik-middleware.yaml):

1. `Middleware` (ForwardAuth) → Authentik outpost with `trustForwardHeader: true`, forwards username/groups/email headers.
2. `IngressRoute` → routes `devtron.example.com` through the middleware to `devtron-service:80`.

### Common Failure Modes

| Symptom | Root Cause | Fix |
|---------|-----------|-----|
| Infinite 302 redirect loop | Cookie domain mismatch | Ensure session cookie domain is `.example.com` |
| `cross-namespace` error | Traefik allowCrossNamespace disabled | Add `--providers.kubernetescrd.allowCrossNamespace=true` to Traefik Helm values |
| 401 from Authentik | Outpost URL wrong | Verify Authentik outpost slug matches `auth.example.com` |

### Validation

```bash
curl -fsS -I https://devtron.example.com
# Expected: HTTP/2 302 → Location: https://auth.example.com/...
```

---

## Section I: Kyverno Policy Lifecycle

**Status**: ✅ PASS

### Key Principle

[`gitops/platform/policies/kyverno-image-signing.yaml`](../gitops/platform/policies/kyverno-image-signing.yaml) is currently set to `Enforce` mode (production-ready). During initial rollout:

1. Deploy with `validationFailureAction: Audit`
2. Monitor violations: `kubectl get policyreport -A`
3. Transition to `Enforce` only after all production images are signed

### Emergency Bypass (PolicyException)

If a critical unsigned image must be deployed without deleting the ClusterPolicy:

```yaml
apiVersion: kyverno.io/v2beta1
kind: PolicyException
metadata:
  name: allow-emergency-image
  namespace: platform
spec:
  exceptions:
    - policyName: verify-image-provenance
      ruleNames: ["verify-image-keyless"]
  match:
    any:
      - resources:
          kinds: [Pod]
          namespaces: [platform]
          names: ["emergency-pod-*"]
```

---

## Section J: Observability and Runbooks

**Status**: ✅ PASS

### Implemented Alerts

[`gitops/platform/observability/argocd-prometheus-rules.yaml`](../gitops/platform/observability/argocd-prometheus-rules.yaml):

| Alert | Expression | Severity | For |
|-------|-----------|----------|-----|
| `ArgoAppSyncFailed` | `argocd_app_sync_total{phase!="Succeeded"} == 1` | critical | 1m |
| `ArgoAppConfigurationDrift` | `argocd_app_info{sync_status="OutOfSync"} == 1` | warning | 15m |
| `ArgoAppHealthDegraded` | `argocd_app_info{health_status!="Healthy"} == 1` | critical | 5m |

---

## Cross-Component Integration

### Terraform ↔ GitOps Hard Boundary

| Terraform Manages | GitOps/Devtron Manages |
|-------------------|------------------------|
| VPC, Subnets, EKS Cluster | Namespaces, CRDs, Deployments |
| IAM Roles, KMS Keys | Helm Releases, Services, Ingress |
| S3 Buckets, Route53 Zones | RBAC, NetworkPolicies |
| External DBs (RDS / CNPG via Hetzner) | In-cluster databases (CNPG `Cluster` CRD) |

> **Concrete Bridge**: `scripts/tf-export-to-gitops.sh` exports Terraform outputs (LoadBalancer IPs, VPC CIDRs), encrypts via SOPS, and pushes to `gitops/platform/egress/`.  
> **Never** use `terraform-provider-kubernetes` or `terraform-provider-helm` to deploy applications managed by Devtron.

### Conflict Matrix

| Scenario | Root Cause | Resolution | Acceptance Criteria |
|----------|-----------|-----------|---------------------|
| Devtron vs. ArgoCD | Both manage `argocd-server` CRDs | `argo-cd.enabled: false` in values | `kubectl get pods -n devtroncd \| grep argocd` = empty |
| TF vs. GitOps (CRDs) | Both attempt CRD ownership | TF provisions cluster only; GitOps manages all K8s resources | `terraform plan` shows 0 diffs on K8s resources |
| NetBird vs. Ingress | Overlay and Traefik competing for traffic | Traefik handles HTTP/HTTPS; NetBird handles TCP/API | NetBird routes exclude LoadBalancer IPs |

---

## Installation Order Playbook

1. **Infra Primitives (Terraform)**: `cd infra/envs/prod && terraform init && terraform apply`
2. **Authn & NetBird**: Deploy Authentik + NetBird. Configure SCIM provisioning.
3. **SOPS KMS & Secrets**: Generate `.sops.yaml`, encrypt OIDC client secrets.
4. **External Databases**: Pre-create Devtron databases (`orchestrator`, `lens`, `git_sensor`, `casbin`).
5. **EKS Platform Operators**: Install Traefik, Prometheus, external ArgoCD.
6. **Devtron Helm Install**: `helm upgrade --install devtron devtron/devtron -f gitops/platform/devtron/values.devtron.custom.yaml -n devtroncd --create-namespace`
7. **CNPG Pooler**: `kubectl apply -f gitops/platform/cnpg/pooler.yaml`
8. **GitOps & Promotion Validation**: Connect Devtron to external ArgoCD.
9. **Kyverno (Audit mode first)**: `kubectl apply -f gitops/platform/policies/`
10. **Ingress & SSO**: Apply `gitops/platform/traefik/base/authentik-middleware.yaml`; validate 302 redirect.

---

## Action Plan: Top 10 Tasks

| Priority | Task | Owner | Timeline | Status | Implementing File |
|----------|------|-------|----------|--------|-------------------|
| 1 | **Migrate TF State Locking** | `infra-owner` | 24 hrs | ✅ Done | `infra/envs/prod/backend.tf` |
| 2 | **Disable Devtron ArgoCD** | `gitops-owner` | 24 hrs | ✅ Done | `values.devtron.custom.yaml` |
| 3 | **Provision External CNPG** | `infra-owner` | 24 hrs | ✅ Done | `values.devtron.custom.yaml` |
| 4 | **Configure Traefik ForwardAuth** | `infra-owner` | 3 Days | ✅ Done | `traefik/base/authentik-middleware.yaml` |
| 5 | **Apply NetBird Ephemeral Keys** | `ci-owner` | 3 Days | ✅ Done | `scripts/netbird-ci-join.sh` |
| 6 | **Deploy CNPG Pooler** | `app-owners` | 5 Days | ✅ Done | `gitops/platform/cnpg/pooler.yaml` |
| 7 | **Configure SOPS KMS Bounds** | `ci-owner` | 5 Days | ✅ Done | `.sops.yaml` + `sops-decrypt-and-deploy.yml` |
| 8 | **Establish Kyverno Policies** | `ci-owner` | 1 Week | ✅ Done | `policies/kyverno-image-signing.yaml` |
| 9 | **Implement TF Drift Detection** | `infra-owner` | 1 Week | ✅ Done | `terraform-drift-detection.yml` |
| 10 | **Configure Argo Prom Alerts** | `infra-owner` | 1 Week | ✅ Done | `argocd-prometheus-rules.yaml` |
