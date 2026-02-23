# Terraform Integration Analysis: Gaps, Best Practices, & Conflicts

Based on the [hashicorp/terraform](https://github.com/hashicorp/terraform) repository capabilities and our current GitOps platform architecture, here is an analysis of how Terraform interacts with our systems, potential conflicts, and missing operational guardrails.

## 1. Architectural Boundaries (The "State" Conflict)

### The Conflict: Overlapping Provisioners

Terraform possesses providers for Kubernetes (`hashicorp/kubernetes`) and Helm (`hashicorp/helm`), allowing it to install cluster applications. Devtron (via ArgoCD) is designed to do exactly the same thing.

- **The Risk**: If you provision a Helm release or Kubernetes ConfigMap via Terraform, and then Devtron or ArgoCD attempts to reconcile or modify that exact same resource, the two systems will endlessly fight each other, resulting in severe configuration drift and deployment failures.
- **The Solution**: Maintain a strict "Hard Boundary".
  - **Terraform owns underlying infrastructure**: VPCs, Subnets, the Kubernetes Cluster (EKS/GKE/Talos), IAM roles, Security Groups, and Cloud storage buckets.
  - **Devtron/GitOps owns cluster payloads**: Helm releases, namespaces, network policies, applications, and in-cluster databases (CNPG).
  - *Never* use the `terraform-provider-kubernetes` or `terraform-provider-helm` to deploy applications if Devtron is managing the cluster.

## 2. Secrets Management & State Security

### The Gap: Plaintext State Files

Terraform stores infrastructure state in a binary JSON-like format. **This state file contains all infrastructure secrets and outputs in plaintext**, regardless of whether you marked the variables as `sensitive=true`.

- **The Risk**: If the Terraform state file is committed to Git, or stored in an unsecured S3 bucket, any user with read access immediately gains access to database passwords, IAM keys, and TLS certificates.
- **The Solution**:
  - Ensure the Terraform backend is configured to use remote storage (e.g., S3 or GCS) with **Encryption at Rest** fully forced.
  - Implement **State Locking** (e.g., AWS DynamoDB table) in your backend block to prevent two CI runners from executing `terraform apply` simultaneously and corrupting the environment.

## 3. Drift Detection vs Continuous Reconciliation

### The Missing Component: Autonomous Drift Healing

- **Devtron/ArgoCD**: Operates on a continuous reconciliation loop. If someone manually deletes a pod or edits a service, ArgoCD instantly reverts it back to the Git state.
- **Terraform**: Operates on a "Triggered" state. We wrote `.github/workflows/terraform-plan.yml` to run on PRs, but if someone logs into the AWS console and manually deletes a security group, Terraform will *not* automatically fix it until the next time `terraform apply` is explicitly run.
- **The Solution**:
  1. Add a scheduled `cron` job to the GitHub Actions workflow that runs `terraform plan -detailed-exitcode` daily. If it detects drift, it should fire an alert to your SRE Slack channel or OpsGenie.
  2. Alternatively, utilize an operator like Terraform Controller (tf-controller) or Atlantis if you require continuous reconciliation of cloud hardware.

## 4. The Bridge (Already Solved)

In many infrastructures, the biggest problem is passing variables (like dynamic LoadBalancer IPs or VPC CIDRs) from Terraform into Kubernetes manifests.

- **Our Setup**: Because we previously implemented `scripts/tf-export-to-gitops.sh`, we successfully closed this gap. Terraform outputs are strictly exported, encrypted via SOPS, and pushed into the `gitops/platform/egress/egress-values.yaml` path for Devtron to safely consume. This is the optimal, decoupled approach.

## Summary Recommendation

To finalize Terraform's integration:

1. **Audit your Terraform codebase**: Ensure you have zero instances of `kubernetes_*` or `helm_release` resources.
2. **Lock the Backend**: Ensure your `backend "s3"` or `backend "gcs"` block explicitly requires locks and encryption.
3. **Automate Drift Detection**: We should add a scheduled job to evaluate Terraform state against reality to catch shadow-IT or manual cloud-console edits.
