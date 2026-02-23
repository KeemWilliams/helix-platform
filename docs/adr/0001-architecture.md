# ADR 0001: High-Performance AI Platform Architecture

## Status

Proposed

## Context

We need a unified platform to host low-latency web applications and AI inference workloads. The platform must prioritize security (Zero-Trust), reliability (GitOps), and performance (Edge + GPU inference).

## Decision

We will use:

- **Hetzner Cloud** for cost-effective compute.
- **Talos Linux** for an immutable, secure host OS.
- **Cilium** for eBPF-based networking and Gateway API.
- **Longhorn** for highly-available block storage.
- **Devtron/ArgoCD** for GitOps-driven application lifecycle management.

## Alternatives Considered

- **Managed K8s (GKE/EKS)**: High cost, less control over kernel tuning for low-latency.
- **Ubuntu/K3s**: High operational overhead for security hardening.

## Consequences

- **Positive**: Automated bootstrap, small attack surface, high performance.
- **Negative**: High initial complexity in CI/CD and Talos configuration.

---
**Owner**: Platform Architecture Team
