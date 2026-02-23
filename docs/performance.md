# Low-Latency & Performance Playbook (v1.1)

This document outlines the optimization strategies used to maintain enterprise-grade P95 latency across the platform.

## ⚡ Top 16 Performance Practices

### 1. Edge Acceleration (Fast Path)

- **HTTP/3 (QUIC)**: Mandatory for all ingress to reduce handshake RTT.
- **Brotli Compression**: Enabled at Cloudflare with multi-tier compression (Edge + Gateway).
- **Edge Workers**: Use Cloudflare Workers for early-auth and cache-hit logic before hitting origin.

### 2. Database & State Optimization

- **PgBouncer Pooling**: Every application MUST use PgBouncer. No direct DB connections.
- **NVMe Pinning**: Database workloads are pinned to nodes with local NVMe storage using Taints/Affinities.
- **Redis Cache**: Hot-path lookups (User/Session) must check Redis before querying Postgres.

### 3. Asynchronous Decoupling (Slow Path)

- **Queue First**: Webhooks are enqueued to **NATS** immediately. Processing is handled by AI workers asynchronously.
- **KEDA Scaling**: Auto-scale AI inference workers based on queue depth, not CPU utilization.

## 📊 Performance Metrics & SLOs

| Metric | Target | Detection |
| :--- | :--- | :--- |
| **P95 API Latency** | < 200ms | Prometheus: `histogram_quantile(0.95, ...)` |
| **DB Query Latency** | < 10ms | Prometheus: `pg_stat_statements` |
| **Inference Latency** | < 5s | Grafana: `ollama_request_duration_seconds` |
| **Cache Hit Ratio** | > 85% | Redis: `redis_keyspace_hits_total` |

## 🧪 k6 Load Testing

Run the smoke test before every deployment:

```bash
docker run --rm -i grafana/k6 run - <infrastructure/scripts/smoke-test.js
```

## 🚨 Performance Alerts

- **High P95 Latency**: Alert if API P95 > 500ms for 5 minutes.
- **Cache Hit Drop**: Alert if Redis hit ratio falls below 70%.
- **Queue Backup**: Alert if NATS `lag` > 100 messages.
