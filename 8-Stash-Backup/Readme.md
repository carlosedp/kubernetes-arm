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
