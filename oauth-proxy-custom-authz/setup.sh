#!/bin/bash

source /opt/asdf-vm/asdf.sh
source ./common

ISTIOVERSION=${1:-"1.9"}
ISTIOASDF=""
MANIFESTSVERSIONEDDIR=""
MANIFESTSCOMMONDIR="./manifests-common"

# Check we are in the right CONTEXT
if [[ "x$(kubectl config current-context)" != "xkind-oauth" ]]; then
  e_error "Wrong context , you need to be in kind-oauth"
  exit 1
fi

if [[ "${ISTIOVERSION}" == "1.9" ]]; then
  ISTIOASDF="1.9.8"
  MANIFESTSVERSIONEDDIR="./manifests-19"
  e_arrow "Using Istio ${ISTIOASDF}"
elif [[ "${ISTIOVERSION}" == "1.10" ]]; then
  ISTIOASDF="1.10.4"
  MANIFESTSVERSIONEDDIR="./manifests-110"
  e_arrow "Using Istio ${ISTIOASDF}"
elif [[ "${ISTIOVERSION}" == "1.8" ]]; then
  ISTIOASDF="1.8.6"
  MANIFESTSVERSIONEDDIR="./manifests-18"
  e_arrow "Using Istio ${ISTIOASDF}"
else
  die "Wrong version of istio selected, only 1.8, 1.9 and 1.10 supported"
fi
sleep 10

e_header "Setting UP Cert-Manager"
kubectl apply -f "${MANIFESTSCOMMONDIR}/cert-manager.yaml"
sleep 10
kubectl wait -n cert-manager deployment --all --for=condition=available --timeout=180s

e_header "Setting UP Istio version ${ISTIOASDF}"
kubectl create ns istio-operator
set -e
asdf shell istioctl ${ISTIOASDF}
istioctl operator dump | kubectl apply -f -
sleep 10
kubectl wait -n istio-operator deployment --all --for=condition=available --timeout=180s || die "something went wrong"
e_success "Completed"
set +e


e_header "Creating Istio Control Plane"
kubectl create ns istio-system
kubectl config set-context --current --namespace=istio-system
cat "${MANIFESTSVERSIONEDDIR}/mesh.yaml"| kubectl apply -f -

sleep 30
kubectl wait -n istio-system deployment --all --for=condition=available --timeout=180s
sleep 5
kubectl wait -n istio-system deployment --all --for=condition=available --timeout=180s || die "something went wrong"
e_success "Completed"

e_header "Creating Test setup"
kubectl apply -f "${MANIFESTSCOMMONDIR}/testcerts.yaml"
kubectl apply -f "${MANIFESTSCOMMONDIR}/common.yaml"
kubectl apply -f "${MANIFESTSVERSIONEDDIR}/dex.yaml"
kubectl apply -f "${MANIFESTSCOMMONDIR}/dex-ui.yaml"
kubectl apply -f "${MANIFESTSVERSIONEDDIR}/oauth2proxy.yaml"
kubectl wait -n dex deployment --all --for=condition=available --timeout=180s || die "something went wrong"
[[ "x${ISTIOVERSION}" != "x1.8" ]] && kubectl apply -f "${MANIFESTSCOMMONDIR}/podinfo1.yaml"
[[ "x${ISTIOVERSION}" != "x1.8" ]] && kubectl apply -f "${MANIFESTSCOMMONDIR}/podinfo2.yaml"
kubectl apply -f "${MANIFESTSCOMMONDIR}/podinfo3.yaml"
kubectl wait -n dev deployment --all --for=condition=available --timeout=180s || die "something went wrong"

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
