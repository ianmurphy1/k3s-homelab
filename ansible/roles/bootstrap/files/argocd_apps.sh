#!/usr/bin/env bash
set -ex

NEW_PASS=${ADMIN_PASSWORD:-undefined}
[[ $NEW_PASS == undefined ]] && exit 1

# Set up port forwarding to the argo app.
# When used with the `--core` option flag
# argo doesn't allow changing the initial
# admin password
kubectl port-forward svc/argocd-server -n argocd 8080:443 >/dev/null 2>&1 &

# This should die once the script exits
# but to be sure grab the PID and kill it
# once the script is finished
FORWARD_PID=$!

CURRENT_PASS="$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"
CHANGE_PASS=true

LOGIN_CMD=(
  argocd
  login
  'localhost:8080'
  --username admin
  --insecure
  --skip-test-tls
  --grpc-web
  --password
)

"${LOGIN_CMD[@]}" "${CURRENT_PASS}" && _login_rc=$? || _login_rc=$?

if [[ $_login_rc -ne 0 ]]; then
	CHANGE_PASS=false
	"${LOGIN_CMD[@]}" "${ADMIN_PASSWORD}"
fi

# Creating the app is tempermental due
# to issues with argo -> github access
# - One error was related to SSH connection
# - Another was rate limiting
# So try 5 times to create it otherwise
# bail out
for i in {1..5}; do
	argocd app create apps \
	  --dest-namespace argocd \
	  --dest-server https://kubernetes.default.svc \
	  --repo git@github.com:ianmurphy1/argocd.git \
      --path argocd-apps >/dev/null 2>&1 \
	&& _create_rc=$? \
	|| _create_rc=$?

	[[ $_create_rc -eq 0 ]] && break
	[[ $i -eq 5 ]] && exit $_create_rc || sleep 2
done

sleep 10
# ArgoCDs logging is obnoxious so send
# it to oblivion
argocd app sync apps >/dev/null 2>&1
sleep 10

# array of apps in the order they should be started
APPS=(
	'metallb' # Creates an IP Pool that metallb is allowed to allocate
	'nginx-ingress' # Nginx ingress controller
	'cert-manager' # Creates the cert issuer, points at local network ACME server
	'argocd' # Creates argo related resources not in the helm chart, Ingress etc.
	'vault'
)
argocd app get apps --hard-refresh >/dev/null 2>&1
argocd app sync apps >/dev/null 2>&1

for app in "${APPS[@]}"; do
	argocd app get "${app}" --hard-refresh > /dev/null 2>&1
	argocd app sync "${app}" --async
	sleep 30
done

if [[ ${CHANGE_PASS} == true ]]; then
	argocd account update-password --current-password "${CURRENT_PASS}" --new-password "${NEW_PASS}"
fi

kill -9 ${FORWARD_PID}
