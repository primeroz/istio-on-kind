#!/bin/bash

if [[ "x${ENV}" != "x" ]]; then
source ./env-${ENV}.sh
else
source ./env-default.sh
fi

kubectl create ns istio-operator
kubectl apply -f operator/1.10.6/operator.yaml
sleep 10
kubectl wait -n istio-operator deployment --all --for=condition=available --timeout=180s

# Create control plane 
kubectl create ns istio-system
kubectl ns istio-system
CLUSTER_DNS_DOMAIN=${CLUSTER_DNS_DOMAIN} envsubst < operator/1.10.6/crd.yaml | kubectl apply -f -

sleep 30
kubectl wait -n istio-system deployment --all --for=condition=available --timeout=180s
sleep 5
kubectl wait -n istio-system deployment --all --for=condition=available --timeout=180s || exit 1

if [[ "x${EXIT_EARLY}" == "xtrue" ]]; then
exit 0
fi
exit 0

#  Demo App

kubectl create ns istio-demo
kubectl label namespace istio-demo istio-injection=enabled
kubectl ns istio-demo
kubectl apply -f bookinfo/bookinfo-kube/bookinfo.yaml
kubectl wait -n istio-demo deployment --all --for=condition=available --timeout=180s

kubectl apply -f bookinfo/bookinfo-networking/bookinfo-gateway.yaml

kubectl apply -f bookinfo/bookinfo-networking/destination-rule-all-mtls.yaml 
# j
# j
# j
# j# Observability Stack
# j
# jkubectl ns istio-system
# jkubectl apply -f istio-addons 
# jsleep 2
# jkubectl apply -f istio-addons 
# jkubectl rollout status deployment/kiali -n istio-system
# jkubectl apply -f istio-addons/extras/prometheus-configmap.yml

#kubectl apply -f istio/samples/addons/extras/zipkin.yaml
#kubectl rollout status deployment/zipkin -n istio-system

# Get and print the ingress info
INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
INGRESS_HOST=$(kubectl get node istio-control-plane -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')

GATEWAY_URL="$INGRESS_HOST:$INGRESS_PORT"
GATEWAY_SECURE_URL="$INGRESS_HOST:$SECURE_INGRESS_PORT"

echo "HTTP Gatway url: $GATEWAY_URL"
echo "HTTP Gatway secure url: $GATEWAY_SECURE_URL"
