# Afghan EMI Admin Portal

Separate React + TypeScript + Vite administration web app for the Flutter
system. It provides a disconnected UI preview and a live, typed integration
with the repository's NestJS backend, including dashboard, transaction,
customer, user, notification, configuration, dynamic-content, monitoring, and
audit views. See [`../ADMIN_PORTAL.md`](../ADMIN_PORTAL.md) for architecture,
setup, and security requirements.

## Run locally

Requires Node.js 20.19+ (or 22.12+) and npm.

```sh
npm ci
cp .env.example .env.local
npm run dev
```

Open `http://localhost:5173`. With `VITE_API_BASE_URL=http://localhost:8081`,
the sign-in screen uses the live backend; otherwise use the disconnected
preview. `.env.example` contains public placeholders only. Never put credentials in
`VITE_*` variables.

Vite supports environment-specific `.env.development`, `.env.uat`, and
`.env.production` files (all ignored by Git). Set only the public,
same-origin `VITE_API_BASE_URL` in each deployment environment. For UAT use
`npm run dev:uat` or `npm run build:uat`; production builds use
`npm run build:production`. The API path must be routed to the Admin API by
the deployment ingress/reverse proxy; this portal image contains static files
only, not the backend.

## Static container

```sh
docker build --build-arg VITE_API_BASE_URL=https://portal.example.invalid -t afghan-emi-admin:local .
docker run --rm -p 8080:8080 afghan-emi-admin:local
```

The container has SPA fallback, `/healthz`, and restrictive browser headers.
The API URL is public configuration, not a secret. Do not use the container for
production until the API/BFF and same-origin `/api/` ingress route are deployed.

## Checks

```sh
npm test
npm run lint
npm run build
```

Production deployment still requires an external security review, managed
secrets, TLS, backups, and approved identity/recovery policies.
