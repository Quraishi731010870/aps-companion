# Monitoring integration

Docker Compose now provisions Prometheus, Grafana, PostgreSQL exporter, Redis exporter, and node exporter. Prometheus scrapes the backend `/metrics` endpoint and the exporters. Grafana automatically provisions the Prometheus data source and three dashboards from `monitoring/grafana/`:

- Afghan EMI — Application Overview
- Afghan EMI — Transactions
- Afghan EMI — Infrastructure

Transaction gauges are calculated from PostgreSQL at scrape time, so database records—not dashboard constants—drive the transaction panels. Grafana uses `http://localhost:3000`; Prometheus uses `http://localhost:9090`. Credentials come from ignored local environment configuration.

Zabbix can monitor `/health/live`, `/health/ready`, `/health`, and `/metrics`, or the same exporter endpoints from a trusted monitoring network. No Zabbix connection is claimed unless its URL and token are configured server-side.

The portal's monitoring screens consume only the authenticated Admin API
contract (`GET /monitoring/overview`, `/monitoring/transactions`, and
`/monitoring/alerts`). They never call Zabbix or Grafana directly and display
unavailable/grey states if no backend result exists. The API schema is in
[`backend/admin-api/openapi.yaml`](backend/admin-api/openapi.yaml).

## Historical environment discovery

On the current development machine, Zabbix server and agent executables and
configuration files are present. No Zabbix server/agent process was visible in
the process scan. Service-manager status checks were blocked by the sandbox's
system bus permissions, so this does not establish whether an external/host
service is running. No Zabbix endpoint, API token, or backend proxy config is
provided to the portal. The integration status is therefore **not configured**.

This section described the machine before the Compose monitoring stack was
added. The repository now provisions Grafana and Prometheus; they are only
considered active after `docker compose up` and endpoint verification.

## Zabbix

When an authorized backend host and Zabbix API token are provided, configure
`ZABBIX_API_URL` and `ZABBIX_API_TOKEN` in the server-side secret manager (the
blank entries in `backend/admin-api/.env.example` are documentation only).
Implement the Zabbix JSON-RPC adapter in the Admin API and normalize host
availability, problems/triggers, metrics, and timestamps into the documented
monitoring DTOs. Keep token auth server-side. Restrict the integration to a
read-only Zabbix account and allowed host groups/item keys. Use bounded
timeouts, response validation, and redaction. Never expose the API token or
direct Zabbix URL via a `VITE_*` variable.

## Grafana

Configure a server-side Grafana base URL and an SSO-protected dashboard route.
The API should return only an allow-listed, user-authorized dashboard URL (or
issue a short-lived SSO handoff); never proxy admin credentials to the browser.
Do not embed dashboards with anonymous public access. The current portal shows
integration status only and does not claim to render Grafana dashboards.

## Required telemetry

For application/API/database/server/network monitoring, connect a supported
collector (e.g. Zabbix agents/exporters) and have the Admin API return
timestamped values plus explicit healthy/warning/critical/unavailable state.
Transaction success/failure/latency/reversal metrics must come from the
authoritative payment service or ledger, not from the Flutter mock gateway or
prototype spreadsheet. Alert acknowledgement/resolution remains disabled
until backend permissions, supported provider actions, and audit persistence
are implemented.
