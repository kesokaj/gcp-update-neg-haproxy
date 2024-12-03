````
apt install haproxy -y
curl -fo /tmp/update-haproxy.sh https://raw.githubusercontent.com/kesokaj/gcp-update-neg-haproxy/refs/heads/master/update-haproxy.sh
chmod a+x /tmp/update-haproxy.sh
nohup bash -c 'while true; do /tmp/update-haproxy.sh; sleep 5; done' > /var/log/update-haproxy.log 2>&1 &
````


````
apt install screen python3 python3-pip python3-locust python3-dev -y
screen -S locust
locust -f locustfile.py --print-stats --headless --autostart --spawn-rate 10 --users 1000 --host <IP>
````

## https://docs.locust.io/en/stable/configuration.html