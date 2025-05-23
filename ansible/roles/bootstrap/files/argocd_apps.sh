#!/usr/bin/env bash
set -ex

ADMIN_PASSWORD=${ADMIN_PASSWORD:?undefined}

# Set up port forwarding to the argo app.
# When used with the `--core` option flag
# argo doesn't allow changing the initial
# admin password
FORWARD_CMD=(
  kubectl
  port-forward
  svc/argocd-server
  -n argocd
  '8080:443'
)

"${FORWARD_CMD[@]}" >/dev/null 2>&1 &
FORWARD_PID=$!
sleep 5

LOGIN_CMD=(
  argocd
  login
  'localhost:8080'
  --username admin
  --insecure
  --skip-test-tls
  --grpc-web
  --password
  ${ADMIN_PASSWORD}
)

"${LOGIN_CMD[@]}"

# Creating the app is tempermental due
# to issues with argo -> github access
# - One error was related to SSH connection
# - Another was rate limiting
# So try 5 times to create it otherwise
# bail out
sleep_for=200
for i in {1..5}; do
	argocd app create apps \
	  --dest-namespace argocd \
	  --dest-server https://kubernetes.default.svc \
	  --repo gitea@gitea.home:ian/argocd.git \
    --path argocd-apps >/dev/null 2>&1 \
	&& _create_rc=$? \
	|| _create_rc=$?

	[[ $_create_rc -eq 0 ]] && {
    echo "Created apps"
    break
  }
  [[ $i -eq 5 ]] && exit $_create_rc || {
    _sleep_ms="$(( $i * $i * $sleep_for ))"
    sleep "${_sleep_ms:0:-3}.${_sleep_ms: -3}"
  }
done

sleep 20
# ArgoCDs logging is obnoxious so send
# it to oblivion
argocd app sync apps >/dev/null 2>&1
sleep 20
echo "Apps synced"

# array of apps in the order they should be started
APPS=(
	'metallb' # Creates an IP Pool that metallb is allowed to allocate
	'nginx-ingress' # Nginx ingress controller
	'cert-manager' # Creates the cert issuer, points at local network ACME server
	'argocd' # Creates argo related resources not in the helm chart, Ingress etc.
	#'vault'
)
argocd app get apps --hard-refresh >/dev/null 2>&1
argocd app sync apps >/dev/null 2>&1

echo "Apps synced again"

for app in "${APPS[@]}"; do
  echo "Syncing ${app}"
	argocd app get "${app}" --hard-refresh > /dev/null 2>&1
	argocd app sync "${app}" --async
	sleep 30
done
