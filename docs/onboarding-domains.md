# Customer Domain Onboarding Guide

Use this guide to onboard external customer domains (e.g., `www.customer.com`) to the platform using our automated TLS/ACME pipeline.

## 🔗 DNS Configuration Options

### 1. CNAME (Recommended)

Ask the customer to point their CNAME to our primary ingress target:

- `www.customer.com` -> `ingress-target.example.com`

### 2. A-Record (Legacy)

If CNAME is not possible, provide our Anycast IP:

- `www.customer.com` -> `1.2.3.4`

## 🛡️ TLS Verification

We use **cert-manager** with **Let's Encrypt**. For HTTP-01 validation, the DNS change must be propagated. For DNS-01 (if using Cloudflare/Hetzner), no action is needed from the customer besides the initial pointer.

## 📧 Sample Email to Customer
>
> "To enable your custom domain on our platform, please add the following DNS record:
>
> - TYPE: CNAME
> - HOST: www
> - VALUE: ingress-target.example.com"
