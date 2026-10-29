-- Saved cards keep only the encrypted card number; the expiry is checked at linking and discarded.
ALTER TABLE "saved_cards" DROP COLUMN "expiry_month",
DROP COLUMN "expiry_year";
