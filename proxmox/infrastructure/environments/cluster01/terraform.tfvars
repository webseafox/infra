pm_api_url          = "https://proxmox.example.com:8006/api2/json"
pm_api_token_id     = "root@pam!terraform"
pm_api_token_secret = "REPLACE_ME"
pm_tls_insecure     = true

target_node    = "pve01"
clone_template = "ubuntu-24-04-cloudinit"
storage_name = "local-lvm"

bridge   = "vmbr0"
vlan_tag = 0

ipconfig0_default = "ip=dhcp"
ci_user        = "ubuntu"
ssh_public_key = "ssh-rsa AAAA... sua-chave-publica"

vms = {
	vm01 = {
		vm_name   = "cluster01-vm-01"
		cores     = 2
		sockets   = 1
		memory    = 4096
		disk_size = "30G"
	}

	vm02 = {
		vm_name   = "cluster01-vm-02"
		cores     = 2
		sockets   = 1
		memory    = 4096
		disk_size = "30G"
	}

	vm03 = {
		vm_name   = "cluster01-vm-03"
		cores     = 4
		sockets   = 1
		memory    = 8192
		disk_size = "40G"
		ipconfig0 = "ip=192.168.10.53/24,gw=192.168.10.1"
	}
}
