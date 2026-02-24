# Visual Architecture & Mermaid Governance

> **Platform Version:** v3.3 (Security-First)  
> **Lead Architect:** Wakeem Williams  

## Purpose

This directory houses the high-fidelity visual representations of the Helix Platform. These diagrams are treated as code: they are versioned, linted, and automatically rendered to SVG to ensure the technical vision remains synchronized with the implementation.

---

## 📂 Logical Structure

### 1. Project Diagrams (`docs/diagrams/`)

Focused technical views for engineers and operators:

- **[overview-full.mmd](./overview-full.mmd)**: The master system map with security interlinks.
- **[network.mmd](./network.mmd)**: Deep dive into zero-trust mesh, ingress, and egress.
- **[cluster.mmd](./cluster.mmd)**: Node pools, namespaces, and internal platform apps.
- **[failure-modes.mmd](./failure-modes.mmd)**: Operational runbook for triggers and recoveries.
- **[state-kyverno.mmd](./state-kyverno.mmd)**: Policy lifecycle states (Draft → Audit → Enforce).

### 2. Stakeholder Suite (`docs/architecture/`)

Persona-based documentation tailored for specific reviews:

- **[Master Architecture](../architecture/master-architecture.md)**: Canonical source of truth.
- **[Recruiter View](../architecture/recruiter-overview.md)**: Why this platform wins.
- **[Admin View](../architecture/network-admin-architecture.md)**: Security-focused infrastructure.

---

## 🛠️ Governance & Standards

- **Theme Consistency**: All diagrams use the custom "Base Dark" theme optimized for Helix (Deep Navy, Indigo, and Neon Green).
- **Security Interlinks**: Every diagram must explicitly show the relationship between functional components and security gates (Authentik/Kyverno/NetBird).
- **Automated Rendering**: SVGs are automatically regenerated using `mermaid-cli` (`mmdc`) on every commit to ensure documentation never drifts.

---

## 🔄 The Rendering Workflow

If you modify an `.mmd` file, you must refresh the SVG:

```bash
npx -y @mermaid-js/mermaid-cli -i file.mmd -o file.svg -t dark -b transparent
```

---
© 2026 Wakeem Williams. All Rights Reserved.
