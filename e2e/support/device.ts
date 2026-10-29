import { createHash, createPrivateKey, createPublicKey, randomBytes, sign } from 'node:crypto';

/**
 * Test device that signs requests exactly like the app
 * (lib/src/core/security/request_signature.dart, backend/src/devices/request-signature.ts).
 * The key is derived from a fixed seed so every run reuses one device binding.
 */
const SCHEME = 'AFGHANPAY-ED25519-V1';
const PKCS8_ED25519_PREFIX = Buffer.from('302e020100300506032b657004220420', 'hex');

export class TestDevice {
  readonly installationId: string;
  readonly publicKey: string;
  private readonly privateKey;

  constructor(name = 'e2e-playwright-device') {
    const seed = createHash('sha256').update(`afghanpay-e2e:${name}`).digest();
    this.privateKey = createPrivateKey({ key: Buffer.concat([PKCS8_ED25519_PREFIX, seed]), format: 'der', type: 'pkcs8' });
    this.publicKey = (createPublicKey(this.privateKey).export({ format: 'jwk' }) as { x: string }).x;
    this.installationId = name;
  }

  binding() {
    return { installationId: this.installationId, platform: 'WEB', publicKey: this.publicKey };
  }

  /** Signature headers for one request. [path] includes the query string. */
  sign(method: string, path: string, body = '', overrides: { timestamp?: string; nonce?: string } = {}): Record<string, string> {
    const timestamp = overrides.timestamp ?? String(Date.now());
    const nonce = overrides.nonce ?? randomBytes(16).toString('base64url');
    const canonical = [SCHEME, method.toUpperCase(), path, timestamp, nonce, createHash('sha256').update(body).digest('hex')].join('\n');
    return {
      'X-Request-Timestamp': timestamp,
      'X-Request-Nonce': nonce,
      'X-Device-Signature': sign(null, Buffer.from(canonical), this.privateKey).toString('base64url'),
    };
  }
}
