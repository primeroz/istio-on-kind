
## Test Upgrade

```
./kind.sh create
./setup-simple15.sh

istioctl proxy-status

kubectl apply -f operator/1.6.14
# wait
kubectl rollout restart -n istio-demo deployment
# wait
istioctl proxy-status

kubectl apply -f operator/1.7.6
# wait
kubectl rollout restart -n istio-demo deployment
# wait
istioctl proxy-status

kubectl apply -f operator/1.8.2
# wait
kubectl rollout restart -n istio-demo deployment
# wait
istioctl proxy-status
```
