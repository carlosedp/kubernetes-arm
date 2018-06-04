#!/bin/bash

echo "Enter namespace where pod to be backup is:";
read ns;

echo "Enter your AWS/Minio Key:";
read key;

echo "Enter your AWS/Minio Secret:";
read secret;

echo "Enter your Restic password:";
read pwd;

echo "Creating secret"
kubectl create secret generic minio-restic-secret -n ${ns} --from-literal=RESTIC_PASSWORD=${RESTIC_PASSWORD} --from-literal=AWS_ACCESS_KEY_ID=${key} --from-literal=AWS_SECRET_ACCESS_KEY=${secret}
