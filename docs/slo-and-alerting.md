# SLOs & Alerting Rules

This document defines our Service Level Objectives and the technical queries used to monitor them.

## 📈 Service Level Objectives (SLOs)

| Metric | Target | Error Budget | Monitoring Query |
| :--- | :--- | :--- | :--- |
| **API Availability** | 99.95% | 22m/mo | `sum(rate(http_requests_total{status!~"5.."}[5m]))` |
| **API Latency (P95)** | < 200ms | 0.05% overflow | `histogram_quantile(0.95, sum(rate(latency_bucket[5m])))` |
| **Inference Time** | < 5s (Llama3) | 1% overflow | `avg(inference_duration_seconds)` |
| **Queue Depth** | < 1000 items | N/A | `nats_server_msgs_pending` |

## 🚨 Critical Alerting Rules

### 1. High Error Rate

- **Condition**: Error rate > 1% for 5 minutes.
- **Action**: Page On-call.
- **Runbook**: Check `docs/runbook.md#5xx-errors`.

### 2. P95 Latency Breach

- **Condition**: P95 latency > 2s for 10 minutes.
- **Action**: Alert Slack #perf-alerts. Check `worker-high` pool saturation.

### 3. Storage Degraded

- **Condition**: Longhorn volume state != healthy.
- **Action**: Page Storage Lead.

---
**Primary Owner**: SRE Lead
