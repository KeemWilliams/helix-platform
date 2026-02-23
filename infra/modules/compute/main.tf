variable "network_id" {}
variable "ssh_keys" { type = list(string) }

locals {
  talos_image = "talos-v1.6.7" # Pre-baked or custom Talos image ID
}

# --- Control Plane Pool ---
resource "hcloud_server" "cp" {
  count       = 3
  name        = "cp-${count.index}"
  image       = local.talos_image
  server_type = "cx21"
  location    = "nbg1"
  ssh_keys    = var.ssh_keys

  network {
    network_id = var.network_id
  }

  labels = {
    "node-role" = "control-plane"
    "pool"      = "master"
  }
}

# --- Worker Pool (Standard) ---
resource "hcloud_server" "worker_std" {
  count       = 2
  name        = "worker-std-${count.index}"
  image       = local.talos_image
  server_type = "cx31"
  location    = "nbg1"
  ssh_keys    = var.ssh_keys

  network {
    network_id = var.network_id
  }

  labels = {
    "node-role" = "worker"
    "pool"      = "standard"
  }
}

# --- Worker Pool (High Compute) ---
resource "hcloud_server" "worker_high" {
  count       = 1
  name        = "worker-high-01"
  image       = local.talos_image
  server_type = "ccx21" # Dedicated vCPU for AI
  location    = "nbg1"
  ssh_keys    = var.ssh_keys

  network {
    network_id = var.network_id
  }

  labels = {
    "node-role" = "worker-high"
    "pool"      = "ai"
  }
}

output "cp_ips" { value = hcloud_server.cp.*.ipv4_address }
output "worker_ips" { value = concat(hcloud_server.worker_std.*.ipv4_address, hcloud_server.worker_high.*.ipv4_address) }
