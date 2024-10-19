deploy:
  cd ./opentofu && \
    tofu apply -auto-approve

destroy:
  cd ./opentofu && \
    tofu apply -auto-approve -destroy

configure:
  cd ./ansible && \
    ansible-playbook -i inventory/proxmox.yaml playbook.yaml

doit:
  just deploy configure
