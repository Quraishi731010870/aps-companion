import { Global, Module } from '@nestjs/common';
import { RuntimeConfig } from './runtime-config.service';

@Global()
@Module({ providers: [RuntimeConfig], exports: [RuntimeConfig] })
export class ConfigurationModule {}
