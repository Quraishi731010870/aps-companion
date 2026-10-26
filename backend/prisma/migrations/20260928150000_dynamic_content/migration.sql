CREATE TABLE "dynamic_content" (
    "id" UUID NOT NULL,
    "key" VARCHAR(120) NOT NULL,
    "locale" VARCHAR(12) NOT NULL DEFAULT 'en',
    "platform" "Platform" NOT NULL DEFAULT 'ALL',
    "title" VARCHAR(200) NOT NULL,
    "body" TEXT NOT NULL,
    "enabled" BOOLEAN NOT NULL DEFAULT true,
    "metadata" JSONB NOT NULL DEFAULT '{}',
    "version" INTEGER NOT NULL DEFAULT 1,
    "updated_by" UUID,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,
    CONSTRAINT "dynamic_content_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "dynamic_content_key_locale_platform_key" ON "dynamic_content"("key", "locale", "platform");
CREATE INDEX "dynamic_content_enabled_platform_updated_at_idx" ON "dynamic_content"("enabled", "platform", "updated_at");
