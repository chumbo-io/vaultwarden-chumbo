# chumbo Vault

> Gestor de contraseñas privado para chumbo.io  
> Basado en [Vaultwarden CE](https://github.com/dani-garcia/vaultwarden) — compatible con todos los clientes Bitwarden.

---

## Arquitectura

```
Internet (HTTPS)
      │
      ▼  Railway termina TLS en el edge → nuestro nginx solo habla HTTP internamente
┌─────────────────────┐
│   vault-proxy       │  nginx — inyecta branding chumbo via sub_filter
│   puerto 8080       │  Variables: VAULT_UPSTREAM, PORT
└──────┬──────────────┘
       │ proxy_pass http://${VAULT_UPSTREAM}:80  (red privada Railway)
       ▼
┌─────────────────────┐
│   vaultwarden       │  vaultwarden/server:latest
│   puerto 80         │  Datos en volumen /data
└─────────────────────┘
```

---

## Desarrollo local (HTTPS con mkcert)

```bash
# 1. Primera vez: generar certificados
mkdir -p certs
mkcert -install
mkcert -cert-file certs/vault.crt -key-file certs/vault.key 192.168.1.7 localhost 127.0.0.1

# 2. Levantar el stack
docker compose up -d --build

# 3. Acceder desde Windows → https://192.168.1.7:8443
```

---

## Despliegue en Railway

### Paso 1 — Subir este repo a GitHub

```bash
git init && git add . && git commit -m "chumbo vault proxy"
git remote add origin https://github.com/TU_USUARIO/vaultwarden-chumbo.git
git push -u origin main
```

### Paso 2 — Crear proyecto Railway

railway.app → **New Project** → **Empty Project** → nombrar `chumbo-vault`

---

### Paso 3 — Servicio `vaultwarden`

**Add Service → Docker Image** → `vaultwarden/server:latest`

Variables de entorno:
```env
SIGNUPS_ALLOWED=false
WEBSOCKET_ENABLED=true
LOG_LEVEL=warn
ADMIN_TOKEN=<openssl rand -base64 48>
```

Volumen → **Mount path: `/data`** ← ⚠️ CRÍTICO: sin esto las contraseñas se borran al reiniciar

---

### Paso 4 — Servicio `vault-proxy`

**Add Service → GitHub Repo** → seleccionar `vaultwarden-chumbo`

Variables de entorno:
```env
PORT=8080
VAULT_UPSTREAM=${{vaultwarden.RAILWAY_PRIVATE_DOMAIN}}
```

> Railway sustituye `${{vaultwarden.RAILWAY_PRIVATE_DOMAIN}}` por el hostname
> interno del servicio vaultwarden en la red privada.

**Settings → Networking → Generate Domain** → copiar la URL generada.

---

### Paso 5 — Añadir DOMAIN a vaultwarden

En el servicio `vaultwarden` → Variables:
```env
DOMAIN=https://<url-de-vault-proxy>.up.railway.app
```
> Debe ser la URL pública del `vault-proxy`, no la interna de vaultwarden.

---

### Paso 6 — Crear cuenta y cerrar registro

1. Abrir la URL pública del vault-proxy
2. Crear tu cuenta
3. `vaultwarden` → Variables → `SIGNUPS_ALLOWED=false` → redeploy ✅

---

## Clientes Bitwarden

Configurar en todos los clientes:  
**Self-hosted environment** → URL del `vault-proxy`

---

## Coste Railway (Hobby $5/mes base)

| Servicio | RAM | Coste aprox. |
|----------|-----|-------------|
| vaultwarden (Rust) | ~20 MB | ~$0.10/mes |
| vault-proxy (nginx) | ~5 MB | ~$0.05/mes |
| Volumen 1 GB | — | ~$0.25/mes |
| **Total adicional** | | **< $0.50/mes** |

---

## Por qué NO Cloudflare

- **Pages** → solo estáticos, no Docker
- **Workers** → sin WebSockets ni volúmenes de datos
- **Railway** → Docker nativo + volúmenes + HTTPS automático ✅

---

*by Vaultwarden CE · © chumbo.io*
