# Infrastructure as Code (IaC) & Talos Bootstrap

This directory manages the underlying Hetzner infrastructure and the Talos Linux OS layer.

## 🛠️ Terraform Usage

1. **Initialize**: `terraform init`
2. **Plan**: `terraform plan -out=tfplan`
3. **Outputs**: Terraform produces `terraform-output.json` which is consumed by the Talos bootstrap scripts.

## 🐧 Talos Linux Bootstrap

1. **Image Build**: We use a custom Talos image with `iscsi-tools` (for Longhorn).
2. **Configuration**: Generate `controlplane.yaml` and `worker.yaml` using the Terraform IP outputs.
3. **Apply**: `talosctl apply-config --nodes <IP> --file <config>.yaml --insecure`.
4. **Bootstrap**: `talosctl bootstrap --nodes <CP1_IP>`.

## 📦 Key Outputs

- `api_lb_ip`: Used for `talosctl` and `kubectl` access.
- `app_lb_ip`: Main entry point for user traffic.
- `node_ips`: Grouped by pool (`App`, `AI`, `DB`).
