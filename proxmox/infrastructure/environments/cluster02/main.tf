terraform {
  required_version = ">= 1.5.0"

  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "~> 3.0"
    }
  }
}

provider "proxmox" {
  pm_api_url          = var.pm_api_url
  pm_api_token_id     = var.pm_api_token_id
  pm_api_token_secret = var.pm_api_token_secret
  pm_tls_insecure     = var.pm_tls_insecure
}

module "network" {
  source   = "../../modules/network"
  bridge   = var.bridge
  vlan_tag = var.vlan_tag
}

module "storage" {
  source       = "../../modules/storage"
  storage_name = var.storage_name
}

module "vm" {
  for_each        = var.vms
  source          = "../../modules/vm"
  vm_name         = each.value.vm_name
  target_node     = var.target_node
  clone_template  = var.clone_template
  cores           = each.value.cores
  sockets         = each.value.sockets
  memory          = each.value.memory
  disk_size       = each.value.disk_size
  storage_name    = module.storage.storage_name
  bridge          = module.network.bridge
  vlan_tag        = module.network.vlan_tag
  ipconfig0       = try(each.value.ipconfig0, var.ipconfig0_default)
  ci_user         = var.ci_user
  ssh_public_key  = var.ssh_public_key
}

output "vm_ids" {
  description = "IDs das VMs criadas no cluster02"
  value       = { for k, m in module.vm : k => m.vm_id }
}
