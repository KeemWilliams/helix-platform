variable "hcloud_token" { sensitive = true }
variable "network_zone" { default = "eu-central" }
variable "egress_ips_count" { default = 1 }

resource "hcloud_network" "main" {
  name     = "platform-net"
  ip_range = "10.0.0.0/16"
}

resource "hcloud_network_subnet" "nodes" {
  network_id   = hcloud_network.main.id
  type         = "cloud"
  network_zone = var.network_zone
  ip_range     = "10.0.1.0/24"
}

# --- Inbound Load Balancer ---
resource "hcloud_load_balancer" "ingress" {
  name               = "ingress-lb"
  load_balancer_type = "lb11"
  location           = "nbg1"
}

resource "hcloud_load_balancer_network" "ingress" {
  load_balancer_id = hcloud_load_balancer.ingress.id
  network_id       = hcloud_network.main.id
  ip               = "10.0.0.2"
}

# --- Outbound Egress (Stable IPs) ---
resource "hcloud_floating_ip" "egress" {
  count         = var.egress_ips_count
  type          = "ipv4"
  home_location = "nbg1"
  description   = "Stable egress IP for AI/Scrapers"
}

output "network_id" { value = hcloud_network.main.id }
output "egress_ips" { value = hcloud_floating_ip.egress.*.ip_address }
output "ingress_lb_ip" { value = hcloud_load_balancer.ingress.ipv4 }
