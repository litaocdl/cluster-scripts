#!/bin/bash
###
## 1. create a minio server
## 2. create a cluster and configure the backup to minio 
###
kubectl create ns minio
## create minio 
kubectl -n minio apply -f ./minio_deployment_full.yaml

## create a cluster with backup configured
#kubectl -n minio apply -f cluster-with-backup.yaml

## port forwarding


## Access from http://localhost:9000/minio/cluster-backups/<clusterName> minio/minio123


## create transaction
## k -n minio exec -it pg-with-backup-1 -- pgbench -i -s 10 app


