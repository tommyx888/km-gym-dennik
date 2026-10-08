#!/bin/sh
# Railway nastaví PORT (verejný port kontajnera) – na ňom počúva nginx.
# API beží interne na API_PORT a nginx naň proxuje /api/.
set -eu
: "${PORT:=8080}"
: "${API_PORT:=3000}"
: "${DATA_DIR:=/data}"
mkdir -p "$DATA_DIR"
envsubst '${PORT} ${API_PORT}' < /etc/nginx/templates/default.conf.template > /etc/nginx/http.d/default.conf
nginx -t

PORT="$API_PORT" node /app/server.js &
API_PID=$!
nginx -g 'daemon off;' &
NGINX_PID=$!

stop() { kill -TERM "$API_PID" "$NGINX_PID" 2>/dev/null; wait; exit 0; }
trap stop TERM INT

# Ak spadne API alebo nginx, kontajner skončí a Railway ho reštartuje.
while kill -0 "$API_PID" 2>/dev/null && kill -0 "$NGINX_PID" 2>/dev/null; do sleep 2; done
echo "process exited – shutting down" >&2
kill -TERM "$API_PID" "$NGINX_PID" 2>/dev/null
wait
exit 1
