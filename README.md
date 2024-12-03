````
curl -fo /tmp/update-haproxy.sh https://raw.githubusercontent.com/kesokaj/gcp-update-neg-haproxy/refs/heads/master/update-haproxy.sh
chmod a+x /tmp/update-haproxy.sh
echo "*/15 * * * * /tmp/update-haproxy.sh > /var/log/haproxy-updater.log 2>&1" | crontab -
````