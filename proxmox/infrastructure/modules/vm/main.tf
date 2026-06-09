resource "proxmox_vm_qemu" "this" {
  name        = var.vm_name
  target_node = var.target_node
  clone       = var.clone_template

  cores   = var.cores
  sockets = var.sockets
  memory  = var.memory

  disk {
    slot    = 0
    size    = var.disk_size
    type    = "scsi"
    storage = var.storage_name
  }

  network {
    id      = 0
    model   = "virtio"
    bridge  = var.bridge
    tag     = var.vlan_tag == 0 ? null : var.vlan_tag
    firewall = false
  }

  os_type = "cloud-init"
  ipconfig0 = var.ipconfig0
  ciuser    = var.ci_user
  sshkeys   = var.ssh_public_key
}
