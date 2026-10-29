import { generateKeyPairSync, sign, type KeyObject } from 'node:crypto';
import { canonicalRequest, ed25519PublicKey, MAX_SIGNATURE_AGE_MS, readSignedRequest, SignatureError, SignedRequest, verifySignedRequest } from './request-signature';

// Shared with test/core/security/request_signature_test.dart: RFC 8032 test 1
// key, a fixed request and its (deterministic) Ed25519 signature.
const vector = {
  publicKey: '11qYAYKxCrfVS_7TyWQHOg7hcvPapiMlrwIaaPcHURo',
  request: { method: 'POST', path: '/api/v1/transactions', timestamp: '1793260800000', nonce: 'bm9uY2UtMTIzNDU2Nzg5MA', body: Buffer.from('{"amount":1500,"currency":"AFN"}') },
  canonical: 'AFGHANPAY-ED25519-V1\nPOST\n/api/v1/transactions\n1793260800000\nbm9uY2UtMTIzNDU2Nzg5MA\nc002e953b937dd89941191670b2f24bc3d1beb0f4281787332a82824098cdada',
  signature: '6IUjnCKgSUIuV9LOPe6jg4gvqS0lwS1d9esKvRzTPMGTaO3EpA0970JkyhN6yENkVMzHx2KmWtAFDCxCPW6WDw',
};

function errorCode(fn: () => unknown): string | undefined {
  try { fn(); return undefined; } catch (error) { return error instanceof SignatureError ? error.code : 'OTHER'; }
}

function signed(privateKey: KeyObject, overrides: Partial<SignedRequest> = {}): SignedRequest {
  const base = { method: 'GET', path: '/api/v1/cards', timestamp: String(Date.now()), nonce: 'AAAAAAAAAAAAAAAAAAAAAA', body: Buffer.alloc(0), ...overrides };
  return { ...base, signature: sign(null, Buffer.from(canonicalRequest(base)), privateKey).toString('base64url') };
}

describe('device request signature', () => {
  const { privateKey, publicKey } = generateKeyPairSync('ed25519');
  const rawPublicKey = (publicKey.export({ format: 'jwk' }) as { x: string }).x;

  it('matches the shared test vector', () => {
    expect(canonicalRequest(vector.request)).toBe(vector.canonical);
    const now = Number(vector.request.timestamp);
    expect(() => verifySignedRequest(vector.publicKey, { ...vector.request, signature: vector.signature }, now)).not.toThrow();
  });

  it('accepts a fresh request signed by the device key', () => {
    expect(() => verifySignedRequest(rawPublicKey, signed(privateKey))).not.toThrow();
  });

  it('rejects a request whose body, path or method changed after signing', () => {
    const request = signed(privateKey, { method: 'POST', body: Buffer.from('{"amount":10}') });
    for (const tampered of [{ ...request, body: Buffer.from('{"amount":99}') }, { ...request, path: '/api/v1/other' }, { ...request, method: 'PUT' }]) {
      expect(errorCode(() => verifySignedRequest(rawPublicKey, tampered))).toBe('DEVICE_SIGNATURE_INVALID');
    }
  });

  it('rejects a signature from another device', () => {
    const other = generateKeyPairSync('ed25519');
    expect(errorCode(() => verifySignedRequest(rawPublicKey, signed(other.privateKey)))).toBe('DEVICE_SIGNATURE_INVALID');
  });

  it('rejects requests outside the time window', () => {
    const old = signed(privateKey, { timestamp: String(Date.now() - MAX_SIGNATURE_AGE_MS - 1000) });
    expect(errorCode(() => verifySignedRequest(rawPublicKey, old))).toBe('DEVICE_SIGNATURE_EXPIRED');
  });

  it('requires all signature headers in the expected format', () => {
    const headers: Record<string, string> = { 'x-request-timestamp': String(Date.now()), 'x-request-nonce': 'AAAAAAAAAAAAAAAAAAAAAA', 'x-device-signature': vector.signature };
    const read = (values: Record<string, string>) => () => readSignedRequest('GET', '/', (name) => values[name], undefined);
    expect(errorCode(read(headers))).toBeUndefined();
    expect(errorCode(read({ ...headers, 'x-device-signature': '' }))).toBe('DEVICE_SIGNATURE_REQUIRED');
    expect(errorCode(read({ ...headers, 'x-request-nonce': 'short' }))).toBe('DEVICE_SIGNATURE_INVALID');
    expect(errorCode(read({ ...headers, 'x-request-timestamp': 'now' }))).toBe('DEVICE_SIGNATURE_INVALID');
  });

  it('rejects malformed public keys', () => {
    expect(errorCode(() => ed25519PublicKey('not-a-key'))).toBe('DEVICE_SIGNATURE_INVALID');
  });
});
