#!/bin/bash

# Set the Internal Field Separator (IFS) to newline
IFS=$'\n'

REGION=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/zone | awk -F '/' '{print substr($4, 1, length($4)-2)}')
NEG=$(curl -sH "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/NEG_TO_UPDATE)
HAPROXY_CFG="/etc/haproxy/haproxy.cfg"
HAPROXY_CFG_TMP="/etc/haproxy/haproxy.cfg.tmp"
ZONES=$(gcloud compute zones list --filter=region=$REGION --format="value(NAME)")

cat > $HAPROXY_CFG_TMP <<EOF
global
  daemon
  maxconn 100000
  stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
  stats timeout 30s  

defaults
  mode http
  timeout connect 5s
  timeout client 30s
  timeout server 60s

listen stats
  bind *:3000
  stats enable
  stats uri /
  stats hide-version
  stats refresh 2s

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
      ENDPOINT_HASH=$(echo "$ENDPOINT" | md5sum | awk '{print $1}')
      echo "  server $ENDPOINT_HASH $ENDPOINT check" >> $HAPROXY_CFG_TMP
    done
done

# Always check if HAProxy is running and start it if needed
if ! systemctl is-active --quiet haproxy; then
  echo "HAProxy is not running. Starting it..."
  if ! systemctl start haproxy; then
    echo "Error starting HAProxy!"
    exit 1  # Or handle the error appropriately
  fi
fi

# Compare configuration files
if ! cmp -s $HAPROXY_CFG $HAPROXY_CFG_TMP; then
  echo "HAProxy configuration files differ. Updating..."
  mv $HAPROXY_CFG_TMP $HAPROXY_CFG

  # Reload HAProxy configuration since it was already running and config changed
  if ! systemctl reload haproxy; then
    echo "Error reloading HAProxy!"
    exit 1  # Or handle the error appropriately
  fi
  echo "HAProxy reloaded."
else
  echo "HAProxy configuration files are identical. No changes made."
fi