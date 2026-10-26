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
    if (this.nodeEnv === 'production' && this.isoApiBaseUrl.startsWith('http://')) throw new Error('ISO_API_BASE_URL must use HTTPS in production.');
  }
}
