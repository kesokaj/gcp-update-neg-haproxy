````
apt install haproxy -y
curl -fo /tmp/update-haproxy.sh https://raw.githubusercontent.com/kesokaj/gcp-update-neg-haproxy/refs/heads/master/update-haproxy.sh
chmod a+x /tmp/update-haproxy.sh
nohup bash -c 'while true; do /tmp/update-haproxy.sh; sleep 5; done' > /var/log/update-haproxy.log 2>&1 &
````