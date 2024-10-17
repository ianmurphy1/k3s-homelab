#!/usr/bin/env bash
#set -x

HOSTS_FILE="../ansible/k3s.ini"
OUTPUTS=($(tofu output -json | jq -r '.ips.value[]' | shuf))

echo '[all]' > ${HOSTS_FILE}
for n in "${OUTPUTS[@]}"; do
	echo "${n}"	>> ${HOSTS_FILE}
done

echo >> ${HOSTS_FILE}
echo "[master]" >> ${HOSTS_FILE}
echo "${OUTPUTS[0]}" >> ${HOSTS_FILE}
echo "" >> ${HOSTS_FILE}
echo "[workers]" >> ${HOSTS_FILE}

LENGTH=$(( ${#OUTPUTS[@]} - 1 ))

for w in "${OUTPUTS[@]:1:$LENGTH}"; do 
	echo "${w}" >> ${HOSTS_FILE}
done

echo '
[all:vars]
ansible_python_interpreter=/usr/bin/python3
' >> ${HOSTS_FILE} 
