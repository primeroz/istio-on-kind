```
ENV=customdns ./kind.sh create

kubectl get cm -n kube-system kubeadm-config -o json | jq '.data."ClusterConfiguration"' -r | yq '.networking.dnsDomain'

# Start istio 1.8.3
ENV=customdns setup-simple.sh
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

# Apply the complex VS to make sure the config is acutlayy propagated
source env-customdns.sh
CLUSTER_DNS_DOMAIN="$CLUSTER_DNS_DOMAIN" envsubst < test-vs-IST0101/VS-fqdn-split.yaml | kubectl apply -f -
```

`istioctl proxy-config route productpage-v1-7db75f7744-j4fps.istio-demo --name 9898 -o json`

## Logs

### Istiod
when i applied the VS.yaml

```
istiod-85d586896f-dgmzs discovery 2021-02-11T10:53:28.670345Z   info    ads     Push Status: {
istiod-85d586896f-dgmzs discovery     "pilot_vservice_dup_domain": {
istiod-85d586896f-dgmzs discovery         "backend.dev.svc.cluster1.a.example.net:9898": {
istiod-85d586896f-dgmzs discovery             "proxy": "details-v1-5974b67c8-vz66r.istio-demo",
istiod-85d586896f-dgmzs discovery             "message": "duplicate domain from  service: backend.dev.svc.cluster1.a.example.net:9898"
istiod-85d586896f-dgmzs discovery         }
istiod-85d586896f-dgmzs discovery     }
istiod-85d586896f-dgmzs discovery }
```
* Why Duplicate domain from service ?
