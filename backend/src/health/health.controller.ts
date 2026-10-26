import { Controller, Get, ServiceUnavailableException, VERSION_NEUTRAL } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { HealthService } from './health.service';
import { Public } from '../auth/decorators/public.decorator';

@ApiTags('health')
@Public()
@Controller({ path: 'health', version: VERSION_NEUTRAL })
export class HealthController {
  constructor(private readonly health: HealthService) {}

  @Get()
  @ApiOperation({ summary: 'Return detailed dependency health' })
  async overview() { return this.health.check(); }

  @Get('live')
  @ApiOperation({ summary: 'Process liveness probe' })
  live() { return { status: 'ok', service: 'afghanpay-api', timestamp: new Date().toISOString() }; }

  @Get('ready')
  @ApiOperation({ summary: 'Database and cache readiness probe' })
  async ready() {
    const result = await this.health.check();
    if (result.status !== 'ok') throw new ServiceUnavailableException({ code: 'SERVICE_NOT_READY', message: 'Required dependencies are unavailable.' });
    return result;
  }
}
