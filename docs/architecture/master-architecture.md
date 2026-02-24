# Master Architecture — Devtron Platform on Talos

**Owner:** platform-team  
**Last validated:** 2026-02-23  

This document is the **canonical architecture** for the platform: ingress, egress, zero‑trust, GitOps, CI/CD, secrets, data, observability, and Devtron/ArgoCD boundaries. All other docs (recruiter, network admin, platform engineer, ingress) are derived from this.

---

## High-level goals

- Multi‑tenant, production‑grade Kubernetes on Talos.
- GitOps‑driven delivery via ArgoCD, surfaced through Devtron.
- Zero‑trust networking with NetBird and Cilium default‑deny.
- Multi‑domain ingress with Traefik + cert‑manager + Authentik.
- Strong supply chain: SBOM, Trivy, cosign, Kyverno verifyImages.
- HA data plane: CNPG, Redis, Longhorn.
- Clear Terraform vs GitOps vs Devtron ownership.

---

## Platform architecture (full diagram)

```mermaid
flowchart LR

  %% CLASS DEFINITIONS
  classDef ext       fill:#1e293b,stroke:#94a3b8,stroke-width:1.5px,color:#cbd5e1,font-style:italic;
  classDef infra     fill:#0c4a6e,stroke:#0ea5e9,stroke-width:2px,color:#e0f2fe;
  classDef nodes     fill:#451a03,stroke:#f97316,stroke-width:1.5px,color:#fed7aa;
  classDef apps      fill:#1e1b4b,stroke:#818cf8,stroke-width:1.5px,color:#c7d2fe;
  classDef db        fill:#3b0764,stroke:#c084fc,stroke-width:2px,color:#f3e8ff;
  classDef sec       fill:#052e16,stroke:#4ade80,stroke-width:2px,color:#bbf7d0;
  classDef ci        fill:#1c1917,stroke:#f59e0b,stroke-width:1.5px,color:#fde68a;
  classDef obs       fill:#0c0a09,stroke:#fb923c,stroke-width:1.5px,color:#fed7aa;
  classDef remediate fill:#3f0714,stroke:#f43f5e,stroke-width:2px,color:#fecdd3;

  %% EXTERNAL & SOURCE
  subgraph EXT ["🌎 External Environment"]
    direction TB
    U(("User")):::ext
    Dev(("Developer")):::ext
    Partner(("Partner APIs")):::ext
    Proxies(("Proxy Pool")):::ext
    ObjStore[("Object Storage S3")]:::db
  end

  subgraph GIFLOW ["🔄 DevOps & CI/CD Lifecycle"]
    direction TB
    GH[("GitHub Repository")]:::ci
    CI[/"CI Runner\nGitHub Actions"/]:::ci
    GitOpsRepo[("GitOps Repo\nState Source of Truth")]:::ci
  end

  %% INFRASTRUCTURE
  subgraph INFRA ["☁️ Cloud Infrastructure (Terraform-Managed)"]
    direction TB
    LB(["Hetzner Load Balancer\npublic HTTPS only"]):::infra
    NAT(["NAT Egress\nFloating IPs"]):::infra
    DNS(["DNS Zone"]):::infra
    NetBirdMgmt(["NetBird Management\nControl Plane"]):::infra
    
    subgraph CI_ACCESS ["CI Security Path"]
      IAM{"IAM / OIDC Role\nno static keys"}:::sec
      Buckets[("S3 State Bucket\nnative tflock")]:::db
      KMS{"KMS Key\nencrypt state + SOPS"}:::sec
    end
  end

  %% KUBERNETES CLUSTER
  subgraph CLUSTER ["🛡️ Talos Kubernetes Cluster"]
    direction TB

    subgraph NETSEC ["🌐 Platform Networking & Security"]
      Cilium{"Cilium CNI\nL3-L4 network policy"}:::sec
      Traefik(["Traefik Ingress v3\nIngressRoute CRDs"]):::infra
      CertManager("cert-manager\nACME Let's Encrypt"):::sec
      Authentik{"Authentik OIDC\nForwardAuth outpost"}:::sec
      Kyverno{"Kyverno\nverifyImages admission"}:::sec
    end

    subgraph GITOPS ["🔄 Platform GitOps & Control Plane"]
      ArgoCD("ArgoCD\nexternal controller"):::apps
      Devtron("Devtron\nGitOps dashboard"):::apps
      Remediate("Remediation Service\nauto rollback PRs"):::remediate
    end

    subgraph POOLS ["💻 Node Pools"]
      InfraPool["Infra nodes"]:::nodes
      DBPool["DB nodes gp3 NVMe"]:::nodes
      ComputePool["Compute nodes"]:::nodes
      EgressPool["Egress nodes"]:::nodes
    end

    subgraph P_APPS ["📦 Internal Platform Apps"]
      Webhook("Webhook Receiver\nHMAC validated"):::apps
      Queue[("NATS / RabbitMQ\nmessage broker")]:::db
      LangGraph("LangGraph\norchestrator"):::apps
      Ollama("Ollama\nlocal LLM inference"):::apps
      Steel("Steel Browser Farm\nscraper egress only"):::apps
    end

    subgraph C_APPS ["🚀 Customer Workloads"]
      AppSvcs("Customer Application\nServices"):::apps
    end

    subgraph DATA ["💾 Stateful Storage (Persistent)"]
      CNPGPooler(["CNPG Pooler\nPgBouncer transaction mode"]):::db
      Postgres[("Postgres HA\nCloudNativePG Cluster")]:::db
      Redis[("Redis\nin-cluster cache")]:::db
      Longhorn[("Longhorn CSI\ngp3 block storage")]:::db
    end

    subgraph OBS ["📈 Observability Stack"]
      Prometheus("Prometheus"):::obs
      Grafana("Grafana"):::obs
      Loki("Loki"):::obs
    end
  end

  %% EGRESS TIER
  subgraph EGRESS ["📤 Secure Outbound Tier"]
    AIPod("AI / Scraper Pods"):::apps
  end

  %% JOURNEYS & FLOWS

  %% User Journey
  U        -->|"HTTPS public"| LB
  LB       -->|"HTTP/HTTPS"| Traefik
  Traefik  ==>|"SSO Gate"| Authentik
  Authentik -.->|"302 if unauthed"| U
  Authentik ==>|"ForwardAuth OK"| Webhook
  Authentik ==>|"ForwardAuth OK"| Devtron

  %% Developer Journey
  Dev      -->|"1. Git Push"| GH
  GH       -->|"2. Trigger CI"| CI
  CI       -->|"3. PR / Commit"| GitOpsRepo
  GitOpsRepo -.->|"4. Sync"| ArgoCD
  ArgoCD   -.->|"SOPS Decrypt"| KMS
  ArgoCD   -->|"5. Reconcile"| CLUSTER

  %% CI Access Flow
  CI  -.->|"OIDC assume role"| IAM
  IAM -->|"PutObject tflock"| Buckets
  IAM -->|"kms:Decrypt"| KMS
  CI  -.->|"ephemeral join"| NetBirdMgmt
  NetBirdMgmt -.->|"mesh peer"| InfraPool

  %% Egress Flow
  AIPod -->|"egress via"| EgressPool
  EgressPool -->|"NAT"| NAT
  NAT --> Partner
  NAT --> Proxies
  NAT --> ObjStore

  %% Internal Relationships
  CertManager -->|"ACME / certificates"| Traefik
  Authentik -.->|"ForwardAuth Middleware"| Traefik
  Webhook   -.->|"async enqueue"| Queue
  Queue     -->|"job dispatch"| LangGraph
  LangGraph -->|"inference"| Ollama
  LangGraph -->|"db write"| CNPGPooler --> Postgres
  LangGraph -->|"cache r/w"| Redis
  Steel     -->|"egress via"| EgressPool
  AppSvcs   -->|"metrics"| Prometheus
  
  %% Platform Operations
  Cilium      -->|"L3/L4 policy"| POOLS
  Kyverno     ==>|"verifyImages"| C_APPS
  Devtron     -.->|"Management"| ArgoCD
  Devtron     -.->|"OIDC identity"| Authentik
  Remediate   -.->|"auto rollback PR"| GitOpsRepo

  %% Cilium Segmentation
  subgraph SEG ["🔒 Cilium Zero-Trust Segmentation"]
    direction TB
    Zone1{"Platform NS\n(default-deny)"}:::sec
    Zone2{"App NS\n(default-deny)"}:::sec
    Zone3{"DB NS\n(default-deny)"}:::sec
  end
  NETSEC --> Zone1
  C_APPS --> Zone2
  DATA   --> Zone3
  Zone2  --> Zone1
  Zone2  --> Zone3

  %% LEGEND
  subgraph LEGEND ["📊 Legend"]
    direction LR
    L1(["Infra / Network"]):::infra
    L2("Application / Logic"):::apps
    L3{"Security / Policy"}:::sec
    L4[/"CI / DevOps"/]:::ci
    L5[("Database / State")]:::db
    L6("Observability"):::obs
  end

  %% CLICKABLE LINKS
  click Traefik "../../gitops/platform/traefik/" "Traefik manifests"
  click Authentik "../../gitops/platform/traefik/base/authentik-middleware.yaml" "Authentik ForwardAuth"
  click Kyverno "../../gitops/platform/policies/" "Kyverno policies"
  click ArgoCD "../../gitops/platform/" "GitOps platform"
  click Devtron "../../gitops/platform/devtron/" "Devtron values"
  click CNPGPooler "../../gitops/platform/cnpg/" "CNPG Pooler"
  click Postgres "../../gitops/platform/cnpg/" "CloudNativePG cluster"
```

