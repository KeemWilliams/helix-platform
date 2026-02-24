# Terraform Drift Detection: Setup Guide

This document outlines the required setup for the automated Terraform Drift Detection workflow located at `.github/workflows/terraform-drift-detection.yml`.

## 1. Required GitHub Secrets

To authenticate the workflow securely via OIDC, configure the following repository secret:

- `TF_ASSUME_ROLE_ARN`: The ARN of the AWS IAM Role that GitHub Actions will assume.

## 2. Remote Backend Constraints

Before running the workflow, verify that your `infra/envs/prod` (or corresponding path) contains the following backend constraints:

- **State Storage**: S3 Bucket (e.g., `helix-terraform-state-bucket`) with Server-Side Encryption (SSE-S3 or SSE-KMS) enabled.
- **State Locking**: DynamoDB Table configured to prevent concurrent applies.

## 3. Least-Privilege IAM Policy for GitHub Actions

The assumed role must only have permissions to read the state file, acquire the state lock, and describe the current AWS resources (Read-Only access for planning). It should generally **not** have write access to mutate resources unless explicitly running an apply pipeline.

**Example Minimal IAM Policy**:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::helix-terraform-state-bucket",
        "arn:aws:s3:::helix-terraform-state-bucket/prod.tfstate"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:us-east-1:ACCOUNT_ID:table/terraform-state-lock"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*",
        "iam:List*",
        "iam:Get*",
        "s3:Get*",
        "rds:Describe*",
        "eks:DescribeCluster"
        // Add other ReadOnly actions based on your Terraform resources
      ],
      "Resource": "*"
    }
  ]
}
```

## 4. Remediation on Drift

When drift is detected, an automated GitHub Issue will be created containing the detailed plan output.

- Review the issue to identify exactly what changed in the cloud console.
- **To accept the drift**: Update the Terraform code to match the new reality and merge the PR.
- **To revert the drift**: Run `terraform apply` locally or via a separate CI pipeline to revert the console changes back to the Git source of truth.
