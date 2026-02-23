# Disaster Recovery: etcd & Postgres Restores

This playbook outlines the steps to recover the core state of the Helix Platform in the event of catastrophic data loss.

## 💾 etcd Restore (Talos Control Plane)

**When to use:** Total loss of the Kubernetes control plane, accidental deletion of critical API objects, or cluster corruption.

### Prerequisites

- SSH/API access to a surviving Talos control plane node.
- AWS CLI configured or `talosctl` access to the backup S3 bucket (`s3://helix-etcd-backups`).

### 1. Locate the Snapshot

Identify the timestamp of the latest healthy snapshot in the bucket:

```bash
aws s3 ls s3://helix-etcd-backups/etcd/ | sort | tail -n 5
```

### 2. Isolate the Cluster

To prevent split-brain during restore, power down or cordon all *other* control plane nodes except the recovery node.

### 3. Restore the Snapshot

Using the Talos CLI, trigger an etcd restore pointing to the snapshot URL:

```bash
talosctl --talosconfig ./talosconfig etcd snapshot restore s3://helix-etcd-backups/etcd/<snapshot-name>.db
```

### 4. Rebuild the Cluster

Once the primary node is back online and `kubectl get nodes` is responsive:

1. Power cycle the remaining control plane nodes.
2. Force them to wipe their local state and join the recovered etcd cluster.

---

## 🐘 Postgres Restore (HA Cluster)

**When to use:** Accidental dropping of a critical database or table, corruption of LangGraph state, or complete Longhorn PV failure.

### Prerequisites

- Access to the cluster with `cluster-admin` privileges.
- The CloudNativePG (CNPG) plugin installed locally (`kubectl cnpg`).

### 1. Identify the Backup

Check the status of automated backups for the Postgres cluster.

```bash
kubectl -n platform get backups
```

### 2. Suspend Applications

Before restoring, scale down the orchestrator and any connected services to prevent data corruption during the restore window.

```bash
kubectl -n platform scale deploy n8n langgraph webhook --replicas=0
```

### 3. Initiate the Restore (Point-in-Time Recovery)

Use the CNPG plugin to create a new cluster from the backup object or a specific point in time (PITR).

*Example: restoring exactly 1 hour ago.*

```yaml
# recovery-cluster.yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: postgres-recovery
  namespace: platform
spec:
  instances: 3
  bootstrap:
    recovery:
      source: postgres-ha
      recoveryTarget:
        targetTime: "2026-02-23T17:00:00Z"
```

Apply the recovery manifest:

```bash
kubectl apply -f recovery-cluster.yaml
```

### 4. Cutover and Resume

1. Verify the `postgres-recovery` cluster is healthy and replication is active.
2. Update the PgBouncer configuration (or the primary `Service` selector) to point to the new `postgres-recovery` cluster.
3. Scale the applications back up and verify connectivity.

```bash
kubectl -n platform scale deploy n8n langgraph webhook --replicas=3
```
