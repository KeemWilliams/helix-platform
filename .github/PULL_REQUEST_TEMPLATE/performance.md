# 🚀 Performance & Security PR Checklist

Please complete this checklist before submitting your PR.

## ⚡ Performance Impact

- [ ] Have you verified the P95 latency impact of this change?
- [ ] Are all database queries using **PgBouncer** or connection pooling?
- [ ] Does this PR introduce any synchronous external network calls?
- [ ] **k6 Validation**: Have you run a local smoke test? (`docker run k6 run scripts/smoke-test.js`)

## 🛡️ Security Check

- [ ] Have all new secrets been encrypted with **SOPS**? (`.enc.yaml`)
- [ ] Does the new container image have a valid **Cosign** signature?
- [ ] Are any new services isolated with a **CiliumNetworkPolicy**?
- [ ] Has **Authentik** OIDC been configured for any new management UIs?

## 📦 Artifacts

- [ ] SBOM generated and attached to image?
- [ ] Vulnerability scan (Trivy) passed with Zero "Critical" CVEs?
