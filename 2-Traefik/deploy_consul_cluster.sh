#!/bin/bash
# Version 1.1.0 is needed because the consul manifest doesn't have the 1.0.0 image for ARM
helm install --name traefik stable/consul --set ImageTag=1.1.0
