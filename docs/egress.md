# Scraping & AI Egress Strategy (v1.0)

This document defines the architecture for safe, reliable, and auditable outbound traffic from AI agents and scraping workloads.

## 🌐 Egress Architecture

To ensure stable identity and prevent cluster-wide leaks, all outbound traffic follows the **Egress Gateway Pattern**.

### 1. Controlled Egress Path

- **Fixed IPs**: Scraping traffic is routed through a dedicated pool of nodes or a NAT Gateway to provide stable outbound IPs for external allowlisting.
- **Egress Gateway**: We use **Envoy** or **Cilium Egress Gateway** to SNAT traffic from the `ai` and `scraping` namespaces.
- **Micro-segmentation**: Only pods labeled `role: scraper` or `role: ai-agent` can reach the egress gateway.

### 2. Scraping Architecture & Tooling

- **Primary Engine: Steel Browser**: We leverage **Steel Browser** (Apache-2.0) for high-performance agentic automation. It provides session management, stealth plugins, and a built-in API.
- **Dedicated Pool**: Run Steel on the `worker-high` node pool with public routing.
- **Queue-Driven**: Scrape jobs are enqueued in **NATS**.

## 🛡️ Security & Egress Policies

### Default-Deny Egress

Every namespace starts with a `default-deny` egress policy.

### Scraper Allow-list (Cilium Example)

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: scraper-egress-allow
  namespace: ai
spec:
  endpointSelector:
    matchLabels:
      role: scraper
  egress:
    - toEndpoints:
        - matchLabels:
            app: egress-gateway
      toPorts:
        - ports:
            - port: "3128"
              protocol: TCP
```

## 📊 Observability & SLOs

| Metric | Target | Detection |
| :--- | :--- | :--- |
| **Egress Success Rate** | > 98% | Prometheus: `http_client_requests_total` |
| **External Call P95** | < 2s | Prometheus: `http_client_duration_seconds` |
| **Proxy Error Rate** | < 5% | Proxy Logs: `upstream_reset_events` |
| **Egress Volume** | < 1TB/mo | Cloud Provider Billing / OTel Metrics |

## 🧪 Verification & Acceptance

- **Synthetic Scrape**: CI job that contact 3 representative targets and asserts presence of specific DOM elements.
- **Illegal Destination Test**: Attempt to reach an unlisted IP from a scraper pod; verify connection timeout.
- **Rate Limit Test**: Burst 100 requests to a test endpoint; verify 429 handling and exponential backoff.
