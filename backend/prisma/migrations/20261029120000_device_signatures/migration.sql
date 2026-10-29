-- DropIndex
DROP INDEX "devices_installation_id_key";

-- AlterTable
ALTER TABLE "devices" ADD COLUMN     "bound_at" TIMESTAMPTZ(6),
ADD COLUMN     "key_algorithm" VARCHAR(16),
ADD COLUMN     "public_key" VARCHAR(64);

-- AlterTable
ALTER TABLE "transactions" ADD COLUMN     "device_id" UUID,
ADD COLUMN     "device_signature" VARCHAR(128);

-- CreateIndex
CREATE UNIQUE INDEX "devices_user_id_installation_id_key" ON "devices"("user_id", "installation_id");

-- CreateIndex
CREATE INDEX "transactions_device_id_idx" ON "transactions"("device_id");

-- AddForeignKey
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_device_id_fkey" FOREIGN KEY ("device_id") REFERENCES "devices"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

