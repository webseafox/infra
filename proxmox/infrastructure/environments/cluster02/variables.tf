variable "pm_api_url" {
  type = string
}

variable "pm_api_token_id" {
  type = string
}

variable "pm_api_token_secret" {
  type      = string
  sensitive = true
}

variable "pm_tls_insecure" {
  type    = bool
  default = true
}

variable "target_node" {
  type = string
}

variable "clone_template" {
  type = string
}

variable "vms" {
  type = map(object({
    vm_name  = string
    cores    = number
    sockets  = number
    memory   = number
    disk_size = string
    ipconfig0 = optional(string)
  }))
}

variable "storage_name" {
  type    = string
  default = "local-lvm"
}

variable "bridge" {
  type    = string
  default = "vmbr0"
}

variable "vlan_tag" {
  type    = number
  default = 0
}

variable "ipconfig0_default" {
  type    = string
  default = "ip=dhcp"
}

variable "ci_user" {
  type    = string
  default = "ubuntu"
}

variable "ssh_public_key" {
  type = string
}
