terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = ">= 0.66.0"
    }
    sops = {
      source = "carlpett/sops"
      version = "1.1.1"
    }
  }
}

data "sops_file" "secrets" {
  source_file = "/home/ian/dev/secrets/sops/k3s.secrets.yaml"
}

provider "proxmox" {
  # Configuration options
  endpoint = "https://pve.home:8006/"
  api_token = "root@pam!terraform=${data.sops_file.secrets.data["pve_token"]}"

  ssh {
    username = "root"
    private_key = file("~/.ssh/id_ed25519")
  }
}
