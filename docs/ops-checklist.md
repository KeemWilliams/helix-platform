# Operational Checklists & Cadence

This document tracks recurring tasks required to maintain cluster health and security.

## 🌅 Daily Checks

- [ ] **Sync Status**: All Devtron Applications are `Synced` and `Healthy`.
- [ ] **Error Rates**: HTTP 5xx rate < 0.1% across primary ingress.
- [ ] **Queue Depth**: AI Queue (`NATS`) has no significant backlog.
- [ ] **Resource Pressure**: No nodes in `DiskPressure` or `MemoryPressure`.

## 📅 Weekly Tasks

- [ ] **Restore Drill**: Restore a single DB table from S3 to verify backup integrity.
- [ ] **OS Updates**: Check for new Talos Linux versions (`talosctl upgrade`).
- [ ] **CVE Scan**: Review `trivy` dashboard for new vulnerabilities in running images.

## 🌑 Monthly Drills

- [ ] **Full Restore**: Deploy a secondary "shadow" cluster using Terraform and restore full state.
- [ ] **Chaos Experiment**: Simulate a node pool failure and verify HPA and Longhorn replica recovery.
- [ ] **Certificate Audit**: Verify upcoming expirations for internal and customer domains.

## 🕒 Maintenance Log

| Date | Task | Result | Operator |
| :--- | :--- | :--- | :--- |
| 2026-02-23 | Plan v3.8 Baseline | Success | Antigravity |

---
**Primary Owner**: On-call Lead
