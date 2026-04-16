FROM node:20-alpine AS builder
RUN echo "THIS IS THE NEW DOCKERFILE 12345"
WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .

RUN npm run build


# -------- Production Stage --------
FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev

COPY --from=builder /app/dist ./dist

EXPOSE 3000

CMD ["node", "dist/index.js"]

# FROM node:20-alpine

# WORKDIR /app

# COPY package*.json ./
# RUN npm install

# COPY . .

# EXPOSE 3000


# CMD ["npx", "ts-node-dev", "--respawn", "--transpile-only", "--poll", "src/index.ts"]
