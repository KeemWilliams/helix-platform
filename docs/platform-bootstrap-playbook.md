# Platform Layer Bootstrap Playbook

This playbook defines the exact sequence to take a raw Talos cluster to a fully functional platform with Networking, Storage, and Ingress.

## 🛠️ Prerequisites

- [ ] Talos cluster bootstrapped (`kubectl get nodes` returns nodes).
- [ ] `talosctl` and `kubectl` installed locally.
- [ ] Devtron / ArgoCD installed in `devtron-cd`.

## 🚀 Step 1: Install Networking (Cilium)

Cilium is the foundation. It must be installed before other pods can communicate reliably.

```bash
# Apply the ArgoCD Application
kubectl apply -f gitops/platform/cilium/application.yaml

# Verification
kubectl get pods -n kube-system -l k8s-app=cilium
cilium status --wait
```

## 🚀 Step 2: Install Storage (Longhorn)

Required for stateful workloads like Postgres and Redis.

```bash
# Apply the Application
kubectl apply -f gitops/platform/longhorn/application.yaml

# Verification
kubectl get pods -n longhorn-system
kubectl get storageclass
```

## 🚀 Step 3: Install Ingress & TLS (Traefik & Cert-Manager)

Exposes services to the public internet securely.

```bash
# Apply manifests
kubectl apply -f gitops/platform/cert-manager/application.yaml
kubectl apply -f gitops/platform/traefik/application.yaml

# Verification
kubectl get pods -n cert-manager
kubectl get pods -n traefik
kubectl get svc -n traefik # Get the LoadBalancer IP
```

## 🚀 Step 4: Configure Cluster Issuers

You must configure a Let's Encrypt issuer after cert-manager is healthy.

```yaml
# yaml/issuers/letsencrypt-prod.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: traefik
```

---
**Next Step**: Once these are verified, proceed to `gitops/platform/ollama` and `gitops/platform/flowise`.
