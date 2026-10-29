-- Admin status controls: BLOCKED is an operator hold (fraud, compliance), distinct
-- from DISABLED (deactivated) and LOCKED (temporary sign-in lockout).
ALTER TYPE "AccountStatus" ADD VALUE IF NOT EXISTS 'BLOCKED';

-- Saved cards can be deactivated or blocked by operators; revoked_at stays the
-- customer's own removal.
ALTER TABLE "saved_cards" ADD COLUMN "status" "AccountStatus" NOT NULL DEFAULT 'ACTIVE';
