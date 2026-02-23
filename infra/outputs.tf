output "cp_ips" {
  value       = module.compute.cp_ips
  description = "IP addresses of the Talos Control Plane nodes"
}

output "worker_ips" {
  value       = module.compute.worker_ips
  description = "IP addresses of the Talos Worker nodes"
}

output "ingress_lb_ip" {
  value       = module.networking.ingress_lb_ip
  description = "Public IP of the Hetzner Application Load Balancer"
}

output "egress_ips" {
  value       = module.networking.egress_ips
  description = "Stable outbound Floating IPs used for egress proxy"
}

output "backup_bucket" {
  value       = module.storage.backup_bucket_name
  description = "Bucket name used for etcd, postgres, and longhorn backups"
}
