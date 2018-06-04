#!/bin/bash
# Version 1.1.0 is needed because the consul manifest doesn't have the 1.0.0 image for ARM
helm install --name traefik stable/consul --set ImageTag=1.1.0

cat << EOF
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: consul-ui
  namespace: kube-system
spec:
  rules:
  - host: consul.internal.carlosedp.com
    http:
      paths:
      - path: /
        backend:
          serviceName: consul-traefik-consul-ui
          servicePort: http
EOF | kubectl create -f -
