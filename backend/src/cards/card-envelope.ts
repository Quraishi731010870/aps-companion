import { constants, createCipheriv, createDecipheriv, createHash, createHmac, hkdfSync, KeyObject, privateDecrypt, publicEncrypt, randomBytes } from 'node:crypto';

/**
 * Hybrid encryption for card data sent by the mobile app (APS spec p.31).
 *
 * The app generates a fresh AES-256-GCM key per request, encrypts the card
 * JSON with it, and wraps the key with this server's RSA-OAEP-256 public key.
 * Only the private key on the server can unwrap it, so neither a
 * man-in-the-middle nor the app itself can read an intercepted payload.
 * Mirrored in `lib/src/features/payments/data/card_encryptor.dart`.
 */
export const ENVELOPE_VERSION = 1;
export const ENVELOPE_ALGORITHM = 'RSA-OAEP-256+A256GCM';
/** Rejects replays of a captured envelope after this window. */
export const MAX_ENVELOPE_AGE_MS = 5 * 60_000;

export interface CardEnvelope { v: number; kid: string; ek: string; iv: string; ct: string }
export interface CardPlaintext { pan: string; expMonth?: number; expYear?: number; holder?: string; ts: number }
export interface RsaPublicJwk { kty: 'RSA'; n: string; e: string }

export type EnvelopeErrorCode = 'UNSUPPORTED_ENVELOPE' | 'DECRYPTION_FAILED' | 'INVALID_CARD' | 'EXPIRED_ENVELOPE';
export class EnvelopeError extends Error {
  constructor(readonly code: EnvelopeErrorCode) { super(code); }
}

/** RFC 7638 JWK thumbprint (SHA-256, base64url); used as the key id and pinned by the app. */
export function jwkThumbprint(jwk: RsaPublicJwk): string {
  return createHash('sha256').update(JSON.stringify({ e: jwk.e, kty: 'RSA', n: jwk.n })).digest('base64url');
}

/** Binds the ciphertext to its purpose and key so it cannot be reused elsewhere. */
export function envelopeAad(kid: string): Buffer {
  return Buffer.from(`afghanpay-card-v1|${kid}`, 'utf8');
}

export function openEnvelope(privateKey: KeyObject, kid: string, envelope: CardEnvelope, now = Date.now()): CardPlaintext {
  if (envelope.v !== ENVELOPE_VERSION || envelope.kid !== kid) throw new EnvelopeError('UNSUPPORTED_ENVELOPE');
  let plaintext: Buffer;
  try {
    const contentKey = privateDecrypt({ key: privateKey, padding: constants.RSA_PKCS1_OAEP_PADDING, oaepHash: 'sha256' }, Buffer.from(envelope.ek, 'base64url'));
    const iv = Buffer.from(envelope.iv, 'base64url');
    const sealed = Buffer.from(envelope.ct, 'base64url');
    if (contentKey.length !== 32 || iv.length !== 12 || sealed.length <= 16) throw new Error('bad sizes');
    const decipher = createDecipheriv('aes-256-gcm', contentKey, iv);
    decipher.setAAD(envelopeAad(kid));
    decipher.setAuthTag(sealed.subarray(sealed.length - 16));
    plaintext = Buffer.concat([decipher.update(sealed.subarray(0, sealed.length - 16)), decipher.final()]);
    contentKey.fill(0);
  } catch {
    throw new EnvelopeError('DECRYPTION_FAILED');
  }
  const card = parseCard(plaintext);
  plaintext.fill(0);
  if (Math.abs(now - card.ts) > MAX_ENVELOPE_AGE_MS) throw new EnvelopeError('EXPIRED_ENVELOPE');
  return card;
}

/** Same format the app produces; used by tests and server-side tooling. */
export function sealEnvelope(publicKey: KeyObject, kid: string, card: CardPlaintext): CardEnvelope {
  const contentKey = randomBytes(32);
  const iv = randomBytes(12);
  const cipher = createCipheriv('aes-256-gcm', contentKey, iv);
  cipher.setAAD(envelopeAad(kid));
  const ct = Buffer.concat([cipher.update(JSON.stringify(card), 'utf8'), cipher.final(), cipher.getAuthTag()]);
  const ek = publicEncrypt({ key: publicKey, padding: constants.RSA_PKCS1_OAEP_PADDING, oaepHash: 'sha256' }, contentKey);
  return { v: ENVELOPE_VERSION, kid, ek: ek.toString('base64url'), iv: iv.toString('base64url'), ct: ct.toString('base64url') };
}

