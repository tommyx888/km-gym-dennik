# KM GYM Denník – jednokontajnerový obraz pre Railway (a podobné PaaS bez docker-compose).
# Spojí frontend (nginx) + API (Node) do jedného kontajnera na jednom porte, aby passkeys
# mali jeden origin. Dáta členov sú v /data – na Railway tam pripoj Volume.
# Build context = koreň repozitára (railway.json → dockerfilePath).

# --- 1. frontend build (rovnako ako web/Dockerfile upstreamu) ---
FROM node:22-alpine AS build
WORKDIR /app/frontend
COPY frontend/package.json frontend/package-lock.json* ./
RUN npm ci --ignore-scripts
COPY api/coach/core/ /app/api/coach/core/
COPY frontend/ ./
ARG APP_BUILD=""
RUN APP_BUILD="$APP_BUILD" npm run build

# --- 2. obrázky a GIFy cvikov (~140 MB, CC licencia – pozri NOTICE.md) ---
FROM alpine/git AS media
RUN git clone --depth 1 https://github.com/hasaneyldrm/exercises-dataset /ds \
 && rm -rf /ds/.git

# --- 3. runtime: Node API + nginx v jednom ---
FROM node:22-alpine
RUN apk add --no-cache nginx gettext && apk upgrade --no-cache
WORKDIR /app
COPY api/package.json api/package-lock.json* ./
RUN npm ci --omit=dev --omit=optional && npm cache clean --force
COPY api/*.js ./
COPY api/coach ./coach
COPY --from=build /app/frontend/dist /usr/share/nginx/html
COPY --from=media /ds/images /usr/share/nginx/html/img
COPY --from=media /ds/videos /usr/share/nginx/html/gif
COPY deploy/railway/nginx.conf.template /etc/nginx/templates/default.conf.template
COPY deploy/railway/start.sh /start.sh
RUN chmod +x /start.sh && mkdir -p /data /run/nginx

ENV NODE_ENV=production \
    DATA_DIR=/data \
    API_PORT=3000 \
    PORT=8080 \
    TRUST_PROXY=1
EXPOSE 8080
HEALTHCHECK --interval=5m --timeout=5s --retries=3 \
  CMD wget --spider -q "http://127.0.0.1:${PORT}/api/health" || exit 1
CMD ["/start.sh"]
