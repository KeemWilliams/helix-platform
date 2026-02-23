# Backup & Restore Strategy (v1.0)

This document defines the multi-tier backup architecture and recovery procedures for the platform.

## 📊 Backup Retention Matrix

| Asset | Frequency | Retention | Copies & Locations | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **etcd** | Hourly | 24h hourly; 7d daily | 2 copies: Local + Offsite S3 | Signed, encrypted snapshots; test monthly |
| **Postgres (DB)** | WAL continuous + Daily base | 14d baseline; 12m monthly | 3 copies: Local NVMe, S3, Offsite | Use WAL-G or pgBackRest; test PITR weekly |
| **Longhorn Vols** | Hourly or on change | 7d daily; 4w weekly | 2 copies: Replicas + S3 Snapshot | Encrypt snapshots; verify replica health |
| **Redis** | Daily | 7d | 2 copies: Local + Offsite | Rebuildable if non-critical cache |
| **Object Store** | Versioning Enabled | 90d Lifecycle | 3 copies: Primary, X-Region, WARM | Enable bucket immutability (WORM) |
| **GitOps Repo** | Commit history | Indefinite | 2 copies: Git host + S3 backup | SOPS keys stored separately in Vault |

## 🛠️ Verification Commands

### 1. etcd Snapshot (Talos)

```bash
# Create local snapshot
talosctl etcd snapshot save --nodes <cp-node-ip> snapshot.db

# Upload to S3
aws s3 cp snapshot.db s3://backups/etcd/$(date -u +%Y%m%dT%H%M%SZ)-snapshot.db
```

### 2. Postgres Base Backup (pgBackRest)

```bash
# Create full backup
pgbackrest --stanza=main --type=full backup

# Verify backup status
pgbackrest --stanza=main info
```

## 🧪 Restore Testing Cadence

- **Daily**: Automated smoke restore of one small dataset to ephemeral namespace.
- **Weekly**: Full PITR (Point-In-Time-Recovery) test for Postgres in staging.
- **Monthly**: Full etcd restore drill to a staging control plane.
- **Quarterly**: Disaster Recovery drill (simulate region loss) to measure RTO/RPO.

## 🛡️ Hardening Checklist

- [ ] **Encryption**: Every backup artifact must be encrypted at rest.
- [ ] **Signing**: Sign snapshots to prevent supply-chain tampering.
- [ ] **Immutability**: Enable S3 Object Lock for 30 days on critical backups.
- [ ] **Alerting**: Alert if age of the newest backup exceeds 2x the frequency.

## 🔄 Emergency Restore (Snippet)

### Restore Postgres to Staging

```bash
pgbackrest --stanza=main restore --delta --target-action=promote
```

### Restore etcd (Talos)

1. Download latest signed snapshot.
2. `talosctl etcd restore --snapshot <backup.snap> --nodes <target-ip>`.
3. Verify: `kubectl get nodes` should show cluster state matching the snapshot time.
