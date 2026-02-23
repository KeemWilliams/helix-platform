# Devtron Integration Analysis: Missing Items, Needs, & Conflicts

Based on the official [devtron-labs/devtron](https://github.com/devtron-labs/devtron) repository architecture and our current platform hardening progress, here is a breakdown of potential conflicts, overlaps, and missing configuration needs.

## 1. Potential Conflicts

### Standalone ArgoCD vs Devtron's ArgoCD Bundle

- **The Conflict**: In `docs/ROLLOUT_SEQUENCE.md`, we defined a step to manually install standard ArgoCD manifests (`argoproj/argo-cd/stable/manifests/install.yaml`) into the `argocd` namespace.
- **Devtron's Approach**: Devtron integrates ArgoCD natively. The provided Devtron Helm installation command uses `--set argo-cd.enabled=true`, which instructs the `devtron-operator` to install and configure its own instance of ArgoCD.
- **Resolution**: Installing standalone ArgoCD and then installing Devtron with `argo-cd.enabled=true` will cause conflicts. We should either drop the standalone ArgoCD installation and purely install the Devtron Helm chart, OR configure Devtron to connect to the external ArgoCD instance (if supported without losing Devtron UI features). The recommended path is usually to let Devtron manage the ArgoCD installation using its Helm charts.

### Database Overlap (PostgreSQL / NATS / Redis)

- **The Conflict**: Devtron has its own stateful components (PostgreSQL, NATS-server, Redis) that it deploys by default. We have explicitly built out our own highly available CloudNativePG (CNPG) PostgreSQL cluster and NATS server.
- **Resolution**: We need to heavily customize the Devtron `values.yaml` when applying its Helm chart so that it points to our external `platform-db-cluster-rw` endpoint (and external NATS/Redis) instead of spinning up its non-HA defaults.

## 2. CI/CD Overlaps (Redundant features)

### CI Promotion Pipelines

- **The Overlap**: We just built a comprehensive GitHub Actions CI pipeline (`promote-to-gitops.yml`) to build images, verify cosign signatures, and push GitOps PRs.
- **Devtron's Approach**: Devtron is built to be a centralized dashboard for CI/CD natively (*"a No Code software delivery workflow"*). It can handle building, pushing, and deploying directly without GitHub Actions.
- **Resolution**: This isn't a hard conflict, but an architectural choice. If your team prefers the GitHub-driven developer experience (opening PRs, relying on GitHub Actions for logic), Devtron will essentially function mostly as a read-only observability dashboard on top of ArgoCD. If you want to use Devtron to its full potential, you might move the CI build logic directly into Devtron's pipeline configurations.

### Security Scanning

- **The Overlap**: We built Trivy and Cosign scanning directly into Github Actions, and Kyverno on the cluster to block unsigned images.
- **Devtron's Approach**: Devtron integrates Trivy and Clair natively into its CI workflows via `--set security.trivy.enabled=true`.
- **Resolution**: Ensure Devtron's integrated scanners do not conflict with our Kyverno admission controllers. If an image is built inside Devtron, it must be signed with Cosign in the Devtron pipeline before Kyverno will admit it into the cluster.

## 3. What We Are Missing

- **Ingress Configuration**: Devtron deploys a dashboard service (`devtron-service`). Currently, Devtron docs suggest accessing it via a raw `LoadBalancer` IP. We need to wrap Devtron in a `Traefik` Ingress route (`dashboard.helix.example.com`) to secure it behind our SSO/RBAC.
- **OIDC/Dex Integration**: Devtron uses `dexidp/dex` internally for SSO. We need to configure it with your identity provider (e.g., Google Workspace, GitHub, Okta) for your team to access the Devtron UI securely.

## Summary Recommendation

Before executing Phase 1 of `ROLLOUT_SEQUENCE.md`:

1. **Do not install raw ArgoCD manifests.** Change the installation to specifically use the Devtron Helm chart.
2. **Author a specific Devtron `values.yaml`** overriding the database, NATS, and Redis configs to use the HA instances we built.
