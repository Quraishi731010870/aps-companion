import { Injectable, OnModuleDestroy } from '@nestjs/common';
import Redis from 'ioredis';
import { RuntimeConfig } from '../configuration/runtime-config.service';

@Injectable()
export class RedisService implements OnModuleDestroy {
  readonly client: Redis;
  constructor(config: RuntimeConfig) {
    this.client = new Redis(config.redisUrl, {
      lazyConnect: true,
      enableOfflineQueue: false,
      maxRetriesPerRequest: 1,
    });
  }
  private connecting?: Promise<void>;
  /** The connected client; concurrent callers share one connect. */
  async ready(): Promise<Redis> {
    if (this.client.status === 'wait') await (this.connecting ??= this.client.connect().finally(() => { this.connecting = undefined; }));
    return this.client;
  }
  async ping(): Promise<string> { return (await this.ready()).ping(); }
  async onModuleDestroy(): Promise<void> { if (this.client.status !== 'end') await this.client.quit(); }
}
