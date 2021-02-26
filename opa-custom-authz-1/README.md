```
./setup.sh

kubectl apply -f common.yaml
kubectl apply -f deployment1.yaml
```


```
HOST=$(kubectl get node istio-control-plane -o json | jq '.status.addresses[0].address' -r)
PORT=$(kubectl -n opa get service opa-httpbin1 -o json | jq -r '.spec.ports[0].nodePort' )
ENDPOINT="http://$HOST:$PORT"
```

```
# 403
curl -v $ENDPOINT

# 200
curl -v $ENDPOINT/ip

# 403
curl -v $ENDPOINT

```



```
TOKEN=$(python3 gen-jwt.py key.pem --expire 10 --path / --role SuperSayan)

while true
do
date; curl --header "Authorization: Bearer $TOKEN" http://172.18.0.3:32618/headers -s -o /dev/null -w "%{http_code}\n"
sleep 1
done
```
