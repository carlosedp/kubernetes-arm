# Installing

## Minio

Generate Minio secrets and deploy the application in the `backup` namespace. Adjust the path where Minio will store it's data on the `minio-deployment.yaml` manifest in `volumes` section. In this case I'm storing the data on a NFS server.

    kubectl create ns backup
    ./generate_secrets.sh
    kubectl apply -f minio-deployment.yaml

## Stash

Deploy Stash operator into the cluster. The standard way is using the script hosted on Stash server but it currently doesn't fetch the ARM images. I've submited a PR for the original project.

From internet (for AMD/Intel):

    curl -fsSL https://raw.githubusercontent.com/appscode/stash/0.7.0/hack/deploy/stash.sh | bash -s -- --namespace=backup --docker-registry=carlosedp --pushgateway_registry=carlosedp --run-on-master --enable-analytics=false --enable-mutating-webhook

From local script (temporary solution, use this for ARM):

    ./stash.sh --namespace=backup --docker-registry=carlosedp --pushgateway-registry=carlosedp --run-on-master --enable-analytics=false --enable-mutating-webhook

In case there is a Prometheus operator deployed, create it's serviceMonitor:

    # For monitoring with Prometheus Operator:
    kubectl apply -f stash-servicemonitor.yaml

Uninstalling:

    ./stash.sh --uninstall --purge --namespace=backup


# Create Backup/Restore jobs

## Backup

Use the script on `kubernetes-arm/8-Stash-Backup/example/create_secret.sh` to generate the secrets so the backup job can store it's data in Minio. Use the same secret/key used on Minio deployment.

Deploy a demo application on `default` namespace. It's data will be backed-up on Minio.

    kubectl apply -f example/busybox.yaml

Create secret and key so the backup job will be able to access S3/Minio storage. After it deploy the backup job:

    ./create_secret.sh
    kubectl apply -f example/minio-backup.yaml

To get the status of the backups check:

    kubectl get repository deployment.stash-demo
    kubectl get snapshots -l repository=deployment.stash-demo

## Restore

First delete the backup job:

    kubectl delete restic minio-restic

Then run the restore job:

    kubectl apply -f example/minio-recovery.yaml

To check status:

    kubectl get recovery minio-recovery -o yaml

For more information and details, check Stash documentation on https://appscode.com/products/stash/0.7.0/guides/

# Building the image

Dependencies:

* Build Stash operator (go get, go build)
* Download Restic (https://github.com/restic/restic/releases/download/v0.8.3/restic_0.8.3_linux_arm64.bz2)
* Build Docker image
* Adjust script to download Onessl for ARM64 (https://github.com/kubepack/onessl/releases/download/0.3.0/onessl-linux-arm64) - Use `uname -m`
* Use pushgateway build for ARM64 (carlosedp/pushgateway)
* Change script do get pushgateway from alternative repository

```bash
#!/bin/bash

RESTIC_VERSION=0.8.3
STASH_VERSION=0.7.0
ARCH=arm64
REPOSITORY=carlosedp

GOPATH=$(go env GOPATH)
REPO_ROOT=$GOPATH/src/github.com/appscode/stash

# Build stash
go get github.com/appscode/stash
pushd ${REPO_ROOT}
git checkout ${STASH_VERSION}
export GOARCH=arm64
go build ./...
popd

mkdir -p /build_dir
cd /build_dir
cp $REPO_ROOT/dist/stash/stash-alpine-amd64 ./stash
chmod 755 ./stash

# Download restic
wget https://github.com/restic/restic/releases/download/v${RESTIC_VERSION}/restic_${RESTIC_VERSION}_linux_${ARCH}.bz2
bzip2 -d restic_${RESTIC_VERSION}_linux_${ARCH}.bz2
mv restic_${RESTIC_VERSION}_linux_${ARCH}.bz2 restic

# Build Docker container (done on ARM64 machine)
cat >> Dockerfile <<EOF
FROM alpine

RUN set -x \
  && apk add --update --no-cache ca-certificates

COPY restic /bin/restic
COPY stash /bin/stash

ENTRYPOINT ["/bin/stash"]
EXPOSE 56789 56790
EOF

# Build and push image
docker build -t ${REPOSITORY}/stash:${STASH_VERSION}-${ARCH} .
docker push ${REPOSITORY}/stash:${STASH_VERSION}-${ARCH}

# Create manifest (adjust on platform being used)
#wget https://github.com/estesp/manifest-tool/releases/download/v0.7.0/manifest-tool-linux-amd64
#mv manifest-tool-linux-amd64 manifest-tool
#chmod +x manifest-tool

# Generates the version manifest pointing to the arch images
#manifest-tool push from-args --platforms linux/amd64,linux/arm64 --template "${REPOSITORY}/stash:${STASH_VERSION}-ARCH" --target "${REPOSITORY}/stash:${STASH_VERSION}"

# Generates the :latest manifest pointing to the built arch images
#manifest-tool push from-args --platforms linux/amd64,linux/arm64 --template "${REPOSITORY}/stash:${STASH_VERSION}-ARCH" --target "${REPOSITORY}/stash:latest"
```
