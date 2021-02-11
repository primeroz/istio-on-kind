```
ENV=customdns ./kind.sh create

kubectl get cm -n kube-system kubeadm-config -o json | jq '.data."ClusterConfiguration"' -r | yq '.networking.dnsDomain'

# Start istio 1.8.3
ENV=customdns ./setup-simple.sh
kubectl apply -f podinfo/podinfo.yaml

# WAIT
istioctl analyze -A 

# Apply broken VS
kubectl apply -f test-vs-IST0101/VS.yaml
istioctl analyze -A 

# Apply the Supposed to work but still broken VS
source env-customdns.sh
CLUSTER_DNS_DOMAIN="$CLUSTER_DNS_DOMAIN" envsubst < test-vs-IST0101/VS-fqdn.yaml | kubectl apply -f -
istioctl analyze -A

# Apply the complex VS to make sure the config is actually propagated to envoy
source env-customdns.sh
CLUSTER_DNS_DOMAIN="$CLUSTER_DNS_DOMAIN" envsubst < test-vs-IST0101/VS-fqdn-split.yaml | kubectl apply -f -

POD=$(istioctl proxy-status | grep productpage | awk '{print $1}')
istioctl proxy-config route $POD --name 9898 -o json
```

