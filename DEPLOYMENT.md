# Deployment and local development

Requirements: Docker Engine with Compose access, Flutter SDK, and Node.js 22. Copy `.env.example` to ignored `.env` and replace every `CHANGE_ME` value.

```bash
docker compose up -d postgres redis
docker compose run --rm backend npx prisma migrate deploy
docker compose run --rm -e SEED_ADMIN_PASSWORD backend npm run prisma:seed
docker compose up -d backend prometheus grafana postgres-exporter redis-exporter node-exporter admin-portal
```

Committed local service URLs:

- Admin portal: `http://localhost:8082`
- Backend API: `http://localhost:8081/api/v1`
- Swagger: `http://localhost:8081/api/docs`
- Health: `http://localhost:8081/health`
- Metrics: `http://localhost:8081/metrics`
- Prometheus: `http://localhost:9090`
- Grafana: `http://localhost:3000`

Flutter development API URLs:

- Android emulator: `http://10.0.2.2:8081`
- Physical device: the development machine's reachable LAN address
- Browser/desktop: `http://localhost:8081`

Build Flutter with `--dart-define-from-file=dart_defines.local.json`; never commit that file. Production requires HTTPS, managed secrets, managed PostgreSQL/Redis, trusted ingress origins, release signing, backups, and reviewed monitoring retention.
