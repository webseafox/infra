pm_api_url          = "https://proxmox.example.com:8006/api2/json"
pm_api_token_id     = "terraform@pve!terraform"
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
  bootstrap = {
    vm_name   = "cluster02-ocp-bootstrap"
    cores     = 4
    sockets   = 1
    memory    = 16384
    disk_size = "100G"
    ipconfig0 = "ip=192.168.10.210/24,gw=192.168.10.1"
  }

  master01 = {
    vm_name   = "cluster02-ocp-master-01"
    cores     = 4
    sockets   = 1
    memory    = 16384
    disk_size = "120G"
    ipconfig0 = "ip=192.168.10.211/24,gw=192.168.10.1"
  }

  master02 = {
    vm_name   = "cluster02-ocp-master-02"
    cores     = 4
    sockets   = 1
    memory    = 16384
    disk_size = "120G"
    ipconfig0 = "ip=192.168.10.212/24,gw=192.168.10.1"
  }

  master03 = {
    vm_name   = "cluster02-ocp-master-03"
    cores     = 4
    sockets   = 1
    memory    = 16384
    disk_size = "120G"
    ipconfig0 = "ip=192.168.10.213/24,gw=192.168.10.1"
  }

  worker01 = {
    vm_name   = "cluster02-ocp-worker-01"
    cores     = 8
    sockets   = 1
    memory    = 32768
    disk_size = "150G"
    ipconfig0 = "ip=192.168.10.221/24,gw=192.168.10.1"
  }

  worker02 = {
    vm_name   = "cluster02-ocp-worker-02"
    cores     = 8
    sockets   = 1
    memory    = 32768
    disk_size = "150G"
    ipconfig0 = "ip=192.168.10.222/24,gw=192.168.10.1"
  }
}
