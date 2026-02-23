#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./tf-export-to-gitops.sh --tf-dir infra/envs/prod --workspace prod \
#     --out gitops/platform/egress/egress-values.yaml \
#     --branch chore/tf-outputs-prod \
#     --git-user "CI Bot" --git-email "ci-bot@example.com"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tf-dir) TF_DIR="$2"; shift 2;;
    --workspace) TF_WORKSPACE="$2"; shift 2;;
    --out) OUT_FILE="$2"; shift 2;;
    --branch) BRANCH="$2"; shift 2;;
    --repo-root) REPO_ROOT="${2:-.}"; shift 2;;
    --git-user) GIT_USER="${2:-ci-bot}"; shift 2;;
    --git-email) GIT_EMAIL="${2:-ci-bot@example.com}"; shift 2;;
    --sops) SOPS_CMD="${2:-sops}"; shift 2;;
    --help) echo "See header comments"; exit 0;;
    *) echo "Unknown arg: $1"; exit 1;;
  esac
done

: "${TF_DIR:?--tf-dir is required}"
: "${TF_WORKSPACE:?--workspace is required}"
: "${OUT_FILE:?--out is required}"
: "${BRANCH:=chore/tf-outputs}"
: "${REPO_ROOT:=.}"
: "${GIT_USER:=ci-bot}"
: "${GIT_EMAIL:=ci-bot@example.com}"
: "${SOPS_CMD:=sops}"

cd "$TF_DIR"

# Select workspace if using TF workspaces (optional)
if command -v terraform >/dev/null 2>&1; then
  if terraform workspace list >/dev/null 2>&1; then
    terraform workspace select "$TF_WORKSPACE" || terraform workspace new "$TF_WORKSPACE"
  fi
fi

# Export outputs as JSON
TF_JSON="$(mktemp)"
terraform output -json > "$TF_JSON"

# Map outputs you care about into a YAML structure
# Edit the jq keys below to match your terraform outputs (egress_ips, lb_ip, backup_bucket)
EGRESS_IPS_JSON=$(jq -r '.egress_ips.value // [] | @json' "$TF_JSON")
LB_IP=$(jq -r '.lb_ip.value // empty' "$TF_JSON" || true)
BACKUP_BUCKET=$(jq -r '.backup_bucket.value // empty' "$TF_JSON" || true)

mkdir -p "$(dirname "$OUT_FILE")"
cat > "${OUT_FILE}.tmp" <<EOF
# Auto-generated from Terraform outputs. Do not edit by hand.
egress:
  ips: ${EGRESS_IPS_JSON}
loadBalancer:
  ip: "${LB_IP}"
backups:
  bucket: "${BACKUP_BUCKET}"
EOF

# Encrypt with SOPS in-place to the target path
# Ensure SOPS is configured in CI (KMS/GPG keys available)
$SOPS_CMD --encrypt --output "${OUT_FILE}" "${OUT_FILE}.tmp"
rm -f "${OUT_FILE}.tmp" "$TF_JSON"

# Commit to git branch
cd "$REPO_ROOT"
git config user.name "$GIT_USER"
git config user.email "$GIT_EMAIL"
git checkout -b "$BRANCH"
git add "$OUT_FILE"
if git diff --cached --quiet; then
  echo "No changes to commit"
else
  git commit -m "chore: update gitops values from terraform outputs ($TF_WORKSPACE)"
  git push --set-upstream origin "$BRANCH"
  echo "Pushed branch $BRANCH. Open a PR to merge into the gitops branch watched by Devtron."
fi
