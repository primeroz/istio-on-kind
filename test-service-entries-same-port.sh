docker run --rm -d --network=kind --name=netcat1 subfuzion/netcat -vkl 8888
docker run --rm -d --network=kind --name=netcat2 subfuzion/netcat -vkl 8888

kubectl run netcat --image=subfuzion/netcat --command -- sleep 3600

cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1beta1
kind: ServiceEntry
metadata:
  name: netcat1
  namespace: istio-system
spec:
  endpoints:
  - address: netcat1
  hosts:
  - netcat1
  location: MESH_EXTERNAL
  ports:
  - name: tcp
    number: 8888
    protocol: TCP
  resolution: DNS
EOF

# istioctl proxy-config listener netcat.istio-demo --port 8888 -o json
# istioctl proxy-config cluster netcat.istio-demo --fqdn "outbound|8888||netcat1" -o json
# 
# ### Test1
# 
# `docker logs netcat2 -f`
# `docker logs netcat1 -f`
# 
# `kubectl exec -t -i netcat -- sh`
# 
# `echo "blah" | nc netcat1 8888`
# `echo "blah" | nc netcat2 8888`
# 
# **Both echo show up in netcat1 server** even though in the logs i can see the ip being set correctly - `172.18.0.5` and `0.6`
# ```
# [2021-02-01T10:16:23.669Z] "- - -" 0 - "-" "-" 5 0 2579 - "-" "-" "-" "-" "172.18.0.5:8888" outbound|8888||netcat1 10.244.2.11:52094 172.18.0.6:8888 10.244.2.11:43666 - -
# [2021-02-01T10:16:35.255Z] "- - -" 0 - "-" "-" 5 0 857 - "-" "-" "-" "-" "172.18.0.5:8888" outbound|8888||netcat1 10.244.2.11:52382 172.18.0.5:8888 10.244.2.11:52380 - -
# ```
# 
# ### Create second service entry
# 
# 
# cat <<EOF | kubectl apply -f -
# apiVersion: networking.istio.io/v1beta1
# kind: ServiceEntry
# metadata:
#   name: netcat2
#   namespace: istio-system
# spec:
#   endpoints:
#   - address: netcat2
#   hosts:
#   - netcat2
#   location: MESH_EXTERNAL
#   ports:
#   - name: tcp
#     number: 8888
#     protocol: TCP
#   resolution: DNS
# EOF
# 
# `proxy-config` output is the same, only one cluster lister
# ```
#                         "name": "envoy.tcp_proxy",
#                         "typedConfig": {
#                             "@type": "type.googleapis.com/envoy.config.filter.network.tcp_proxy.v2.TcpProxy",
#                             "statPrefix": "outbound|8888||netcat1",
#                             "cluster": "outbound|8888||netcat1",
# ```
# 
# even though 2 clusters now exits
# ```
# istioctl proxy-config cluster netcat.istio-demo | grep netcat                          
# netcat1                                             8888      -               outbound      STRICT_DNS       
# netcat2                                             8888      -               outbound      STRICT_DNS 
# ```
# 
# ### test connections 
# 
# 
# `docker logs netcat2 -f`
# `docker logs netcat1 -f`
# 
# `kubectl exec -t -i netcat -- sh`
# 
# `echo "blah" | nc netcat1 8888`
# `echo "blah" | nc netcat2 8888`
# 
# Same as before, all connections to netcat1 , logs show resolution to 2 ips 
# ```
# [2021-02-01T10:20:10.420Z] "- - -" 0 - "-" "-" 5 0 2092 - "-" "-" "-" "-" "172.18.0.5:8888" outbound|8888||netcat1 10.244.2.11:57788 172.18.0.6:8888 10.244.2.11:49360 - -
# [2021-02-01T10:20:14.313Z] "- - -" 0 - "-" "-" 5 0 2367 - "-" "-" "-" "-" "172.18.0.5:8888" outbound|8888||netcat1 10.244.2.11:57890 172.18.0.5:8888 10.244.2.11:57888 - -
# ```
# 
# ### Remove netcat1 serviceentry
# 
# ```
# kubectl delete serviceentry -n istio-system netcat1
# serviceentry.networking.istio.io "netcat1" deleted
# ```
# 
# listener now direct traffic to netcat2 cluster
# ```
#                     {
#                         "name": "envoy.tcp_proxy",
#                         "typedConfig": {
#                             "@type": "type.googleapis.com/envoy.config.filter.network.tcp_proxy.v2.TcpProxy",
#                             "statPrefix": "outbound|8888||netcat2",
#                             "cluster": "outbound|8888||netcat2",
# ```
# 
# `docker logs netcat2 -f`
# `docker logs netcat1 -f`
# 
# `kubectl exec -t -i netcat -- sh`
# 
# `echo "blah" | nc netcat1 8888`
# `echo "blah" | nc netcat2 8888`
# 
# All requests show up on netcat2 now 
