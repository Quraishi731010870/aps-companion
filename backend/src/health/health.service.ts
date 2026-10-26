import { Injectable } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';
import { RedisService } from '../database/redis.service';

@Injectable()
export class HealthService {
  constructor(private readonly prisma: PrismaService, private readonly redis: RedisService) {}

  async check() {
    const started = Date.now();
    const [database, cache] = await Promise.all([this.databaseHealth(), this.redisHealth()]);
    const healthy = database.status === 'ok' && cache.status === 'ok';
    return {
      status: healthy ? 'ok' : 'degraded',
      service: 'afghanpay-api',
      timestamp: new Date().toISOString(),
      durationMs: Date.now() - started,
      dependencies: { database, redis: cache },
    };
  }

  private async databaseHealth() {
    const start = Date.now();
    try { await this.prisma.$queryRaw`SELECT 1`; return { status: 'ok', latencyMs: Date.now() - start }; }
    catch { return { status: 'unavailable', latencyMs: Date.now() - start }; }
  }

  private async redisHealth() {
    const start = Date.now();
    try { await this.redis.ping(); return { status: 'ok', latencyMs: Date.now() - start }; }
    catch { return { status: 'unavailable', latencyMs: Date.now() - start }; }
  }
}
