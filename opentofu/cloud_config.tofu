data "local_file" "ssh_public_key" {
  filename = "/home/ian/.ssh/id_ed25519.pub"
}

resource "proxmox_virtual_environment_file" "cloud_config" {
  content_type = "snippets"
  datastore_id = "hdd"
  node_name    = "pve"
  count = 3

  source_raw {
    data = <<-EOF
    #cloud-config
    disable_root: false
    timezone: Europe/Dublin
    hostname: k3s-${count.index}
    ssh_authorized_keys:
      - ${trimspace(data.local_file.ssh_public_key.content)}
    users:
      - default
      - name: debian
        groups:
          - sudo
        shell: /bin/bash
        ssh_authorized_keys:
          - ${trimspace(data.local_file.ssh_public_key.content)}
        sudo: ALL=(ALL) NOPASSWD:ALL
    runcmd:
      - systemctl enable qemu-guest-agent
      - systemctl start qemu-guest-agent
      - ln -sf /usr/bin/python3.11 /usr/bin/python
      - echo "done" > /tmp/cloud-config.done
    #package_upgrade: true
    package_update: true
    packages:
      - qemu-guest-agent
      - net-tools
      - curl
      - git
      - vim
    EOF

    file_name = "cloud-config-${count.index}.yaml"
  }
}
