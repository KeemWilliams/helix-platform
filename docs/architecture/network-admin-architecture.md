# Network Admin Architecture — Zero-Trust, Ingress, Egress, Segmentation

## Ingress path

- **Edge:** Cloudflare WAF (optional) → Hetzner Load Balancer (HTTPS only).
- **Cluster entry:** Traefik Ingress v3 using IngressRoute CRDs.
- **Auth:** Authentik ForwardAuth middleware enforces OIDC before apps.
- **TLS:** cert‑manager issues and renews Let’s Encrypt certificates.

Traffic flow:

1. `User → LB → Traefik`
2. Traefik applies routing + middleware.
3. ForwardAuth to Authentik; unauthenticated users get 302 to `auth.example.com`.
4. Authenticated traffic is forwarded to internal services (Devtron, Webhook, apps).

## Zero-trust mesh (NetBird)

- Kubernetes API is **not publicly exposed**.
- NetBird control plane manages WireGuard peers.
- CI runners join with **short‑lived tokens**.
- Admin/SRE devices join with **long‑lived identities**.
- Only NetBird peers can reach:
  - Kubernetes API
  - ArgoCD UI
  - other internal endpoints as needed.

## Egress path

- AI/scraper pods and other egressing workloads send traffic to an **egress node pool**.
- NAT gateway provides **stable public IPs**.
- Outbound targets:
  - Partner APIs
  - Proxy pools
  - Object storage (S3) for WAL/archive.

## Segmentation (Cilium)

- Namespaces grouped into:
  - Platform NS (default‑deny)
  - App NS (default‑deny)
  - DB NS (default‑deny)
- CiliumNetworkPolicies:
  - Allow App NS → Platform NS (specific ports).
  - Allow App NS → DB NS (Postgres/Redis).
  - Drop all other east‑west traffic by default.

## DNS

- External DNS zones and records managed via Terraform.
- Internal service discovery via cluster DNS (CoreDNS).
- cert‑manager uses HTTP‑01 or DNS‑01 depending on domain type.

This model gives you **tight ingress control**, **explicit egress**, and **strong east‑west segmentation**.
