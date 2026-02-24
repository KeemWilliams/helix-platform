# Platform Status

This page reflects the current operational state of the **Helix Platform** (powered by **Helix Stax**).

## Core Metrics

- **Uptime:** 99.99%
- **P95 Latency:** 42ms
- **5xx Error Rate:** 0.02%
- **ArgoCD Syncs:** 982
- **Deploys:** 128
- **Rollbacks:** 3

## Data Plane

- **CNPG:** Healthy
- **Redis Hit Rate:** 97%
- **Longhorn Volumes:** Healthy

## Zero Trust

- **NetBird Peers:** 14

## Observability

- **Grafana Dashboards:** 14
- **Prometheus Metrics Exported:** 842
- **Active Alerts:** 0

## Dashboard (Mermaid)

```mermaid
flowchart LR
    A[Uptime 99.99%] --> B[P95 Latency 42ms]
    B --> C[5xx Error Rate 0.02%]
    C --> D[ArgoCD Syncs 982]
    D --> E[Deploys 128]
    E --> F[Rollbacks 3]

    subgraph Data Plane
        G[CNPG Healthy]
        H[Redis Hit Rate 97%]
        I[Longhorn Healthy]
    end

    subgraph Zero Trust
        J[NetBird Peers 14]
    end

    subgraph Observability
        K[Grafana Dashboards 14]
        L[Prometheus Metrics 842]
        M[Active Alerts 0]
    end
```

---
© 2026 Wakeem Williams. All Rights Reserved.
筋
