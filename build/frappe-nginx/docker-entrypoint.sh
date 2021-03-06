#!/bin/bash

## Thanks
# https://serverfault.com/a/919212
##

set -e

rsync -a --delete /var/www/html/assets/js /assets
rsync -a --delete /var/www/html/assets/css /assets
rsync -a --delete /var/www/html/assets/frappe /assets
. /rsync

chmod -R 755 /assets

touch /var/www/html/sites/.build -r $(ls -td /assets/* | head -n 1)

if [[ -z "$FRAPPE_PY" ]]; then
    export FRAPPE_PY=0.0.0.0
fi

if [[ -z "$FRAPPE_PY_PORT" ]]; then
    export FRAPPE_PY_PORT=8000
fi

if [[ -z "$FRAPPE_SOCKETIO" ]]; then
    export FRAPPE_SOCKETIO=0.0.0.0
fi

if [[ -z "$SOCKETIO_PORT" ]]; then
    export SOCKETIO_PORT=9000
fi

if [[ -z "$HTTP_TIMEOUT" ]]; then
    export HTTP_TIMEOUT=120
fi

if [[ -z "$UPSTREAM_REAL_IP_ADDRESS" ]]; then
    export UPSTREAM_REAL_IP_ADDRESS=127.0.0.1
fi

if [[ -z "$UPSTREAM_REAL_IP_RECURSIVE" ]]; then
    export UPSTREAM_REAL_IP_RECURSIVE=off
fi

if [[ -z "$UPSTREAM_REAL_IP_HEADER" ]]; then
    export UPSTREAM_REAL_IP_HEADER="X-Forwarded-For"
fi

envsubst '${FRAPPE_PY}
    ${FRAPPE_PY_PORT}
    ${FRAPPE_SOCKETIO}
    ${SOCKETIO_PORT}
    ${HTTP_TIMEOUT}
    ${UPSTREAM_REAL_IP_ADDRESS}
    ${UPSTREAM_REAL_IP_RECURSIVE}
    ${UPSTREAM_REAL_IP_HEADER}' \
    < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf

echo "Waiting for frappe-python to be available on $FRAPPE_PY port $FRAPPE_PY_PORT"
timeout 10 bash -c 'until printf "" 2>>/dev/null >>/dev/tcp/$0/$1; do sleep 1; done' $FRAPPE_PY $FRAPPE_PY_PORT
echo "Frappe-python available on $FRAPPE_PY port $FRAPPE_PY_PORT"
echo "Waiting for frappe-socketio to be available on $FRAPPE_SOCKETIO port $SOCKETIO_PORT"
timeout 10 bash -c 'until printf "" 2>>/dev/null >>/dev/tcp/$0/$1; do sleep 1; done' $FRAPPE_SOCKETIO $SOCKETIO_PORT
echo "Frappe-socketio available on $FRAPPE_SOCKETIO port $SOCKETIO_PORT"

exec "$@"
