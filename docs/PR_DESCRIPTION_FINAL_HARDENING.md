Title: chore: final operational readiness and platform hardening sweep

## Summary

Completes the final operational readiness sweep before enabling `default-deny` network policies. This PR introduces automated disaster recovery verification, Grafana dashboard skeletons for capacity planning, PR link/MAP enforcement, chaos automation manifests, and a complete image supply chain verification pipeline (Cosign + Kyverno).

## Files changed

- `gitops/platform/network-policies/*` (Devtron allow rules)
- `gitops/platform/observability/prometheusrules/*` (DB capacity & Queue alerts)
- `gitops/platform/policies/kyverno-image-signing.yaml` (Kyverno Enforce)
- `.github/workflows/verify-dr-restore.yml` (Automated Postgres Restore CI)
- `.github/workflows/sign-and-publish-image.yml` (Cosign Signing CI)
- `.github/workflows/verify-image-signature.yml` (Signature Gate CI)
- `.github/workflows/check-links-and-map.yml` (PR Link Checker)
- `gitops/platform/observability/grafana/platform-capacity-dashboard.yaml`
- `tests/chaos/manifests/consumer-restart-job.yaml`

## Motivation and Context

To safely lockdown the cluster (`default-deny`) and move to production, we must ensure Devtron can still reconcile, images are signed and verified to prevent supply-chain attacks, capacity alerts proactively warn of saturation, and automated restores prove our recovery posture.

## Staging validation plan (Checklist)

1. **Devtron sync health**: Confirm `argocd-application-controller` logs show successful syncs.
2. **Kyverno audit**: Verify `require-cosign-signed-images` is active and check `kyverno` logs for dropped images.
3. **Prometheus alerts**: Verify `platform-db-capacity-rules` and `platform-queue-rules` are loaded.
4. **DR CI Job**: Trigger `verify-dr-restore.yml` in staging and confirm success.
5. **Chaos run**: Apply `consumer-restart-job.yaml` and verify consumer recovery and queue depth.

## Verification commands (copy outputs into PR)

### Argo / Devtron Status

```bash
kubectl -n argocd get applications -o wide
# Ensure STATUS is Synced and HEALTH is Healthy
```

### Kyverno & Image Signing

```bash
kubectl get clusterpolicy require-cosign-signed-images -o yaml
# Monitor for blocked unsigned payloads in staging:
kubectl -n kyverno logs deploy/kyverno | tail -n 50
```

### Observability

```bash
kubectl -n monitoring get prometheusrules -o wide
kubectl -n monitoring exec deploy/prometheus -- prometheus-query 'sum(nats_stream_msgs_pending)'
```

## Rollback plan

- **Devtron Sync Failure**: Apply the temporary broad Argo egress allow rule. If still failing, revert this PR.
- **Kyverno Blocking Valid Images**: Patch `require-cosign-signed-images` to `validationFailureAction: audit`, then re-sign and re-promote.
- **Alert Storm**: Pause chaos experiment, revert Prometheus rules, evaluate thresholds.

## Owners and reviewers

- **Infra / TF outputs**: @infra-owner
- **Platform / GitOps**: @gitops-owner
- **SRE / Observability**: @sre-lead
- **DB / Recovery**: @db-owner
- **Security**: @security-lead

## Checklist (required)

- [ ] `docs/diagrams/MAP.md` updated matches current architecture
- [ ] Rendered diagram SVG attached/committed
- [ ] Verification outputs pasted above
- [ ] Staging validation completed successfully
- [ ] Owner approvals obtained
