#!/usr/bin/env bash

ARGOCD_VERSION=$(curl --silent "https://api.github.com/repos/argoproj/argo-cd/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')

curl -sSL -o "/tmp/argocd-${ARGOCD_VERSION}" "https://github.com/argoproj/argo-cd/releases/download/${ARGOCD_VERSION}/argocd-linux-amd64"

chmod +x "/tmp/argocd-${ARGOCD_VERSION}"

mv "/tmp/argocd-${ARGOCD_VERSION}" "/usr/local/bin/argocd"
