terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "aws" {
  region = var.backup_region
}

module "networking" {
  source           = "./modules/networking"
  hcloud_token     = var.hcloud_token
  network_zone     = "eu-central"
  egress_ips_count = 1
}

module "compute" {
  source     = "./modules/compute"
  network_id = module.networking.network_id
  ssh_keys   = var.ssh_keys
}

module "storage" {
  source             = "./modules/storage"
  backup_bucket_name = "platform-backups-${var.backup_region}"
}
