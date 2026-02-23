# Policy Enforcement (OPA / Conftest)

We use **Open Policy Agent (OPA)** and **Conftest** to enforce architectural and security guardrails during the CI/CD process.

## 🛡️ Policy Zones

1. **Infrastructure (Terraform)**: Block creation of public LBs without WAF.
2. **Kubernetes (Manifests)**: Deny pods running as `root` or without resource limits.
3. **Security**: Block ingress rules that expose management ports to the internet.

## 🚀 How Policies are Enforced

- **CI Gating**: Every PR runs `conftest test` against the manifests.
- **Failures**: If a policy is violated, the PR is blocked until the manifest is compliant.

## 📝 Example Rule (Deny No-Resource-Limits)

```rego
package main

deny[msg] {
  input.kind == "Deployment"
  not input.spec.template.spec.containers[_].resources.limits
  msg = "Deployments must define resource limits."
}
```

---
**Primary Owner**: Security Lead
