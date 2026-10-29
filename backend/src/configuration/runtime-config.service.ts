import { Injectable } from '@nestjs/common';
import Joi from 'joi';

const schema = Joi.object({
  NODE_ENV: Joi.string().valid('development', 'test', 'staging', 'production').default('development'),
  PORT: Joi.number().port().default(8080),
  DATABASE_URL: Joi.string().uri({ scheme: ['postgresql', 'postgres'] }).required(),
  REDIS_URL: Joi.string().uri({ scheme: ['redis', 'rediss'] }).required(),
  CORS_ORIGINS: Joi.string().required(),
  LOG_LEVEL: Joi.string().valid('fatal', 'error', 'warn', 'info', 'debug', 'trace').default('info'),
  JWT_ACCESS_SECRET: Joi.string().min(32).required(),
  JWT_REFRESH_SECRET: Joi.string().min(32).required().invalid(Joi.ref('JWT_ACCESS_SECRET')),
  JWT_ACCESS_TTL: Joi.string().default('15m'),
  JWT_REFRESH_TTL_DAYS: Joi.number().integer().positive().default(30),
  ADMIN_SESSION_TTL_MINUTES: Joi.number().integer().positive().default(30),
  ISO_API_BASE_URL: Joi.string().uri({ scheme: ['http', 'https'] }).allow('').default(''),
  ISO_API_TIMEOUT_MS: Joi.number().integer().min(1000).max(120000).default(30000),
  // Base64 of a PKCS#8 PEM RSA private key (>= 3072 bits). Empty disables card endpoints.
  CARD_ENCRYPTION_PRIVATE_KEY: Joi.string().base64().allow('').default(''),
  // Base64 of 32 random bytes: AES-256-GCM key for PANs at rest in the card vault.
  CARD_VAULT_KEY: Joi.string().base64().allow('').default(''),
  // Open customer sign-up (no KYC/OTP yet). Defaults to on outside production only.
  SELF_REGISTRATION_ENABLED: Joi.boolean(),
}).unknown(true);

@Injectable()
export class RuntimeConfig {
  readonly nodeEnv: string;
  readonly port: number;
  readonly databaseUrl: string;
  readonly redisUrl: string;
  readonly corsOrigins: string[];
  readonly jwtAccessSecret: string;
  readonly jwtRefreshSecret: string;
  readonly jwtAccessTtl: string;
  readonly jwtRefreshTtlDays: number;
  readonly adminSessionTtlMinutes: number;
  readonly adminCookieName: string;
  readonly isoApiBaseUrl: string;
  readonly isoApiTimeoutMs: number;
  readonly cardEncryptionPrivateKeyPem: string;
  readonly cardVaultKey: Buffer;
  readonly selfRegistrationEnabled: boolean;

  constructor() {
    const { error, value } = schema.validate(process.env, { abortEarly: false });
    if (error) throw new Error(`Invalid environment configuration: ${error.message}`);
    this.nodeEnv = value.NODE_ENV as string;
    this.port = value.PORT as number;
    this.databaseUrl = value.DATABASE_URL as string;
    this.redisUrl = value.REDIS_URL as string;
    this.corsOrigins = (value.CORS_ORIGINS as string).split(',').map((origin) => origin.trim());
    this.jwtAccessSecret = value.JWT_ACCESS_SECRET as string;
    this.jwtRefreshSecret = value.JWT_REFRESH_SECRET as string;
    this.jwtAccessTtl = value.JWT_ACCESS_TTL as string;
    this.jwtRefreshTtlDays = value.JWT_REFRESH_TTL_DAYS as number;
    this.adminSessionTtlMinutes = value.ADMIN_SESSION_TTL_MINUTES as number;
    this.adminCookieName = this.nodeEnv === 'production' ? '__Host-admin_session' : 'admin_session';
    this.isoApiBaseUrl = value.ISO_API_BASE_URL as string;
    this.isoApiTimeoutMs = value.ISO_API_TIMEOUT_MS as number;
    this.cardEncryptionPrivateKeyPem = Buffer.from(value.CARD_ENCRYPTION_PRIVATE_KEY as string, 'base64').toString('utf8');
    this.cardVaultKey = Buffer.from(value.CARD_VAULT_KEY as string, 'base64');
    this.selfRegistrationEnabled = (value.SELF_REGISTRATION_ENABLED as boolean | undefined) ?? this.nodeEnv !== 'production';
    if (this.cardVaultKey.length !== 0 && this.cardVaultKey.length !== 32) throw new Error('CARD_VAULT_KEY must decode to exactly 32 bytes (AES-256).');
    if (this.nodeEnv === 'production' && this.isoApiBaseUrl.startsWith('http://')) throw new Error('ISO_API_BASE_URL must use HTTPS in production.');
  }
}