/**
 * Sensitive authentication data (PCI DSS 3.3): never accepted in a card
 * envelope, so it cannot reach the vault, a transaction or a log.
 */
const FORBIDDEN_CARD_FIELDS = ['cvv', 'cvv2', 'cvc', 'cvc2', 'cid', 'securityCode', 'pin', 'pinBlock', 'track1', 'track2'];

/** True when the card's expiry month has fully passed. */
export function isExpired(expMonth: number, expYear: number, now = new Date()): boolean {
  return expYear < now.getUTCFullYear() || (expYear === now.getUTCFullYear() && expMonth < now.getUTCMonth() + 1);
}

function parseCard(plaintext: Buffer): CardPlaintext {
  let value: unknown;
  try { value = JSON.parse(plaintext.toString('utf8')); } catch { throw new EnvelopeError('INVALID_CARD'); }
  if (typeof value !== 'object' || value === null) throw new EnvelopeError('INVALID_CARD');
  if (FORBIDDEN_CARD_FIELDS.some((field) => Object.keys(value).some((key) => key.toLowerCase() === field.toLowerCase()))) throw new EnvelopeError('INVALID_CARD');
  const { pan, expMonth, expYear, holder, ts } = value as Record<string, unknown>;
  if (typeof pan !== 'string' || !/^\d{12,19}$/.test(pan) || typeof ts !== 'number') throw new EnvelopeError('INVALID_CARD');
  if (expMonth !== undefined && (typeof expMonth !== 'number' || expMonth < 1 || expMonth > 12)) throw new EnvelopeError('INVALID_CARD');
  if (expYear !== undefined && (typeof expYear !== 'number' || expYear < 2000 || expYear > 2099)) throw new EnvelopeError('INVALID_CARD');
  if (holder !== undefined && (typeof holder !== 'string' || holder.length > 120)) throw new EnvelopeError('INVALID_CARD');
  return { pan, expMonth, expYear, holder, ts };
}

/** PCI-permitted display form: first six and last four digits, e.g. 603799******1234. */
export function maskPan(pan: string): string {
  return `${pan.slice(0, 6)}${'*'.repeat(pan.length - 10)}${pan.slice(-4)}`;
}

/** True for anything that looks like a raw card number (12–19 digits, separators ignored). */
export function looksLikePan(value: string | undefined): boolean {
  return value !== undefined && /^\d{12,19}$/.test(value.replace(/[\s-]/g, ''));
}

/**
 * Card vault at rest: AES-256-GCM with a key derived from CARD_VAULT_KEY,
 * bound to the owning customer so ciphertext cannot be moved between accounts.
 * Layout: iv(12) || ciphertext || tag(16).
 */
export class VaultCipher {
  private readonly encryptionKey: Buffer;
  private readonly fingerprintKey: Buffer;

  constructor(vaultKey: Buffer) {
    if (vaultKey.length !== 32) throw new Error('The vault key must be 32 bytes.');
    this.encryptionKey = Buffer.from(hkdfSync('sha256', vaultKey, Buffer.alloc(0), 'afghanpay-vault-enc-v1', 32));
    this.fingerprintKey = Buffer.from(hkdfSync('sha256', vaultKey, Buffer.alloc(0), 'afghanpay-vault-fp-v1', 32));
  }

  encrypt(pan: string, customerId: string): Buffer {
    const iv = randomBytes(12);
    const cipher = createCipheriv('aes-256-gcm', this.encryptionKey, iv);
    cipher.setAAD(Buffer.from(customerId, 'utf8'));
    return Buffer.concat([iv, cipher.update(pan, 'utf8'), cipher.final(), cipher.getAuthTag()]);
  }

  decrypt(sealed: Buffer, customerId: string): string {
    const decipher = createDecipheriv('aes-256-gcm', this.encryptionKey, sealed.subarray(0, 12));
    decipher.setAAD(Buffer.from(customerId, 'utf8'));
    decipher.setAuthTag(sealed.subarray(sealed.length - 16));
    return Buffer.concat([decipher.update(sealed.subarray(12, sealed.length - 16)), decipher.final()]).toString('utf8');
  }

  /** Keyed hash so the same card can be found without storing it in clear. */
  fingerprint(pan: string): string {
    return createHmac('sha256', this.fingerprintKey).update(pan).digest('hex');
  }
}
