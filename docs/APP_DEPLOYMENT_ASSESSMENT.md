# Helix Platform — App Deployment Assessment (Assessment 2)

> **Overall Verdict: PASS** — Confidence: 92/100  
> **Date**: 2026-02-23 | **Assessed By**: Platform Architecture Review  
> **Scope**: Multi-domain ingress, TLS automation, private/public app patterns, CI/CD model, multi-tenant secrets

---

## Quick Reference

| Section | Topic | Status | Confidence | Implementing File |
|---------|-------|--------|------------|-------------------|
| 1 | Multi-domain Traefik Ingress | ✅ PASS | 95/100 | [`ingress-patterns.yaml`](../gitops/platform/traefik/base/ingress-patterns.yaml) |
| 2 | Automatic TLS — Let's Encrypt | ✅ PASS | 95/100 | [`clusterissuer.yaml`](../gitops/platform/cert-manager/clusterissuer.yaml) |
| 3 | Private Apps — IPAllowList | ✅ PASS | 95/100 | [`ingress-patterns.yaml`](../gitops/platform/traefik/base/ingress-patterns.yaml) |
| 4 | Public Apps — Stateless CMS | ✅ PASS | 85/100 | Manual (S3 offload plugin config) |
| 5 | Devtron CI/CD Automation | ✅ PASS | 90/100 | [`.github/workflows/promote-to-gitops.yml`](../.github/workflows/promote-to-gitops.yml) |
| 6 | Multi-Tenant SOPS Secrets | ✅ PASS | 95/100 | [`.sops.yaml`](../.sops.yaml) |
| 7 | Authentik OIDC App Protection | ✅ PASS | 90/100 | [`authentik-middleware.yaml`](../gitops/platform/traefik/base/authentik-middleware.yaml) |
| 8 | NetBird Zero-Trust Access | ✅ PASS | 95/100 | [`netbird-ci-join.sh`](../scripts/netbird-ci-join.sh) |
| 9 | Installation Order Playbook | ✅ PASS | — | [`ROLLOUT_SEQUENCE_PHASE1_HELM.md`](ROLLOUT_SEQUENCE_PHASE1_HELM.md) |

---

## Section 1: Multi-Domain & Multi-Tenant Ingress

### Pattern A — Public Customer Domain

```yaml
# Host() matcher + HTTP-01 TLS + rate-limit middleware
kind: IngressRoute
match: Host(`customer.example.com`)
middlewares: [rate-limit-public]
tls.certResolver: letsencrypt-prod
```

### Pattern B — Private Internal App (Double Gate)

```yaml
# IP gate first (NetBird CIDR), then OIDC session check
kind: IngressRoute
match: Host(`admin.internal.example.com`)
middlewares:
  - netbird-ip-allowlist   # 403 if outside NetBird CIDR
  - authentik-forwardauth  # 302 if no valid OIDC session
```

> ⚠️ **Traffic hijacking risk**: Overlapping `Host()` rules or wildcard priorities between tenant namespaces can cause traffic to leak between tenants. Always use explicit hostnames, never `HostRegexp()` for tenant routing.

**Validation**:

```bash
kubectl get ingressroute -A
curl -I https://customer.example.com         # 200 OK
curl -I https://admin.internal.example.com   # 403 / 302 from non-NetBird IP
```

---

## Section 2: Automatic TLS — Let's Encrypt Dual Solver

| Challenge | Use for | Requirement |
|-----------|---------|-------------|
| **DNS-01** | `*.example.com`, `*.internal.example.com` | Cloudflare API token; only method for wildcards |
| **HTTP-01** | Customer vanity domains | DNS A-record → Traefik LB IP must be set first |

> ⚠️ **Rate limit**: 50 certs per registered domain per week. Use `letsencrypt-staging` issuer in non-prod environments.

See: [`gitops/platform/cert-manager/clusterissuer.yaml`](../gitops/platform/cert-manager/clusterissuer.yaml)

**Validation**:

```bash
kubectl get clusterissuer letsencrypt-prod
kubectl get certificates,certificaterequests,challenges -A
```

---

## Section 3: Private Apps — NetBird IP Allow List

```yaml
kind: Middleware
name: netbird-ip-allowlist
spec:
  ipAllowList:
    sourceRange: ["100.64.0.0/10"]  # NetBird overlay CIDR
```

> ⚠️ **`trustForwardHeader: true` is required** in Traefik's Helm values. Without it, Traefik evaluates the internal LoadBalancer IP rather than `X-Forwarded-For`, causing all requests to be rejected regardless of client IP.

**Immediate 24-hr mitigation**: Apply `netbird-ip-allowlist` to all internal endpoints before public DNS records propagate.

