#!/bin/bash

###
## 1. create a minio server
## 2. create a cluster and configure the backup to minio 
###

createMinio() {
    echo "create ns"
    kubectl create ns $minio_ns
    echo "create minio"
    kubectl -n $minio_ns apply -f $ROOT_DIR/common/minio_deployment_full.yaml

    echo "create minio client"
    kubectl -n $minio_ns apply -f $ROOT_DIR/common/minio_client.yml

    if [[ -z $api ]] ; then
    echo "done"
    exit 0
    fi
}

mc() {
    kubectl -n $minio_ns exec -it mc -- mc ls -r minio
}

expose() {
    echo " Access from http://localhost:9000/minio/cluster-backups/<clusterName> minio/minio123 "
    kubectl -n $minio_ns port-forward svc/minio-service 9000:9000
}

createCluster() {
    kubectl create ns $cluster_ns

    if [[ $cluster_ns != $minio_ns ]]; then
        kubectl -n $cluster_ns apply -f $ROOT_DIR/common/minio_secrets.yml
    fi

    api=$1
    echo "create a cluster with backup configured"
    kubectl -n $cluster_ns apply -f $ROOT_DIR/$api/cluster-init-with-backup.yaml

    ## wait for the third pod is ready
    kubectl wait --for=condition=Ready=true --timeout=2m -n minio-cluster po pg-with-backup1-3

    echo "create a backup object"
    kubectl -n $cluster_ns apply -f $ROOT_DIR/$api/backup.yaml

    if [[ $2 == recovery ]]; then
         echo "create a cluster recovery from minio backup object"
         kubectl -n $cluster_ns apply -f $ROOT_DIR/$api/cluster-recovery-from-backup.yaml
    fi
}

minio_ns=minio
cluster_ns=minio-cluster

ROOT_DIR=$(realpath "$(dirname "$0")/")
api=$1
if [[ -z $api ]]; then
    echo "path is: $ROOT_DIR" 
    echo "usage"
    echo "createMinio.sh minio|cnp [recovery]|cnpg [recovery]|mc|expose"  
    exit 0
fi

if [[ $api == minio ]]; then
   echo "Going to create minio server under namespace minio"
   createMinio 
elif [[ $api == cnpg || $api == cnp ]]; then
   echo "Going to create minio server under namespace minio with $api cluster"
   createCluster $api $2
elif [[ $api == mc ]]; then
   echo "use mc client to list backup"
   mc
elif [[ $api == expose ]]; then
   echo "portforwarding minio"
   expose  
else
   $0
fi