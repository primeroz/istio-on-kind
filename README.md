
## Test Upgrade

```
ENV=default ./kind.sh create
ENV=default ./setup-simple15.sh

istioctl proxy-status

ENV=default ./upgrade16.sh
# wait
istioctl proxy-status
# if needed restart all deployments in other namespaces
k
ENV=default ./upgrade17.sh
# wait
istioctl proxy-status
# if needed restart all deployments in other namespaces
kubectl rollout restart -n namespace WORKLOAD_TYPE

ubectl rollout restart -n namespace WORKLOAD_TYPE

ENV=default ./upgrade18.sh
# wait
istioctl proxy-status
# if needed restart all deployments in other namespaces
kubectl rollout restart -n namespace WORKLOAD_TYPE


```
