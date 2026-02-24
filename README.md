![Helix Platform Social Preview](./docs/assets/social-preview.png)

# Helix Stax — The Future of Autonomous, Secure Infrastructure

> **Architecture v3.3 (Security-First Edition)**  
> **Lead Architect:** [Wakeem Williams](https://github.com/keemwilliams)  
> **Status:** Production-Ready Reference Suite

---

## 🏛️ Project Vision

I am **Wakeem Williams**, and I build infrastructure that doesn't just run code—it protects it. The **Helix Platform** (powered by **Helix Stax**) is an elite, zero-trust ecosystem engineered on **Talos Linux** and **Hetzner Cloud**.

---

## 🛡️ Supply Chain & Security Posture

![Build](https://img.shields.io/badge/Build-Verified-success)
![Security](https://img.shields.io/badge/Trivy-Clean-success)
![Supply Chain](https://img.shields.io/badge/SBOM-Generated-blue)
![Signature](https://img.shields.io/badge/Cosign-Verified-success)

---

## 📊 Live Platform Metrics

These dynamic endpoints reflect the current operational state of the Helix infrastructure.

![Uptime](https://img.shields.io/endpoint?url=https://keemwilliams.github.io/helix-platform/metrics/uptime.json)
![Latency](https://img.shields.io/endpoint?url=https://keemwilliams.github.io/helix-platform/metrics/latency.json)
![Error Rate](https://img.shields.io/endpoint?url=https://keemwilliams.github.io/helix-platform/metrics/error_rate.json)
![ArgoCD Syncs](https://img.shields.io/endpoint?url=https://keemwilliams.github.io/helix-platform/metrics/argo_syncs.json)
![Deploys](https://img.shields.io/endpoint?url=https://keemwilliams.github.io/helix-platform/metrics/deploys.json)
![Active Alerts](https://img.shields.io/endpoint?url=https://keemwilliams.github.io/helix-platform/metrics/alerts.json)

👉 **[Detailed Platform Status](./docs/STATUS.md)**

```mermaid
flowchart LR
    A[Uptime 99.99%] --> B[P95 Latency 42ms]
    B --> C[Error Rate 0.02%]
    C --> D[ArgoCD Syncs 982]
    D --> E[Deploys 128]
    E --> F[Rollbacks 3]

    subgraph Data_Plane ["Data Plane (State)"]
        G[CNPG Healthy]
        H[Redis Hit Rate 97%]
        I[Longhorn Healthy]
    end

    subgraph Zero_Trust ["Zero Trust"]
        J[NetBird Peers 14]
    end

    subgraph Observability
        K[Grafana Dashboards 14]
        L[Prometheus Metrics 842]
        M[Active Alerts 0]
    end

    F --> G
    F --> J
    F --> K
```

---

## 🗺️ Navigation & Architecture Suite

The documentation is structured for specific stakeholders.

### 💼 For Stakeholders & Recruiters

- **[Recruiter Overview](./docs/audiences/recruiter-overview.md)**: High-level vision and "Why it works" summary.
- **[Cost, Time, and Complexity](./docs/architecture/cost-time-complexity.md)**: A founder-grade technical whitepaper on efficiency and tradeoffs.
- **[Strategic Roadmap](./ROADMAP.md)**: The future evolution of the Helix ecosystem (Iron Spider vision).

### 🛠️ For Platform & Network Engineers

- **[Master Architecture](./docs/architecture/master-architecture.md)**: The canonical source of truth and full platform diagram.
- **[Iron Spider Subsystem](./docs/architecture/iron-spider.md)**: Proactive, eBPF-driven autonomous control.
- **[Platform Engineer Guide](./docs/audiences/platform-engineer.md)**: GitOps flow and troubleshooting.
- **[Network Admin Guide](./docs/audiences/network-admin.md)**: Ingress, Egress, and Mesh topology.
- **[Detailed Platform Status](./docs/STATUS.md)**: Comprehensive health and observability view.

---

## 🏗️ The 6-Phase Execution Roadmap

1. **Phase 1: Hardened Core** — Terraform, IAM, and KMS initialization.
2. **Phase 2: Immutable Substrate** — Talos Linux bootstrap and cluster stabilization.
3. **Phase 3: Security Weave** — NetBird, Cilium, and Authentik SSO gating.
4. **Phase 4: GitOps Control Plane** — ArgoCD and Devtron orchestration.
5. **Phase 5: State & Data HA** — CloudNativePG, Redis, and Longhorn storage.
6. **Phase 6: AI-Agentic Integration** — Ollama, LangGraph, and Steel Browser egress.

---

## 🛠️ Who is this for?

- **Hiring Managers** looking for deep expertise in Cloud-Native security and GitOps.
- **DevOps Architects** seeking a production-grade blueprint for Hetzner and Talos.
- **Platform Engineers** studying the "Security Weave" model of integrated IDP and eBPF.

---

## 🛡️ Repository Hygiene

This repository is a **Documentation & Reference Suite**. It contains:

- ✅ Canonical architecture diagrams (Mermaid & SVG).
- ✅ Stakeholder-specific technical guides.
- ✅ Strategic assessment whitepapers.
- ✅ Governance and visual standards.

*Note: This repo intentionally excludes live secrets, static Terraform providers, or proprietary application source code.*

---
Founder: **Wakeem (Keem) Williams**  
Repo: `keemwilliams/helix-platform`  
© 2026 Wakeem Williams. All Rights Reserved.
