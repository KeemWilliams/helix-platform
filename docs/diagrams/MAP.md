# Architecture Component Map

This document bridges the components modeled in `docs/diagrams/overview-full.mmd` to their concrete repository paths, owners, and immediate runbook links.

## 🗺️ Component Mapping

| Diagram Component | Repository Path | Owner | Runbook Link |
| :--- | :--- | :--- | :--- |
| **LB**, **NAT**, **DNS** | `infra/modules/networking/` | @infra-lead | `docs/runbook.md#networking` |
| **IAM** | `infra/modules/security/` | @security-lead | `docs/runbook.md#iam-rotation` |
| **Buckets** | `infra/modules/storage/` | @infra-lead | `docs/runbook.md#storage` |
| **InfraPool**, **DBPool** | `infra/modules/compute/` | @infra-lead | `docs/runbook.md#node-pools` |
| **Cilium** | `gitops/platform/cilium/` | @network-lead | `docs/runbook.md#cilium` |
| **Traefik** | `gitops/platform/traefik/` | @platform-owner | `docs/runbook.md#traefik` |
| **CertManager** | `gitops/platform/cert-manager/` | @security-lead | `docs/runbook.md#tls-certs` |
| **Devtron** | `gitops/platform/devtron/` | @platform-owner | `docs/runbook.md#devtron` |
| **Remediate** | `gitops/platform/remediation/` | @sre-lead | `docs/runbook.md#remediation` |
| **Webhook**| `gitops/platform/webhook/`| @app-lead | `docs/runbook.md#webhook` |
| **Queue**| `gitops/platform/queue/`| @app-lead | `docs/runbook.md#queue` |
| **LangGraph**| `gitops/platform/langgraph/`| @ai-lead | `docs/runbook.md#langgraph` |
| **Ollama** | `gitops/platform/ollama/` | @ai-lead | `docs/runbook.md#ollama` |
| **Steel** | `gitops/platform/steel-browser/` | @ai-lead | `docs/runbook.md#steel-browser` |
| **PgBouncer**, **Postgres** | `gitops/platform/postgres/` | @db-owner | `docs/runbook.md#postgres-restore` |
| **Redis** | `gitops/platform/redis/` | @db-owner | `docs/runbook.md#redis` |
| **Longhorn** | `gitops/platform/longhorn/` | @db-owner | `docs/runbook.md#longhorn-recovery` |
| **Prometheus** | `gitops/platform/observability/prometheus/` | @sre-lead | `docs/runbook.md#observability` |
| **Grafana** | `gitops/platform/observability/grafana/` | @sre-lead | `docs/runbook.md#observability` |
| **Loki**, **AlertManager** | `gitops/platform/observability/loki/` | @sre-lead | `docs/runbook.md#observability` |

## 🔄 Review Cadence

- **Infra Lead**: Monthly review of node pool capacity and egress quotas.
- **Security Lead**: Quarterly audit of network policies and secret rotation.
- **SRE Lead**: Bi-weekly SLO impact analysis and dashboard validation.
