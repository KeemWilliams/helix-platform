# Traefik Helm Chart Analysis: Gaps, Conflicts & Alignment

Based on the [traefik/traefik-helm-chart](https://github.com/traefik/traefik-helm-chart) repository and our current Devtron and platform network architecture, here is a breakdown of critical compatibility considerations.

## 1. v2 vs v3 API Conflict (Breaking Change)

### The Conflict

Starting with chart version **v28+**, the Traefik Helm chart defaults to **Traefik Proxy v3**. This uses the `IngressRoute` Custom Resource Definition (CRD) approach rather than the classic Kubernetes `Ingress` API.

- **The Risk**: Our current `values.devtron.custom.yaml` specifies:

  ```yaml
  ingress:
    className: "traefik"
  ```

  This assumes standard Kubernetes `Ingress` objects. If the installed Traefik chart was upgraded past `v28+`, the standard `Ingress` objects will still work, but access to advanced Traefik features (middleware chaining, HSTS enforcement, mTLS headers) requires migrating to `IngressRoute` CRDs.

- **The Solution**: Decide on your Traefik version now:
  - **If using Traefik Proxy v3 (recommended)**: Migrate all ingress definitions to `IngressRoute` and `Middleware` CRDs. Update `values.devtron.custom.yaml` to use `IngressRoute` annotations.
  - **If staying on Traefik Proxy v2**: Pin your Helm chart to `v27.x` explicitly to avoid accidental upgrades.

## 2. CRDs Ownership Conflict with GitOps

### The Conflict

The Traefik chart ships with multiple CRDs like `IngressRoute`, `Middleware`, `TLSOption`, etc.

- **The Risk**: ArgoCD/Devtron has a known limitation: it may try to reconcile CRD resources (like `IngressRoute`) and fail if Helm installed those CRDs as part of the chart. CRDs managed by Helm and simultaneously watched by ArgoCD can cause resource conflicts if both try to own the same resource at the same time.

- **The Solution**:
  - Install Traefik via a dedicated Helm-only App in Devtron (not tracked by ArgoCD resource health checks for the CRDs themselves).
  - Or, pre-install the CRDs separately before deploying Traefik, so Devtron tracks Pod-level resources but not the CRD spec itself.

## 3. Missing Configuration: Pilot and Dashboard Exposure

### The Gap

By default, the Traefik Helm chart exposes the **Traefik dashboard** on port `9000` via an internal service. Without explicit protection, this can leak internal routing topology and entrypoint metadata.

- **The Solution**: Add the following to your Traefik `values.yaml` overlay:

  ```yaml
  ingressRoute:
    dashboard:
      enabled: false # Disable default dashboard exposure
  ports:
    traefik:
      expose:
        default: false # Do not expose the admin port via LoadBalancer
  ```

## 4. What We Have Right (Alignment)

- Our `docs/ROLLOUT_SEQUENCE_PHASE1_HELM.md` already specifies installing Traefik as a gateway for the Devtron dashboard.
- Our Cilium `CiliumNetworkPolicies` are compatible with Traefik as an ingress controller since Cilium operates at L3/L4 and Traefik operates at L7.
- Our OIDC middleware configuration uses standard Traefik `ForwardAuth` middleware, which is fully supported in both v2 and v3.

## Summary Recommendations

1. **Pin Traefik chart version** to `v27.x` (Proxy v2) or explicitly upgrade to `v28+` (Proxy v3) and migrate all `Ingress` definitions to `IngressRoute` CRDs. Do not leave the version unpinned.
2. **Disable the Traefik dashboard** in production values.
3. **Install Traefik CRDs before the Traefik Helm chart** when GitOps (Devtron/Argo) is managing the namespace. This avoids CRD ownership races.
4. **Update `gitops/platform/devtron/values.devtron.custom.yaml`** to replace the `Ingress` annotations with `IngressRoute`-specific annotations once you decide on the v3 approach.
