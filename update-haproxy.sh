#!/bin/bash

# Set the Internal Field Separator (IFS) to newline
IFS=$'\n'

REGION=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/zone | awk -F '/' '{print substr($4, 1, length($4)-2)}')
NEG=$(curl -sH "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/NEG_TO_UPDATE)
HAPROXY_CFG="/etc/haproxy/haproxy.cfg"
HAPROXY_CFG_TMP="/etc/haproxy/haproxy.cfg.tmp"
ZONES=$(gcloud compute zones list --filter=region=$REGION --format="value(NAME)")
ENDPOINT_NUMBER=1

cat > $HAPROXY_CFG_TMP <<EOF
global
  daemon
  maxconn 100000
  stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
  stats timeout 30s  

defaults
  mode http
  timeout connect 5000ms
  timeout client 50000ms
  timeout server 50000ms

listen stats
  bind *:3000
  stats enable
  stats uri /
  stats hide-version
  stats refresh 5s

frontend front
  bind  *:80
  default_backend back

backend back
  timeout queue 30s
  balance roundrobin
EOF

for ZONE in $ZONES; do
  ENDPOINTS=""
  ENDPOINTS+=$(gcloud compute network-endpoint-groups list-network-endpoints $NEG \
      --zone=$ZONE \
      --format="value(IP_ADDRESS,PORT)" 2>/dev/null | \
      sed 's/[[:space:]]\+/:/g')
    for ENDPOINT in $ENDPOINTS; do
      echo "  server endpoint$ENDPOINT_NUMBER $ENDPOINT check inter 3s fall 3 rise 2" >> $HAPROXY_CFG_TMP
      ENDPOINT_NUMBER=$((ENDPOINT_NUMBER+1))
    done
done

if ! cmp -s $HAPROXY_CFG $HAPROXY_CFG_TMP; then
  echo "HAProxy configuration files differ. Updating..."
  mv $HAPROXY_CFG_TMP $HAPROXY_CFG

  if ! systemctl is-active --quiet haproxy; then
    echo "HAProxy is not running. Starting it..."
    systemctl start haproxy
  fi

  systemctl reload haproxy
  echo "HAProxy reloaded."
else
  echo "HAProxy configuration files are identical. No changes made."
fi