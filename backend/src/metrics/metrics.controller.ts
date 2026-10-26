import { Controller, Get, Header, VERSION_NEUTRAL } from '@nestjs/common';
import { Public } from '../auth/decorators/public.decorator';
import { MetricsService } from './metrics.service';

@Controller({ version: VERSION_NEUTRAL }) @Public()
export class MetricsController {
  constructor(private readonly metrics: MetricsService) {}
  @Get('/metrics') @Header('Content-Type', 'text/plain; version=0.0.4; charset=utf-8') get() { return this.metrics.render(); }
}
