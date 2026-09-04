# syntax=docker/dockerfile:1

# ---- deps: production dependencies only ----
FROM node:24-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

# ---- runtime ----
FROM node:24-alpine AS runtime
ENV NODE_ENV=production \
    PORT=3030
WORKDIR /app

# 
COPY --from=deps --chown=node:node /app/node_modules ./node_modules
COPY --chown=node:node package.json ./
COPY --chown=node:node index.js ./

USER node
EXPOSE 3030

# Hits the existing "/" route; no extra tooling needed since node is present.
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:'+(process.env.PORT||3030)+'/').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

# Exec form => node is PID 1 and receives SIGTERM directly.
CMD ["node", "index.js"]
