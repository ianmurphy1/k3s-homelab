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
    ca_certs:
      trusted:
        - |
          -----BEGIN CERTIFICATE-----
          MIIBizCCATKgAwIBAgIRAKk5OPRJ23w2j0GTbnjESPYwCgYIKoZIzj0EAwIwJDEM
          MAoGA1UEChMDSWFuMRQwEgYDVQQDEwtJYW4gUm9vdCBDQTAeFw0yNDEwMDIxNDAz
          MzZaFw0zNDA5MzAxNDAzMzZaMCQxDDAKBgNVBAoTA0lhbjEUMBIGA1UEAxMLSWFu
          IFJvb3QgQ0EwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAATJKuh4t5aL2h5J/+Du
          cXCE2oD6A9Vldnca6ULUepoI9ahGINtwv7fAPGfMMnvtuXjVQ3bMDBj50RHLJOM0
          zsqXo0UwQzAOBgNVHQ8BAf8EBAMCAQYwEgYDVR0TAQH/BAgwBgEB/wIBATAdBgNV
          HQ4EFgQU+3kOFZmQ2elFg7OvFlmUXJulyo0wCgYIKoZIzj0EAwIDRwAwRAIgK5/U
          /ecieFTnhkQw1XWzlINkmcozWboYyHDZTeKNdYECIAo7AzOpkQDA/PnP6wAYdNfr
          NjtqY45e3g98ykzfuRqd
          -----END CERTIFICATE-----
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
      - ssh-keygen gitea.home github.com > /etc/ssh/ssh_known_hosts
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