---

## Section 4: Public Apps — Stateless CMS (WordPress / Ghost)

**Risk**: Default CMS media storage breaks horizontal scaling. `ReadWriteOnce` PVs prevent rolling updates.

**Required pattern**:

| Layer | Configuration |
|-------|-------------|
| Application | Stateless ephemeral pods — no media on local disk |
| Media | S3 offload (WP Offload Media / Ghost S3 adapter / Cloudinary) |
| Database | `cnpg-rw.database.svc.cluster.local` via CNPG Pooler |
| Sessions | External Redis (not in-pod) |

Confidence 85/100 — implementation depends on CMS plugin configuration outside Kubernetes.

---

## Section 5: CI/CD Automation Model

| Model | Pros | Cons | Use for |
|-------|------|------|---------|
| **GitHub Actions → GitOps PR** ✅ (recommended) | Strict isolation, OIDC Cosign support | PR automation script needed | Microservices, governed apps |
| Devtron Pipelines | Single UI, easy adoption | In-cluster CI, harder to isolate | Internal tools, prototyping |

**Recommended flow**: GitHub Actions builds → Syft SBOM → Trivy scan → keyless Cosign sign → auto-PR that bumps image tag in `gitops/` → ArgoCD reconciles on merge.

See: [`.github/workflows/promote-to-gitops.yml`](../.github/workflows/promote-to-gitops.yml)

---

## Section 6: Multi-Tenant SOPS Secrets

```
gitops/
├── .sops.yaml                         ← path_regex routes each dir to its KMS key
└── tenants/
    ├── customer-a/secrets.enc.yaml    ← encrypted with KMS Key A (isolated)
    ├── customer-b/secrets.enc.yaml    ← encrypted with KMS Key B (isolated)
    └── internal-tools/secrets.enc.yaml ← KMS Key C (platform team only)
```

> ⚠️ **Blast radius risk**: Broad IAM role permissions allow a CI runner for Tenant A to decrypt Tenant B's secrets. The `.sops.yaml` `path_regex` isolation + per-tenant KMS keys closes this gap — but each tenant CI role must *only* have `kms:Decrypt` on their own key ARN.

See: [`.sops.yaml`](../.sops.yaml)

---

## Section 7: Authentik OIDC

Already implemented. See [`authentik-middleware.yaml`](../gitops/platform/traefik/base/authentik-middleware.yaml).

**Common failure modes**:

| Symptom | Fix |
|---------|-----|
| Infinite 302 loop | Cookie domain must be `.example.com` (dot-prefixed) |
| Cross-namespace error | Add `--providers.kubernetescrd.allowCrossNamespace=true` to Traefik |
| 401 from Authentik | Verify outpost slug matches configured URL |

---

## Section 8: NetBird Zero-Trust

Already implemented. See [`scripts/netbird-ci-join.sh`](../scripts/netbird-ci-join.sh).

Key property: `ephemeral: true` keys auto-deregister CI peers ~10 minutes after container exits.

---

## Section 9: Full Installation Order

1. **Terraform** — VPC, EKS, Route53, KMS keys, S3 state backend
2. **Authentik + NetBird** — OIDC, SCIM, peer groups
3. **EKS namespaces + StorageClasses** — `gp3` required for CNPG
4. **Traefik + cert-manager** — ClusterIssuers (DNS-01 + HTTP-01 solvers)
5. **CNPG / Redis / NATS** — HA data services, pre-create Devtron databases
6. **SOPS keys + secrets** — `.sops.yaml` routing, tenant IAM roles scoped
7. **Devtron** — Helm install (`argo-cd.enabled: false`, external DBs)
8. **ArgoCD** — External controller, connect to Devtron
9. **GitOps repo** — Multi-tenant directory structure bootstrapped
10. **App onboarding** — WordPress/n8n with S3 offload + external DB
11. **Kyverno (Audit mode)** — Deploy `verifyImages` policies
12. **Final ingress exposure** — Apply `authentik-forwardauth` + `netbird-ip-allowlist` to all private endpoints

---

## Immediate 24-Hour Mitigation

Apply `netbird-ip-allowlist` middleware to **all internal IngressRoutes** before DNS records propagate:

```bash
kubectl apply -f gitops/platform/traefik/base/ingress-patterns.yaml
kubectl get middleware -n traefik
```

Verify no internal endpoint is reachable without a NetBird IP:

```bash
curl -I https://admin.internal.example.com
# Expected: 403 Forbidden (from non-NetBird IP)
```

---

*See also: [PRODUCTION_READINESS_ASSESSMENT.md](PRODUCTION_READINESS_ASSESSMENT.md) for the platform infrastructure assessment (Assessment 1).*
