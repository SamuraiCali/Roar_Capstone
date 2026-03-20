FROM node:20

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

# RUN npm run build

EXPOSE 3000

# Run the compiled JS file
# CMD ["npm", "run", "dev"]
CMD ["npx", "ts-node-dev", "--respawn", "--transpile-only", "--poll", "src/index.ts"]
# CMD ["node", "dist/index.js"]