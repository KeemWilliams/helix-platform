# Terraform outputs → GitOps (egress values) CI job

## Purpose

Export selected Terraform outputs (egress IPs, LB IP, backup bucket, registry info) and publish them into the GitOps tree as a SOPS-encrypted YAML so Devtron/Argo can reconcile platform manifests that depend on these values.

## Required inputs (CI environment)

- **Terraform credentials** for the infra repo (cloud provider credentials).
- **Terraform workspace** or directory containing the target environment (e.g., `infra/envs/prod`).
- **SOPS keys** available to the CI runner (KMS/GCP KMS/AWS KMS/GPG) configured for encryption.
- **Git credentials** with permission to push branches and open PRs (use a machine user or `GITHUB_TOKEN` with repo write).
- **Repository layout**: CI must run from the monorepo root or be able to clone both infra and gitops repos.

## Required secrets (set in CI)

- `TF_VAR_*` or cloud provider secrets used by Terraform
- `SOPS_KMS_ARN` or equivalent KMS/GPG access configured for sops
- `GIT_TOKEN` or use `GITHUB_TOKEN` with write permission
- `GIT_USER` (optional) e.g., "github-actions[bot]"
- `GIT_EMAIL` (optional) e.g., "github-actions[bot]@users.noreply.github.com"

## Permissions needed

- **Terraform**: ability to run `terraform output -json` against the target workspace
- **SOPS**: encrypt using configured KMS/GPG keys
- **Git**: create branches and push commits to the repo that Devtron watches
- **Optional**: permission to open PRs via API if your workflow creates PRs automatically

## CI job steps (high level)

1. Checkout infra repo and ensure correct Terraform workspace selected.
2. Run `terraform output -json` and extract required keys (`egress_ips`, `lb_ip`, `backup_bucket`, `registry`).
3. Render `egress-values.yaml` from a template using the extracted values.
4. Encrypt the YAML with SOPS:

   ```bash
   sops --encrypt --output gitops/platform/egress/egress-values.yaml ./egress-values.yaml
   ```

5. Create a branch, commit the encrypted file, and push the branch.
6. Open a PR against the branch Devtron watches (optional) or push directly to the branch Devtron reconciles per your policy.

## Example GitHub Actions step

```yaml
- name: Export TF outputs and publish to GitOps
  env:
    TF_DIR: infra/envs/prod
    TF_WORKSPACE: prod
    OUT_FILE: gitops/platform/egress/egress-values.yaml
    BRANCH: chore/tf-outputs-prod
  run: |
    chmod +x scripts/tf-export-to-gitops.sh
    scripts/tf-export-to-gitops.sh --tf-dir "$TF_DIR" --workspace "$TF_WORKSPACE" \
      --out "$OUT_FILE" --branch "$BRANCH" --repo-root "${{ github.workspace }}" \
      --git-user "github-actions[bot]" --git-email "github-actions[bot]@users.noreply.github.com"
```

## Verification after CI runs

- Confirm branch pushed and PR opened (if applicable).
- Confirm SOPS file decrypts locally with your keys:

  ```bash
  sops --decrypt gitops/platform/egress/egress-values.yaml | yq .
  ```

- Confirm Devtron/Argo reconciles the updated values:
  - Check Argo app sync status for `platform-manifests`.
  - Verify resources that depend on egress IPs or LB IPs are updated.

## Rollback and safety

- If the CI job produces incorrect values, revert the PR or branch. Devtron will reconcile the revert.
- Keep a short manual approval step in CI if your org requires human review before promoting infra outputs to production.

## Troubleshooting

- **SOPS encryption errors**: ensure KMS/GPG keys are available to the runner and SOPS config is correct.
- **Git push failures**: verify `GIT_TOKEN` permissions and branch protection rules.
- **Devtron sync failures**: check Argo/Devtron logs and ensure network policies allow Devtron components to operate.

## Contacts

- **Infra owner**: @infra-owner
- **Platform owner**: @platform-owner
- **GitOps owner**: @gitops-owner
