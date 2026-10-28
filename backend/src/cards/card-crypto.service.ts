import { BadRequestException, Injectable, ServiceUnavailableException } from '@nestjs/common';
import { createPrivateKey, createPublicKey, KeyObject } from 'node:crypto';
import { RuntimeConfig } from '../configuration/runtime-config.service';
import { CardEnvelope, CardPlaintext, ENVELOPE_ALGORITHM, EnvelopeError, jwkThumbprint, openEnvelope, RsaPublicJwk, VaultCipher } from './card-envelope';

export interface CardEncryptionKey extends RsaPublicJwk { kid: string; alg: 'RSA-OAEP-256'; use: 'enc'; envelope: typeof ENVELOPE_ALGORITHM }

/** Holds the card keys; card endpoints answer 503 until they are configured. */
@Injectable()
export class CardCryptoService {
  private readonly privateKey?: KeyObject;
  private readonly publicJwk?: CardEncryptionKey;
  private readonly vault?: VaultCipher;

  constructor(config: RuntimeConfig) {
    if (config.cardEncryptionPrivateKeyPem) {
      this.privateKey = createPrivateKey(config.cardEncryptionPrivateKeyPem);
      const bits = this.privateKey.asymmetricKeyDetails?.modulusLength ?? 0;
      if (this.privateKey.asymmetricKeyType !== 'rsa' || bits < 3072) throw new Error('CARD_ENCRYPTION_PRIVATE_KEY must be an RSA key of at least 3072 bits.');
      const jwk = createPublicKey(this.privateKey).export({ format: 'jwk' }) as RsaPublicJwk;
      this.publicJwk = { kty: 'RSA', n: jwk.n, e: jwk.e, kid: jwkThumbprint(jwk), alg: 'RSA-OAEP-256', use: 'enc', envelope: ENVELOPE_ALGORITHM };
    }
    if (config.cardVaultKey.length === 32) this.vault = new VaultCipher(config.cardVaultKey);
  }

  publicKey(): CardEncryptionKey {
    return this.ready().publicJwk;
  }

  /** Decrypts an app envelope; any failure is reported with a generic message. */
  open(envelope: CardEnvelope): CardPlaintext {
    const { privateKey, publicJwk } = this.ready();
    try {
      return openEnvelope(privateKey, publicJwk.kid, envelope);
    } catch (error) {
      const code = error instanceof EnvelopeError ? error.code : 'DECRYPTION_FAILED';
      throw new BadRequestException({ code: `CARD_${code}`, message: 'The card details could not be read. Please try again.' });
    }
  }

  vaultCipher(): VaultCipher {
    return this.ready().vault;
  }

  private ready(): { privateKey: KeyObject; publicJwk: CardEncryptionKey; vault: VaultCipher } {
    if (!this.privateKey || !this.publicJwk || !this.vault) {
      throw new ServiceUnavailableException({ code: 'CARD_ENCRYPTION_NOT_CONFIGURED', message: 'Card services are not available.' });
    }
    return { privateKey: this.privateKey, publicJwk: this.publicJwk, vault: this.vault };
  }
}
