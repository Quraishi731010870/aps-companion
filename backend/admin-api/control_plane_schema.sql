-- Proposed PostgreSQL control-plane schema only; not applied to any database.
-- Customer/transaction ledger entities are intentionally not duplicated here.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE admin_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  login TEXT NOT NULL,
  display_name TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('active', 'locked', 'disabled')),
  failed_login_count INTEGER NOT NULL DEFAULT 0 CHECK (failed_login_count >= 0),
  locked_until TIMESTAMPTZ,
  password_changed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX admin_users_login_ci_unique ON admin_users(lower(login));

CREATE TABLE admin_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL UNIQUE,
  display_name TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  is_system BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE admin_permissions (
  code TEXT PRIMARY KEY,
  description TEXT NOT NULL
);

CREATE TABLE admin_user_roles (
  user_id UUID NOT NULL REFERENCES admin_users(id) ON DELETE RESTRICT,
  role_id UUID NOT NULL REFERENCES admin_roles(id) ON DELETE RESTRICT,
  granted_by UUID REFERENCES admin_users(id) ON DELETE SET NULL,
  granted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, role_id)
);

CREATE TABLE admin_role_permissions (
  role_id UUID NOT NULL REFERENCES admin_roles(id) ON DELETE RESTRICT,
  permission_code TEXT NOT NULL REFERENCES admin_permissions(code) ON DELETE RESTRICT,
  granted_by UUID REFERENCES admin_users(id) ON DELETE SET NULL,
  granted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (role_id, permission_code)
);

CREATE TABLE admin_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES admin_users(id) ON DELETE CASCADE,
  session_id_hash BYTEA NOT NULL UNIQUE,
  csrf_token_hash BYTEA NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ NOT NULL,
  last_seen_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  revoked_at TIMESTAMPTZ,
  CHECK (expires_at > created_at)
);
CREATE INDEX admin_sessions_user_active_idx ON admin_sessions(user_id, expires_at) WHERE revoked_at IS NULL;

CREATE TABLE admin_audit_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  actor_user_id UUID REFERENCES admin_users(id) ON DELETE SET NULL,
  actor_login_snapshot TEXT NOT NULL,
  action_code TEXT NOT NULL,
  target_type TEXT,
  target_id TEXT,
  outcome TEXT NOT NULL CHECK (outcome IN ('success', 'denied', 'failure')),
  request_id TEXT NOT NULL,
  safe_metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);
CREATE INDEX admin_audit_events_time_idx ON admin_audit_events(occurred_at DESC);
CREATE INDEX admin_audit_events_actor_time_idx ON admin_audit_events(actor_user_id, occurred_at DESC);
CREATE INDEX admin_audit_events_target_idx ON admin_audit_events(target_type, target_id, occurred_at DESC);

-- Provision permissions and roles only via reviewed migrations. Never seed an
-- administrator/password. Restrict UPDATE/DELETE rights on audit events to a
-- separate retention/archival process and audit that process itself.
