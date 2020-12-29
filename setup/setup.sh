#!/usr/bin/env bash

source $(dirname "$0")/environment.sh

need kubectl
need flux

if [ -z "$GITHUB_TOKEN" ]; then
  echo "GITHUB_TOKEN is not set! Check setup/.env"
  exit 1
fi

message "checking fluxv2 prerequisites"
flux check --pre
[[ $? -ne 0 ]] && echo "Prerequisites were not satisfied" && exit 1

# Adding the CRDs is necessary because these custom resources live in the github repo
message "adding CRDs"
kubectl apply -f "${REPO_ROOT}"/crds

# Adding the system-upgrade controller because the crd doesn't work without it
message "adding system-upgrade controller"
kubectl apply -f deployment/system-upgrade/system-upgrade-controller.yml
kubectl wait --for=condition=ready pod -n system-upgrade -l upgrade.cattle.io/controller=system-upgrade-controller

message "adding personal sealed-secrets key"
kubectl apply -f .secrets/sealed-secrets/my-sealed-secrets-key.yml

message "installing flux components"
flux bootstrap github \
  --owner=RickCoxDev \
  --repository=k3s-gitops \
  --branch=master \
  --path=cluster \
  --personal \
  --arch=arm
