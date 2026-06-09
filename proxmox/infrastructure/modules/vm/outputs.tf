output "vm_id" {
  description = "ID da VM criada no Proxmox"
  value       = proxmox_vm_qemu.this.vmid
}

output "vm_name" {
  description = "Nome da VM"
  value       = proxmox_vm_qemu.this.name
}
