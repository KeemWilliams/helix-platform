variable "hcloud_token" {
  description = "Hetzner Cloud API Token"
  type        = string
  sensitive   = true
}

variable "ssh_keys" {
  description = "List of SSH key names/IDs deployed in Hetzner Cloud"
  type        = list(string)
  default     = []
}

variable "backup_region" {
  description = "Region for the object storage backups"
  type        = string
  default     = "eu-central-1"
}
