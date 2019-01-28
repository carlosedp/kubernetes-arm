#!/bin/bash
kubectl create -f rbac-config.yaml
helm init --service-account tiller --tiller-image jessestuart/tiller
# Patch Helm to land on an ARM node because of the used image
kubectl patch deployment tiller-deploy -n kube-system --patch '{"spec": {"template": {"spec": {"nodeSelector": {"beta.kubernetes.io/arch": "arm64"}}}}}'
