```
TOKEN=$(python3 gen-jwt.py key.pem --expire 10 --path /)

while true
do
date; curl --header "Authorization: Bearer $TOKEN" http://172.18.0.3:32618/headers -s -o /dev/null -w "%{http_code}\n"
sleep 1
done

```
