# Dashboard Ownership & Design

This document tracks our Grafana dashboards and the golden signals they monitor.

## 📊 Core Dashboards

| Dashboard | Description | Owner |
| :--- | :--- | :--- |
| **System Overview** | Global RPS, Errors, and Cluster Health. | SRE Lead |
| **AI Workloads** | Inference latency (P95), GPU utilization. | AI Lead |
| **Edge & CDN** | Cache hit ratio, WAF blocks, Top IPs. | Network Lead |
| **Stateful Ops** | Postgres lag, NATS queue depth, Longhorn IO. | DB Lead |

## 🛠️ Adding New Panels

1. **Target**: Use Prometheus datasource for metrics, Loki for logs.
2. **Standard**: Use HSL color palettes for consistency (Green=Healthy, Red=Alert).
3. **Thresholds**: Define `Critical` and `Warning` visual markers on all P95 graphs.

## 🔗 Trace Integration

Where possible, include a link to **Gerafana Tempo** using the `trace_id` from the log panel to jump directly into the request timeline.

---
**Primary Owner**: Observability Lead
