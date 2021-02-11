#!/bin/bash

if [[ "x${ENV}" != "x" ]]; then
source ./env-${ENV}.sh
else
source ./env-default.sh
fi

kubectl apply -f operator/1.6.14/operator.yaml
CLUSTER_DNS_DOMAIN=${CLUSTER_DNS_DOMAIN} envsubst < operator/1.6.14/crd.yaml | kubectl apply -f -
kubectl wait -n istio-operator deployment --all --for=condition=available --timeout=180s
sleep 60
# wait
sleep 30
kubectl wait -n istio-system deployment --all --for=condition=available --timeout=180s
kubectl rollout restart -n istio-demo deployment
kubectl wait -n istio-demo deployment --all --for=condition=available --timeout=180s
# wait
istioctl proxy-status
