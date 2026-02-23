# Staging Validation Checklist

This checklist must be successfully completed in the `staging` environment before any platform or GitOps changes are promoted to production. Copy and paste this into your PR.

## 📋 Pre-Flight Checks

- [ ] Devtron has successfully reconciled the PR branch in the `staging` environment.
- [ ] No `Degraded` or `OutOfSync` applications in the ArgoCD/Devtron UI for the `platform` project.

## 🔍 Validation Commands

Run these commands against the staging cluster. **All commands must return healthy statuses.**

### 1. Control Plane & Nodes

Verify the Talos control plane and worker nodes are responsive and ready.

```bash
talosctl --talosconfig ./envs/staging/talosconfig kubeconfig . && export KUBECONFIG=./kubeconfig
kubectl get nodes -o wide
```

### 2. Network & Policies

Verify Cilium policies are active and that the webhook can reach the message broker.

```bash
# Verify policies exist
kubectl -n platform get ciliumnetworkpolicies,ciliumegressnatpolicies

# Connectivity test
kubectl -n platform exec deploy/webhook -- curl -sS --fail http://queue:4222/health || true
```

### 3. Observability & Alerting

Verify Prometheus has loaded the latest rules and the monitoring stack is healthy.

```bash
# Verify rules
kubectl -n monitoring get prometheusrules -o yaml

# Verify pods
kubectl -n monitoring get pods -l app=prometheus -o wide
```

### 4. Application Health & Connectivity

Verify the core application components are running and the database pooler is accessible.

```bash
kubectl -n platform get deploy,sts,svc -l app=webhook,app=langgraph,app=pgbouncer
```

### 5. Egress & External Routing

Verify NAT and Egress proxies are routing correctly with stable IPs.

```bash
# Check terraform output for staging egress IPs
cd infra/envs/staging && terraform output egress_ips
```

## 🧪 Behavioral Smoke Test

- [ ] Send 100 simulated webhook events to the staging ingress endpoint.
- [ ] Confirm events are processed by the orchestrator (n8n/LangGraph) within 5 minutes.
- [ ] Verify no new severity `warning` or `critical` alerts fired in AlertManager during the test.

---
*If any checks fail, halt promotion, diagnose the issue in staging, and update the PR.*
