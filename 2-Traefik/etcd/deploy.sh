#!/usr/bin/env bash

if [ -z "${KUBECONFIG}" ]; then
    export KUBECONFIG=~/.kube/config
fi

# CAUTION - setting NAMESPACE will deploy most components to the given namespace
# however some are hardcoded to 'monitoring'. Only use if you have reviewed all manifests.

if [ -z "${NAMESPACE}" ]; then
    NAMESPACE=logging
fi

kubectl create namespace "$NAMESPACE"

kctl() {
    kubectl --namespace "$NAMESPACE" "$@"
}

# Deploy etcd operator
kctl apply -f etcd-operator-rbac.yaml
kctl apply -f etcd-operator-deployment.yaml

sleep 20
# Deploy etcd cluster for Traefik
kctl apply -f etcd-traefik-cluster.yaml
sleep 10
kctl apply -f etcd-traefik-svc.yaml



