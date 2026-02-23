Title: feat(ci): add automated image promotion pipeline and smoke tests

## Summary

Adds an automated workflow to safely promote signed images into the GitOps repository. This pipeline includes Cosign verification before updating manifests and triggers an automated smoke test script after rollouts.

## Added components

- `.github/workflows/promote-to-gitops.yml` (CI job to verify signature, update GitOps, and open PR)
- `tests/smoke/promote-smoke.sh` (Health check script for promoted deployments)

## Verification commands (copy outputs into PR)

### PR Smoke Test Results

```bash
./tests/smoke/promote-smoke.sh <app_name> <namespace>
# Example: ./tests/smoke/promote-smoke.sh n8n platform
# Ensure rollout status is clear and healthz endpoint returns HTTP 200/OK
```

### Signature Verification Success

```bash
# Verify the promotion job successfully validated the signature:
cosign verify --key cosign.pub ghcr.io/yourorg/n8n:sha-xxx
```

## Rollback plan

- If the smoke test fails post-merge, revert the promotion PR and allow Devtron to sync the previous operational image tag.

## Owners and reviewers

- **Platform / GitOps**: @gitops-owner
- **Security**: @security-lead
