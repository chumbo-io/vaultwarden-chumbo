#!/bin/sh
# Sustituir variables de entorno en la plantilla nginx
# Variables usadas: ${VAULT_UPSTREAM}, ${PORT}
envsubst '${VAULT_UPSTREAM} ${PORT}' \
  < /etc/nginx/nginx.conf.template \
  > /etc/nginx/nginx.conf

echo "[chumbo-vault-proxy] upstream → ${VAULT_UPSTREAM}:80  port → ${PORT}"
exec nginx -g 'daemon off;'

