import { createHash, createPublicKey, verify, type KeyObject } from 'node:crypto';

/**
 * Device request signing (APS p.27, p.49, p.54): every mobile request is signed
 * with the Ed25519 key the app created for this installation and registered at
 * login. Format shared with `lib/src/core/security/request_signature.dart`.
 */
export const SIGNATURE_SCHEME = 'AFGHANPAY-ED25519-V1';
export const MAX_SIGNATURE_AGE_MS = 5 * 60_000;
export const NONCE_TTL_MS = 2 * MAX_SIGNATURE_AGE_MS;

export const SIGNATURE_HEADERS = {
  timestamp: 'x-request-timestamp',
  nonce: 'x-request-nonce',
  signature: 'x-device-signature',
} as const;

export type SignatureFailure = 'DEVICE_SIGNATURE_REQUIRED' | 'DEVICE_SIGNATURE_INVALID' | 'DEVICE_SIGNATURE_EXPIRED';

export class SignatureError extends Error {
  constructor(readonly code: SignatureFailure) { super(code); }
}

export interface SignedRequest {
  method: string;
  /** Path and query exactly as sent, e.g. `/api/v1/transactions?page=0`. */
  path: string;
  timestamp: string;
  nonce: string;
  signature: string;
  body: Buffer;
}

/** The bytes that are signed; any change to method, path, time, nonce or body breaks the signature. */
export function canonicalRequest(request: Omit<SignedRequest, 'signature'>): string {
  return [
    SIGNATURE_SCHEME,
    request.method.toUpperCase(),
    request.path,
    request.timestamp,
    request.nonce,
    createHash('sha256').update(request.body).digest('hex'),
  ].join('\n');
}

/** A raw 32-byte Ed25519 public key in base64url, or throws. */
export function ed25519PublicKey(rawBase64Url: string): KeyObject {
  if (!/^[A-Za-z0-9_-]{43}$/.test(rawBase64Url)) throw new SignatureError('DEVICE_SIGNATURE_INVALID');
  return createPublicKey({ key: { kty: 'OKP', crv: 'Ed25519', x: rawBase64Url }, format: 'jwk' });
}

/** Reads the signature headers; throws when any is missing or malformed. */
export function readSignedRequest(
  method: string,
  path: string,
  header: (name: string) => string | undefined,
  body: Buffer | undefined,
): SignedRequest {
  const timestamp = header(SIGNATURE_HEADERS.timestamp);
  const nonce = header(SIGNATURE_HEADERS.nonce);
  const signature = header(SIGNATURE_HEADERS.signature);
  if (!timestamp || !nonce || !signature) throw new SignatureError('DEVICE_SIGNATURE_REQUIRED');
  if (!/^\d{13}$/.test(timestamp) || !/^[A-Za-z0-9_-]{16,64}$/.test(nonce) || !/^[A-Za-z0-9_-]{86}$/.test(signature)) {
    throw new SignatureError('DEVICE_SIGNATURE_INVALID');
  }
  return { method, path, timestamp, nonce, signature, body: body ?? Buffer.alloc(0) };
}

/** Checks freshness and the Ed25519 signature. Replay (nonce reuse) is checked by the caller. */
export function verifySignedRequest(publicKey: string, request: SignedRequest, now = Date.now()): void {
  if (Math.abs(now - Number(request.timestamp)) > MAX_SIGNATURE_AGE_MS) throw new SignatureError('DEVICE_SIGNATURE_EXPIRED');
  const valid = verify(null, Buffer.from(canonicalRequest(request)), ed25519PublicKey(publicKey), Buffer.from(request.signature, 'base64url'));
  if (!valid) throw new SignatureError('DEVICE_SIGNATURE_INVALID');
}
