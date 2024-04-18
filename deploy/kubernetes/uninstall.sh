echo "Uninstalling namepsace __NAMESPACE__ ..."

kubectl delete namespace __NAMESPACE__

kubectl delete pv __NAMESPACE__-pv

rm -R /volumes/__NAMESPACE__