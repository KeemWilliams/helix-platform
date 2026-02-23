# Emergency Operational Runbook (v1.1)

This is the **Source of Truth** for on-call operators. Use these commands to stabilize the cluster during an incident.

## 🆘 Immediate Triage (First 5–10 Minutes)

1. **Check Cluster Health**
   - `talosctl kubeconfig . && export KUBECONFIG=./kubeconfig`
   - `kubectl get nodes -o wide`
   - `kubectl get pods -A --field-selector=status.phase!=Running`
2. **Check Cloud Console**: Verify Hetzner Cloud for node status and load balancer health.
3. **Check Monitoring**: Look at Prometheus alerts and Loki logs for recent errors.

## 🛠️ Out-of-Band Access Methods

### 1. Cloud Provider Console (Recommended First)

Use the Hetzner Cloud Console to view instance serial/console logs or boot into **Rescue Mode**. Fastest way to see kernel panics or network misconfigurations.

### 2. NetBird / Bastion

If the control plane is reachable but node SSH/API is not, use the **NetBird** VPN mesh to reach the private network.

- `ssh -J user@bastion user@10.x.x.x`

## 🐧 Cluster-Level Recovery (Talos)

| Scenario | Command |
| :--- | :--- |
| **Node Health** | `talosctl --talosconfig ./talosconfig health` |
| **Fetch Logs** | `talosctl --talosconfig ./talosconfig logs --follow <node-ip>` |
| **Restart Kubelet** | `talosctl --talosconfig ./talosconfig service restart kubelet --nodes <node-ip>` |
| **Reapply Config** | `talosctl apply-config --nodes <node-ip> --file worker.yaml` |
| **Reboot Node** | `talosctl reboot --nodes <node-ip>` |

## 📦 Storage & Longhorn Recovery

- **Check Health**: `kubectl -n longhorn-system get pods`
- **Degraded Replicas**: Use Longhorn UI to failover. **Do not** immediately delete volumes.
- **Port-Forward UI**: `kubectl -n longhorn-system port-forward svc/longhorn-frontend 8080:80`

## 🛠️ Devtron / GitOps Emergency Ops

| Scenario | Action | Command |
| :--- | :--- | :--- |
| **Pause Sync** | Stop reconciliation | `kubectl -n devtron annotate application <app> argocd.argoproj.io/sync-wave=-1` |
| **Scale Down** | Kill controller | `kubectl -n devtron scale deployment devtron-controller --replicas=0` |
| **Rollback** | Git Revert | `git revert <bad-commit> && git push origin main` |
| **Verify Sync** | Check status | `kubectl -n devtron get applications.argoproj.io <app> -o jsonpath='{.status.sync.status}'` |
| **Rotate Token**| Revoke SA | `kubectl -n devtron delete secret devtron-sa-token` |

## 📉 Escalation Matrix

1. **Level 1**: On-call SRE.
2. **Level 2**: Platform/Infra Lead.
3. **Level 3**: Security Lead (if compromise suspected).

---

## 🏁 Emergency Checklist (Copy-Paste)

1. `talosctl kubeconfig . && export KUBECONFIG=./kubeconfig`
2. `kubectl get nodes -o wide`
3. `kubectl get pods -A --field-selector=status.phase!=Running`
4. `talosctl health --talosconfig ./talosconfig`
5. `kubectl -n longhorn-system get volumes`

## <a name="stuck-webhook-job"></a>🚨 Stuck Webhook Job

**Severity:** P2 (affects processing but not entire platform)

**Symptoms:**

- Webhook receives requests but jobs remain in Queue with status "pending" or "retrying".
- n8n or LangGraph consumers show high restart counts or zero consumption.
- Queue depth metric (nats_queue_depth) rising above threshold.

**Immediate checks (5 minutes)**

1. Verify webhook accepted the request:
   - `kubectl -n platform logs deploy/webhook --since=10m | grep <request-id>`
   - Confirm webhook returned 202/200 and logged idempotency key.

2. Check queue health and consumers:
   - `kubectl -n platform get pods -l app=queue`
   - `kubectl -n platform exec -it svc/queue -- nats stream info <stream>` (or use management UI)
   - Check consumer lag and pending messages.

3. Check orchestrator (n8n / LangGraph) status:
   - `kubectl -n platform get pods -l app=n8n`
   - `kubectl -n platform logs deploy/n8n --since=15m | tail -n 200`
   - Look for errors: DB connection refused, auth errors, OOMKilled.

4. Check DB pool usage:
   - `kubectl -n platform exec -it deploy/pgbouncer -- psql -c "SHOW POOLS;"` (or check metrics)
   - Confirm PgBouncer has available connections.

**Quick mitigations (10–20 minutes)**
A. If consumers are crashed / OOM:

- Scale up consumer replicas temporarily:
     `kubectl -n platform scale deploy n8n --replicas=3`
- Check memory limits; if OOM, increase limits in a safe increment and redeploy.

B. If DB connections exhausted:

- Restart PgBouncer to clear stale connections:
     `kubectl -n platform rollout restart deploy/pgbouncer`
- If Postgres is overloaded, scale read replicas or reduce consumer concurrency.

C. If queue backlog is large and consumers healthy:

- Temporarily increase consumer replicas or throttle producer (webhook) via rate limit:
     `kubectl -n platform patch deploy webhook -p '{"spec":{"template":{"metadata":{"annotations":{"rate-limit":"true"}}}}}'`

D. If egress or external API calls are failing (n8n external steps):

- Check EgressProxy logs and NAT egress IPs.
- If proxy credentials expired, rotate via Vault and restart affected pods.

**Post‑incident (within 24 hours)**

1. Record incident in `docs/postmortems/` with timeline, root cause, and action items.
2. Add or adjust Prometheus alerts:
   - `queue_depth > X` for 5m
   - `consumer_restart_rate > Y`
   - `pgbouncer_free_connections < Z`
3. Add a test to `tests/smoke/` that simulates a webhook -> full workflow and verifies completion.
4. If remediation was manual, add an automated playbook to `platform-scripts/remediation/playbooks/` for safe restart/scale steps.

**Owner:** @platform-owner
**Escalation:** If unable to restore within 30 minutes, page on-call SRE and follow full incident runbook.
