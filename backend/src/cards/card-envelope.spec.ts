import { generateKeyPairSync, randomBytes } from 'node:crypto';
import { CardEnvelope, EnvelopeError, jwkThumbprint, looksLikePan, maskPan, MAX_ENVELOPE_AGE_MS, openEnvelope, RsaPublicJwk, sealEnvelope, VaultCipher } from './card-envelope';

const { privateKey, publicKey } = generateKeyPairSync('rsa', { modulusLength: 3072 });
const kid = jwkThumbprint(publicKey.export({ format: 'jwk' }) as RsaPublicJwk);
const card = { pan: '6037991234561234', expMonth: 12, expYear: 2029, holder: 'Demo Customer', ts: Date.now() };

function errorCode(fn: () => unknown): string | undefined {
  try { fn(); return undefined; } catch (error) { return error instanceof EnvelopeError ? error.code : 'OTHER'; }
}

function flipLastByte(value: string): string {
  const bytes = Buffer.from(value, 'base64url');
  bytes[bytes.length - 1] ^= 0x01;
  return bytes.toString('base64url');
}

describe('card envelope', () => {
  it('round-trips a card through seal and open', () => {
    expect(openEnvelope(privateKey, kid, sealEnvelope(publicKey, kid, card))).toEqual(card);
  });

  it('uses fresh randomness so equal cards encrypt differently', () => {
    const a = sealEnvelope(publicKey, kid, card);
    const b = sealEnvelope(publicKey, kid, card);
    expect(a.ct).not.toBe(b.ct);
    expect(a.ek).not.toBe(b.ek);
  });

  it('rejects a tampered ciphertext, wrapped key or iv', () => {
    const envelope = sealEnvelope(publicKey, kid, card);
    for (const field of ['ct', 'ek', 'iv'] as const) {
      const tampered: CardEnvelope = { ...envelope, [field]: flipLastByte(envelope[field]) };
      expect(errorCode(() => openEnvelope(privateKey, kid, tampered))).toBe('DECRYPTION_FAILED');
    }
  });

  it('rejects envelopes for another key or version', () => {
    const envelope = sealEnvelope(publicKey, kid, card);
    expect(errorCode(() => openEnvelope(privateKey, 'other-kid', envelope))).toBe('UNSUPPORTED_ENVELOPE');
    expect(errorCode(() => openEnvelope(privateKey, kid, { ...envelope, v: 2 }))).toBe('UNSUPPORTED_ENVELOPE');
  });

  it('cannot be opened with a different private key', () => {
    const other = generateKeyPairSync('rsa', { modulusLength: 3072 });
    expect(errorCode(() => openEnvelope(other.privateKey, kid, sealEnvelope(publicKey, kid, card)))).toBe('DECRYPTION_FAILED');
  });

  it('rejects replays older than the allowed window', () => {
    const old = sealEnvelope(publicKey, kid, { ...card, ts: Date.now() - MAX_ENVELOPE_AGE_MS - 1000 });
    expect(errorCode(() => openEnvelope(privateKey, kid, old))).toBe('EXPIRED_ENVELOPE');
  });

  it('rejects malformed card data', () => {
    for (const bad of [{ ...card, pan: '1234' }, { ...card, pan: '6037-9912-3456-1234' }, { ...card, expMonth: 13 }, { ...card, ts: 'now' }]) {
      const envelope = sealEnvelope(publicKey, kid, bad as never);
      expect(errorCode(() => openEnvelope(privateKey, kid, envelope))).toBe('INVALID_CARD');
    }
  });

  it('computes the RFC 7638 thumbprint (shared test vector with the app)', () => {
    const rfcExample: RsaPublicJwk = {
      kty: 'RSA',
      e: 'AQAB',
      n: '0vx7agoebGcQSuuPiLJXZptN9nndrQmbXEps2aiAFbWhM78LhWx4cbbfAAtVT86zwu1RK7aPFFxuhDR1L6tSoc_BJECPebWKRXjBZCiFV4n3oknjhMstn64tZ_2W-5JsGY4Hc5n9yBXArwl93lqt7_RN5w6Cf0h4QyQ5v-65YGjQR0_FDW2QvzqY368QQMicAtaSqzs8KJZgnYb9c7d0zgdAZHzu6qMQvRL5hajrn1n91CbOpbISD08qNLyrdkt-bFTWhAI4vMQFh6WeZu0fM4lFd2NcRwr3XPksINHaQ-G_xBniIqbw0Ls1jF44-csFCur-kEgU8awapJzKnqDKgw',
    };
    expect(jwkThumbprint(rfcExample)).toBe('NzbLsXh8uDCcd-6MNwXF4W_7noWXFZAfHkxZsRGC9Xs');
  });
});

describe('card helpers', () => {
  it('masks all but the first six and last four digits', () => {
    expect(maskPan('6037991234561234')).toBe('603799******1234');
    expect(maskPan('603799123456')).toBe('603799**3456');
  });

  it('detects raw card numbers, ignoring spaces and dashes', () => {
    expect(looksLikePan('6037991234561234')).toBe(true);
    expect(looksLikePan('6037 9912 3456 1234')).toBe(true);
    expect(looksLikePan('603799******1234')).toBe(false);
    expect(looksLikePan('WALLET-7814')).toBe(false);
    expect(looksLikePan(undefined)).toBe(false);
  });
});

describe('VaultCipher', () => {
  const vault = new VaultCipher(randomBytes(32));

  it('round-trips a PAN for the same customer', () => {
    expect(vault.decrypt(vault.encrypt(card.pan, 'customer-1'), 'customer-1')).toBe(card.pan);
  });

  it('never stores the PAN in clear', () => {
    expect(vault.encrypt(card.pan, 'customer-1').toString('utf8')).not.toContain(card.pan);
  });

  it('ciphertext cannot be moved to another customer', () => {
    expect(() => vault.decrypt(vault.encrypt(card.pan, 'customer-1'), 'customer-2')).toThrow();
  });

  it('fingerprints are stable per vault key and differ across keys', () => {
    expect(vault.fingerprint(card.pan)).toBe(vault.fingerprint(card.pan));
    expect(new VaultCipher(randomBytes(32)).fingerprint(card.pan)).not.toBe(vault.fingerprint(card.pan));
  });

  it('requires a 256-bit key', () => {
    expect(() => new VaultCipher(randomBytes(16))).toThrow();
  });
});

