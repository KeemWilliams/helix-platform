# Helix Platform Runbooks

## 1. Emergency Rollback Procedure (GitOps / ArgoCD)

If a recent GitOps commit breaks platform reconciliation or triggers a rollout failure, follow this procedure to safely revert:

### Step 1: Automated Revert via CI

1. Navigate to your repository's **Actions** tab.
2. If `post-merge-health.yml` detected the failure, an **Auto revert** PR should already be open.
3. Review and merge the revert PR. Devtron (ArgoCD) will automatically reconcile back to the stable state.

### Step 2: Manual Revert (If CI Fails)

If the automated revert failed or the GitHub Action runner is down:

```bash
# Clone the repository locally
git clone git@github.com:yourorg/yourrepo.git && cd yourrepo

# Locate the offending commit in the gitops/platform tree
git log --oneline gitops/platform/

# Revert the commit and push
git revert <faulty-commit-sha>
git push origin main
```

### Step 3: Force ArgoCD Sync

If ArgoCD is stuck or taking too long to poll the repository:

```bash
# Sync the platform application manually
kubectl -n argocd get applications
kubectl config set-context --current --namespace=argocd
# Force sync (requires ArgoCD CLI)
argocd app sync platform-manifests --force
```

---

## 2. Emergency Network Allow Rule (Default-Deny Lockout)

If `default-deny` policies are actively blocking Devtron controllers or the Repo Server from reaching GitHub or the Kubernetes API Server, apply the temporary emergency allow rule.

### Apply the Emergency Policy

```bash
# This will temporarily allow broad egress from the argocd namespace
kubectl apply -f gitops/platform/network-policies/emergency-allow.yaml
```

### Verify Recovery

```bash
# Check if the repo server can now fetch the manifests
kubectl -n argocd logs deploy/argocd-repo-server | tail -n 50

# Check if syncs are progressing
kubectl -n argocd get applications -o wide
```

### Remove the Emergency Policy

**CRITICAL**: Do not leave this policy active. Once the specific, granular egress rules are fixed in the repository and reconciled by Devtron, delete the emergency policy.

```bash
kubectl delete -f gitops/platform/network-policies/emergency-allow.yaml
```
