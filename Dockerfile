# ─────────────────────────────────────────────────────────────
# chumbo Vault — nginx branding layer sobre Vaultwarden CE
#
# Arquitectura en Railway:
#   Servicio A: vaultwarden   (imagen vaultwarden/server)
#   Servicio B: vault-proxy   (este Dockerfile — nginx)
#
# El proxy:
#   1. Inyecta chumbo-theme.css en todas las páginas HTML
#   2. Sirve el logo de chumbo
#   3. Reescribe los <title> a "chumbo Vault"
# ─────────────────────────────────────────────────────────────
FROM nginx:alpine

# Copiar template de configuración nginx (con ${VAULT_UPSTREAM} y ${PORT})
COPY nginx/nginx.conf.template /etc/nginx/nginx.conf.template

# Copiar assets estáticos de branding
COPY nginx/chumbo-theme.css /etc/nginx/chumbo-static/chumbo-theme.css
COPY nginx/chumbo-logo.svg  /etc/nginx/chumbo-static/chumbo-logo.svg

# Script de arranque: envsubst → nginx
COPY start.sh /start.sh
RUN chmod +x /start.sh \
 && chmod -R 755 /etc/nginx/chumbo-static \
 && mkdir -p /var/cache/nginx /var/log/nginx /tmp \
 && chown -R nginx:nginx /var/cache/nginx /var/log/nginx

EXPOSE 8080

CMD ["/start.sh"]
