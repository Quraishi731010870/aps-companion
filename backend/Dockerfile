FROM node:22.20-alpine AS dependencies
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

FROM dependencies AS build
COPY prisma ./prisma
RUN npx prisma generate
COPY nest-cli.json tsconfig.json tsconfig.build.json ./
COPY src ./src
RUN npm run build

FROM node:22.20-alpine AS runtime
ENV NODE_ENV=production
WORKDIR /app
RUN addgroup -S afghanpay && adduser -S afghanpay -G afghanpay
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY --from=build /app/prisma ./prisma
COPY package.json ./
USER afghanpay
EXPOSE 8080
CMD ["node", "dist/src/main.js"]
