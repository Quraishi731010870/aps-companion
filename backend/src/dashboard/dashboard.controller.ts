import { Controller, Get } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Permissions } from '../auth/decorators/permissions.decorator';
import { DashboardService } from './dashboard.service';

@ApiTags('dashboard') @Controller({ path: 'dashboard', version: '1' }) @Permissions('dashboard.view')
export class DashboardController {
  constructor(private readonly dashboard: DashboardService) {}
  @Get('summary') summary() { return this.dashboard.summary(); }
  @Get('transaction-stats') stats() { return this.dashboard.stats(); }
  @Get('activity') async activity() { return (await this.dashboard.summary()).recentActivity; }
}
