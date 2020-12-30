#!/bin/bash

git submodule update --init

istioctl operator init

# Create control plane 
kubectl create ns istio-system
kubectl ns istio-system
kubectl apply -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: example-istiocontrolplane
spec:
  profile: demo
  values:
    pilot:
      env:
        PILOT_ENABLE_STATUS: true 
    global:
      istiod:
        enableAnalysis: true
EOF

kubectl wait -n istio-system deployment --all --for=condition=available --timeout=180s
sleep 15
kubectl wait -n istio-system deployment --all --for=condition=available --timeout=180s

#  Demo App

kubectl create ns istio-demo
kubectl label namespace istio-demo istio-injection=enabled
kubectl ns istio-demo
kubectl apply -f istio/samples/bookinfo/platform/kube/bookinfo.yaml
kubectl wait -n istio-demo deployment --all --for=condition=available --timeout=180s

kubectl apply -f istio/samples/bookinfo/networking/bookinfo-gateway.yaml



# Observability Stack

kubectl apply -f istio/samples/addons 
sleep 2
kubectl apply -f istio/samples/addons 
kubectl rollout status deployment/kiali -n istio-system

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
