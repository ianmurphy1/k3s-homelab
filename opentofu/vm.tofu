resource "proxmox_virtual_environment_vm" "k3s" {
  count = 3
  name      = "k3s-${count.index}"
  node_name = "pve"
  keyboard_layout = "en-gb"
  vm_id = 2000 + count.index
  tags = [
    "k3s",
    "k3s_${count.index == 0 ? "master" : "worker"}"
  ]

  initialization {
    user_data_file_id = proxmox_virtual_environment_file.cloud_config[count.index].id

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  network_device {
    enabled = true
    bridge = "vmbr0"
  }

  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_download_file.image.id
    interface    = "scsi0"
    size         = 20
    ssd = true
  }

  cpu {
    cores = 2
    type = "x86-64-v2-AES"
  }

  operating_system {
    type = "l26"
  }

  memory {
    dedicated = 1024 * 8
  }

  agent {
    enabled = true
  }

  serial_device {
  }
}


resource "proxmox_virtual_environment_download_file" "image" {
  content_type = "iso"
  datastore_id = "hdd"
  node_name    = "pve"
  #url = "https://cloud.debian.org/images/cloud/bookworm/20241004-1890/debian-12-genericcloud-amd64-20241004-1890.qcow2"
  url = "https://cloud.debian.org/images/cloud/bookworm/20250210-2019/debian-12-genericcloud-amd64-20250210-2019.qcow2"
  file_name = "debian-12-image.img"
  overwrite = true
  overwrite_unmanaged = true
}

output "ips" {
  value = proxmox_virtual_environment_vm.k3s[*].ipv4_addresses[1][0]
}
