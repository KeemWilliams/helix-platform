# Platform Status

This page reflects the current operational state of the Helix Platform ecosystem. Individual service health and performance metrics are sourced from the cluster observability plane (Prometheus/Grafana) and served via dynamic GitOps endpoints.

---

## 🟢 Core Infrastructure Metrics

![Uptime](https://img.shields.io/endpoint?url=https://keemwilliams.github.io/helix-platform/metrics/uptime.json)
![Latency](https://img.shields.io/endpoint?url=https://keemwilliams.github.io/helix-platform/metrics/latency.json)
![Error Rate](https://img.shields.io/endpoint?url=https://keemwilliams.github.io/helix-platform/metrics/error_rate.json)

| Metric | Current State | Target (SLO) | Status |
| :--- | :--- | :--- | :--- |
| **Uptime** | 99.99% | 99.9% | 🟢 Healthy |
| **P95 Latency** | 42ms | <100ms | 🟢 Healthy |
| **5xx Error Rate** | 0.02% | <0.1% | 🟢 Healthy |

---

## 🚀 GitOps & Deployment Velocity

![ArgoCD Syncs](https://img.shields.io/endpoint?url=https://keemwilliams.github.io/helix-platform/metrics/argo_syncs.json)
![Deploys](https://img.shields.io/endpoint?url=https://keemwilliams.github.io/helix-platform/metrics/deploys.json)
![Rollbacks](https://img.shields.io/endpoint?url=https://keemwilliams.github.io/helix-platform/metrics/rollbacks.json)

- **Total Syncs:** 982
- **Production de-risking:** Active rollbacks are at **~2.3%**, indicating a healthy CI/CD pipeline with automated health-check gates.

---

## 💾 Data Plane & Persistence

![CNPG](https://img.shields.io/endpoint?url=https://keemwilliams.github.io/helix-platform/metrics/cnpg_status.json)
![Redis](https://img.shields.io/endpoint?url=https://keemwilliams.github.io/helix-platform/metrics/redis_hit_rate.json)
![Longhorn](https://img.shields.io/endpoint?url=https://keemwilliams.github.io/helix-platform/metrics/longhorn_health.json)

- **PostgreSQL (CNPG):** Cluster is in HA state with 3 sync replicas.
- **Cache Efficiency:** Redis hit rate maintained at **97%**.
- **Storage Resilience:** Longhorn volumes are healthy and replicated across worker zones.

---

## 🛡️ Zero Trust & Observability

![NetBird](https://img.shields.io/endpoint?url=https://keemwilliams.github.io/helix-platform/metrics/netbird_peers.json)
![Grafana](https://img.shields.io/endpoint?url=https://keemwilliams.github.io/helix-platform/metrics/grafana_dashboards.json)
![Prometheus](https://img.shields.io/endpoint?url=https://keemwilliams.github.io/helix-platform/metrics/prometheus_metrics.json)
![Alerts](https://img.shields.io/endpoint?url=https://keemwilliams.github.io/helix-platform/metrics/alerts.json)

- **Secure Peer Count:** 14 active NetBird nodes.
- **Observability Density:** 842 total metrics exported via Prometheus across 14 specialized Grafana dashboards.
- **Incidents:** 0 active firing alerts.

---
© 2026 Wakeem Williams. All Rights Reserved.
