#!/bin/bash
if [[ $# -eq 0 ]] ; then
    echo "Run the script with the required auth user: ${0} [user]"
    exit 0
fi
printf "${1}:`openssl passwd -apr1`\n" >> auth
kubectl delete secret -n kube-system dashboard-auth
kubectl create secret generic dashboard-auth --from-file=auth -n kube-system
rm auth
