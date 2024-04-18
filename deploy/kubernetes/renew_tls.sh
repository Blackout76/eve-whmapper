
echo "#####> Renew tls certs on: __DOMAIN__ "

kubectl delete -f deploys/certs.yaml

kubectl apply -f deploys/certs.yaml

kubectl describe -n __NAMESPACE__ Certificate tls-__NAMESPACE__