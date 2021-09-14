#!/bin/bash


kubectl apply -f cert-manager.yaml
sleep 10
kubectl wait -n cert-manager deployment --all --for=condition=available --timeout=180s

kubectl create ns istio-operator
kubectl apply -f ../operator/1.9.8/operator.yaml
sleep 10
kubectl wait -n istio-operator deployment --all --for=condition=available --timeout=180s

# Create control plane 
kubectl create ns istio-system
kubectl config set-context --current --namespace=istio-system
cat mesh.yaml| kubectl apply -f -

sleep 30
kubectl wait -n istio-system deployment --all --for=condition=available --timeout=180s
sleep 5
kubectl wait -n istio-system deployment --all --for=condition=available --timeout=180s || exit 1

kubectl apply -f testcerts.yaml
kubectl apply -f common.yaml
kubectl apply -f dex.yaml
kubectl apply -f oauth2proxy.yaml
kubectl wait -n dex deployment --all --for=condition=available --timeout=180s || exit 1
kubectl apply -f deployment.yaml
kubectl wait -n dev deployment --all --for=condition=available --timeout=180s || exit 1

# Test
echo "Testing DEX"
curl http://dex.127.0.0.1.nip.io/healthz -s -o /dev/null -w "%{http_code}\n"
curl http://dex.127.0.0.1.nip.io/healthz -s -o /dev/null -w "%{http_code}\n"
curl http://dex.127.0.0.1.nip.io/healthz -s -o /dev/null -w "%{http_code}\n"
echo "Testing OAUTH2 PROXY"
curl http://oauth2-proxy.127.0.0.1.nip.io/ping  -s -o /dev/null -w "%{http_code}\n"
curl http://oauth2-proxy.127.0.0.1.nip.io/ping  -s -o /dev/null -w "%{http_code}\n"
curl http://oauth2-proxy.127.0.0.1.nip.io/ping  -s -o /dev/null -w "%{http_code}\n"


#
## Observability Stack
#
#kubectl ns istio-system
#kubectl apply -f istio-addons 
#sleep 2
#kubectl apply -f istio-addons 
#kubectl rollout status deployment/kiali -n istio-system
#kubectl apply -f istio-addons/extras/prometheus-configmap.yml
#
##kubectl apply -f istio/samples/addons/extras/zipkin.yaml
##kubectl rollout status deployment/zipkin -n istio-system
#
## Get and print the ingress info
#INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
#SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
#INGRESS_HOST=$(kubectl get node istio-control-plane -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')
#
#GATEWAY_URL="$INGRESS_HOST:$INGRESS_PORT"
#GATEWAY_SECURE_URL="$INGRESS_HOST:$SECURE_INGRESS_PORT"
#
#echo "HTTP Gatway url: $GATEWAY_URL"
#echo "HTTP Gatway secure url: $GATEWAY_SECURE_URL"
