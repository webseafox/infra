variable "bridge" {
  description = "Bridge de rede no Proxmox (ex: vmbr0)"
  type        = string
}

variable "vlan_tag" {
  description = "Tag VLAN opcional"
  type        = number
  default     = 0
}
