variable "vm_name" {
  description = "Nome da VM"
  type        = string
}

variable "target_node" {
  description = "Node Proxmox onde a VM sera criada"
  type        = string
}

variable "clone_template" {
  description = "Template cloud-init para clone"
  type        = string
}

variable "cores" {
  description = "Quantidade de vCPUs"
  type        = number
}

variable "sockets" {
  description = "Quantidade de sockets"
  type        = number
  default     = 1
}

variable "memory" {
  description = "Memoria em MB"
  type        = number
}

variable "disk_size" {
  description = "Tamanho do disco (ex: 30G)"
  type        = string
}

variable "storage_name" {
  description = "Storage do Proxmox"
  type        = string
}

variable "bridge" {
  description = "Bridge de rede (ex: vmbr0)"
  type        = string
}

variable "vlan_tag" {
  description = "Tag VLAN opcional"
  type        = number
  default     = 0
}

variable "ipconfig0" {
  description = "Configuracao de IP cloud-init (ex: ip=dhcp)"
  type        = string
  default     = "ip=dhcp"
}

variable "ci_user" {
  description = "Usuario cloud-init"
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key" {
  description = "Chave publica SSH"
  type        = string
}
