-- Card vault: PAN stored only as AES-256-GCM ciphertext; tokens are random.
CREATE TABLE "saved_cards" (
    "id" UUID NOT NULL,
    "customer_id" UUID NOT NULL,
    "token" VARCHAR(64) NOT NULL,
    "pan_ciphertext" BYTEA NOT NULL,
    "pan_fingerprint" CHAR(64) NOT NULL,
    "masked_pan" VARCHAR(19) NOT NULL,
    "expiry_month" SMALLINT,
    "expiry_year" SMALLINT,
    "holder_name" VARCHAR(120),
    "key_id" VARCHAR(64) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "revoked_at" TIMESTAMPTZ(6),
    CONSTRAINT "saved_cards_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "saved_cards_token_key" ON "saved_cards"("token");
CREATE UNIQUE INDEX "saved_cards_customer_id_pan_fingerprint_key" ON "saved_cards"("customer_id", "pan_fingerprint");
CREATE INDEX "saved_cards_customer_id_revoked_at_idx" ON "saved_cards"("customer_id", "revoked_at");

ALTER TABLE "saved_cards" ADD CONSTRAINT "saved_cards_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "customers"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