---

## Ownership boundaries

- **Terraform (infra repo)**  
  - LB, NAT, DNS, NetBirdMgmt, IAM, Buckets, KMS, base Talos cluster.
- **GitOps (gitops repo via ArgoCD)**  
  - Traefik, cert‑manager, Cilium, Kyverno, CNPG, Redis, Longhorn, observability, platform apps.
- **Devtron**  
  - Application onboarding, app‑level Helm values, environment configs, deployment pipelines (if used), dashboards.

---

## Installation order (high level)

1. Terraform: network, LB, DNS, IAM, S3, KMS, NetBirdMgmt, Talos cluster.
2. Cluster bootstrap: Cilium, Longhorn, CNPG, Redis.
3. Traefik + cert‑manager + Authentik outpost.
4. ArgoCD install and GitOps bootstrap.
5. Devtron install (external CNPG/Redis/NATS wired).
6. Observability stack (Prometheus, Grafana, Loki).
7. Kyverno in audit → enforce.
8. App onboarding (internal + customer workloads).
9. Final ingress exposure and SSO enforcement.

---

## Links to audience-specific docs

- **[Cost, Time, and Complexity Analysis](./cost-time-complexity.md)** (Founder-Grade Assessment)
- [Recruiter Overview](file:///c:/Users/MSI%20LAPTOP/Documents/Projects/helix-platform/docs/architecture/recruiter-overview.md)
- [Network Admin View](file:///c:/Users/MSI%20LAPTOP/Documents/Projects/helix-platform/docs/architecture/network-admin-architecture.md)
- [Platform Engineer View](file:///c:/Users/MSI%20LAPTOP/Documents/Projects/helix-platform/docs/architecture/platform-engineer-architecture.md)
- [Multi-Domain Ingress Detail](file:///c:/Users/MSI%20LAPTOP/Documents/Projects/helix-platform/docs/architecture/multi-domain-ingress.md)
