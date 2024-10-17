deploy:
  cd ./opentofu && \
    tofu apply -var-file=./variable.tfvars -auto-approve && \
    ./generate_inventory.sh

destroy:
  cd ./opentofu && \
    tofu apply -var-file=./variable.tfvars -auto-approve -destroy

configure:
  cd ./ansible && \
    ansible-playbook -i k3s.ini playbook.yaml

doit:
  just deploy configure
