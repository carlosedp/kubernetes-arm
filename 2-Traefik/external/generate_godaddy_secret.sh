#!/bin/bash

echo "Please enter your GoDaddy Key";
read key;

echo "Please enter your GoDaddy secret";
read -s secret;

echo "Creating secret"
kubectl create secret generic traefik-external-godaddy -n kube-system --from-literal=key=${key} --from-literal=secret=${secret}
