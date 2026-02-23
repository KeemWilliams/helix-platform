Title: gitops: <short summary of change> (e.g., add network policy for webhook->queue)

## Summary

Briefly describe what this PR changes and why (1–3 sentences).

## Files changed

List the main files/paths changed:

- gitops/platform/network-policies/allow-webhook-to-queue.yaml
- gitops/platform/observability/prometheusrules/queue.rules.yaml
- docs/diagrams/overview-full.mmd
- docs/diagrams/MAP.md

## Motivation and Context

Explain the operational reason, risk mitigations, and expected impact.

## Staging validation plan

Steps to validate in staging (must be executed before promoting to production):

1. Devtron will reconcile branch `staging` -> verify manifests applied.
2. Run verification commands below and paste outputs in this PR.
3. Smoke test: send 100 webhook events and confirm processing within 5 minutes.

## Verification commands (copy outputs into PR)

### Cluster / nodes

```bash
talosctl --talosconfig ./talosconfig kubeconfig . && export KUBECONFIG=./kubeconfig
kubectl get nodes --show-labels
```

### Network policies

```bash
kubectl -n platform get ciliumnetworkpolicies,ciliumegressnatpolicies
kubectl -n platform exec deploy/webhook -- curl -sS --fail http://queue:4222/health || true
```

### Observability

```bash
kubectl -n monitoring get prometheusrules platform-queue-rules -o yaml
kubectl -n monitoring get pods -l app=prometheus -o wide
```

### App health

```bash
kubectl -n platform get deploy,sts,svc -l app=webhook,app=langgraph,app=pgbouncer
```

## Rollback plan

If validation fails:

1. Revert this PR.
2. Devtron will reconcile the revert; confirm resources return to previous state.
3. If rollback fails, follow docs/runbook.md#rollback-procedure and page on-call.

## Owners and reviewers

- **Network**: @network-lead
- **SRE / Observability**: @sre-lead
- **DB**: @db-owner
- **Platform / GitOps**: @gitops-owner

## Checklist (required)

- [ ] Diagram changes included? If yes:
  - [ ] Updated `.mmd` file(s) committed
  - [ ] Rendered `.svg` included OR CI render workflow will produce preview artifacts
  - [ ] `docs/diagrams/MAP.md` updated if topology or owners changed
  - [ ] Owner(s) listed in `docs/diagrams/MAP.md` have been requested for review
- [ ] Verification outputs pasted above
- [ ] Owner approvals obtained from all listed owners
- [ ] Staging validation completed

## Notes

Any additional context, links to runbooks, or follow-up tasks.
