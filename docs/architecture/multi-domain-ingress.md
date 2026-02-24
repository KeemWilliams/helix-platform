# Multi-Domain Ingress — Traefik, cert-manager, Authentik

## Domain types

- **Public apps:** `app.example.com`, `devtron.example.com`.
- **Private apps:** `internal.example.com`, `n8n.internal.example.com`.
- **Customer domains:** `customer.com`, `app.customer.com`.
- **Wildcards:** `*.tenant.example.com`.

## Traefik

- Uses **IngressRoute** and **Middleware** CRDs.
- Routes based on:
  - Host (domain)
  - Path
  - Middleware chain (Auth, rate limit, headers, etc.).
- For private apps:
  - No public ingress, or
  - Ingress restricted to NetBird IP ranges / internal networks.

## cert-manager

- **ClusterIssuers**:
  - HTTP‑01 for public domains.
  - DNS‑01 for wildcards or external DNS providers.
- Certificates are automatically requested and renewed.
- Traefik uses these certificates via annotations or TLS configuration.

## Authentik

- Acts as **ForwardAuth** provider for Traefik.
- Per‑app or per‑path protection:
  - Devtron UI
  - ArgoCD UI (if exposed)
  - internal tools (n8n, dashboards, admin panels).
- OIDC used for SSO; groups/claims can map to app roles.

## Patterns

- **Public app (WordPress/Ghost):**
  - Traefik IngressRoute with public host.
  - cert‑manager HTTP‑01.
  - Optional Authentik for admin paths.

- **Private app (n8n, internal dashboards):**
  - No public DNS, or internal DNS only.
  - Access via NetBird mesh or VPN.
  - Optional Authentik for user auth.

- **Customer domain:**
  - DNS‑01 challenge if customer controls DNS.
  - Dedicated IngressRoute per customer.
  - Optional per‑customer middleware (rate limits, headers).

This model supports **flexible multi‑tenant ingress** while keeping security and automation intact.
