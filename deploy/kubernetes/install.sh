#!/bin/bash

############### VAR SECTION ###############

__NAMESPACE__="eve-whmapper"
__DOMAIN__="map.blackout76.tech"
__MAIL__="olivier.leger.dev@gmail.com"                   # must be a valid email
__NODE_NAME__="aqua-master"   # must be same as current node where u install this
__DB_NAME__=whmapper
__DB_USER__=whmapper
__DB_PASSWORD__=whmapper

__PORT_APP__=30150
__PORT_DB__=$(( $__PORT_APP__ + 1 ))
__PORT_REDIS__=$(( $__PORT_APP__ + 2 ))
__EVE_KEY__="988508e4acfa43ab9529194ccfce8aac"
__EVE_SECRET__="cex9UTLlnVshbCpz0LQRvWALT0glXdlutuTlyhKy"

__CLUSTER_IP__="192.168.1.120"
__STORAGE_SPACE__=4
__APP_IMAGE__=ghcr.io/pfh59/eve-whmapper:latest

############### MISC ###############

file_contents=$(<uninstall.sh)
file_contents=${file_contents//__NAMESPACE__/$__NAMESPACE__}
echo "$file_contents" > uninstall.sh
chmod +x uninstall.sh

############### CLEAN OLD INSTALL ###############

./uninstall.sh

############### NAMESPACE ###############
echo "#####> Deploy namespace"
kubectl create namespace $__NAMESPACE__

############### STORAGES ###############
echo "#####> Deploy storage"

mkdir -p "/volumes/$__NAMESPACE__"
chmod -R 777 "/volumes/$__NAMESPACE__"

MANIFEST="deploys/storage-pv.yaml"
cat << EOF >> "$MANIFEST"
apiVersion: v1
kind: PersistentVolume
metadata:
  name: "${__NAMESPACE__}-pv"
spec:
  capacity:
    storage: "${__STORAGE_SPACE__}Gi"
  volumeMode: Filesystem
  accessModes:
    - ReadWriteMany
  hostPath:
    path: "/volumes/$__NAMESPACE__"
  persistentVolumeReclaimPolicy: Retain
EOF
kubectl apply -f deploys/storage-pv.yaml
rm deploys/storage-pv.yaml

MANIFEST="deploys/storage-pvc.yaml"
cat << EOF >> "$MANIFEST"
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: "${__NAMESPACE__}-pvc"
  namespace: $__NAMESPACE__
spec:
  storageClassName: ""
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: "${__STORAGE_SPACE__}Gi"
EOF
kubectl apply -f deploys/storage-pvc.yaml
rm deploys/storage-pvc.yaml

############### CORE ###############
echo "#####> Deploy core"

file_contents=$(<deploys/core.yaml)
file_contents=${file_contents//__NAMESPACE__/$__NAMESPACE__}
file_contents=${file_contents//__DOMAIN__/$__DOMAIN__}
file_contents=${file_contents//__CLUSTER_IP__/$__CLUSTER_IP__}
file_contents=${file_contents//__MAIL__/$__MAIL__}
file_contents=${file_contents//__NODE_NAME__/$__NODE_NAME__}
file_contents=${file_contents//__DB_NAME__/$__DB_NAME__}
file_contents=${file_contents//__DB_USER__/$__DB_USER__}
file_contents=${file_contents//__DB_PASSWORD__/$__DB_PASSWORD__}
file_contents=${file_contents//__PORT_DB__/$__PORT_DB__}
file_contents=${file_contents//__PORT_REDIS__/$__PORT_REDIS__}
file_contents=${file_contents//__EVE_KEY__/$__EVE_KEY__}
file_contents=${file_contents//__EVE_SECRET__/$__EVE_SECRET__}
file_contents=${file_contents//__PORT_APP__/$__PORT_APP__}
echo "$file_contents" > deploys/core.yaml
kubectl apply -f deploys/core.yaml

############### APP ###############
echo "#####> Deploy app"
file_contents=$(<deploys/app.yaml)
file_contents=${file_contents//__NAMESPACE__/$__NAMESPACE__}
file_contents=${file_contents//__DOMAIN__/$__DOMAIN__}
file_contents=${file_contents//__PORT_APP__/$__PORT_APP__}
file_contents=${file_contents//__APP_IMAGE__/$__APP_IMAGE__}
file_contents=${file_contents//__PORT_APP__/$__PORT_APP__}
echo "$file_contents" > deploys/app.yaml
kubectl apply -f deploys/app.yaml

############### TLS CERTS ###############
echo "#####> Deploy https tls"
file_contents=$(<deploys/certs.yaml)
file_contents=${file_contents//__NAMESPACE__/$__NAMESPACE__}
file_contents=${file_contents//__DOMAIN__/$__DOMAIN__}
file_contents=${file_contents//__MAIL__/$__MAIL__}
echo "$file_contents" > deploys/certs.yaml
chmod +x renew_tls.sh
kubectl apply -f deploys/certs.yaml

