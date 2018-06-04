#!/bin/bash

echo "Enter your Minio Key:";
read key;

echo "Enter your Minio Secret:";
read secret;

echo "Creating secret"
kubectl create secret generic minio-credentials -n backup --from-literal=key=${key} --from-literal=secret=${secret}

