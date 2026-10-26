import { Module } from '@nestjs/common';
import { AuditService } from './audit/audit.service';
import { ApplicationConfigurationController, DynamicContentController, FeatureFlagsController } from './configuration/application-configuration.controller';
import { DashboardController } from './dashboard/dashboard.controller';
import { DashboardService } from './dashboard/dashboard.service';
import { MetricsController } from './metrics/metrics.controller';
import { MetricsService } from './metrics/metrics.service';
import { RealtimeGateway } from './realtime/realtime.gateway';
import { TransactionsController } from './transactions/transactions.controller';
import { AuditController, CustomersController, MonitoringController, NotificationsController, ReportsController, UsersController } from './operations/operations.controllers';
import { APP_INTERCEPTOR } from '@nestjs/core';
import { MetricsInterceptor } from './metrics/metrics.interceptor';
import { HealthModule } from './health/health.module';
import { Iso8583Controller } from './iso8583/iso8583.controller';
import { Iso8583Service } from './iso8583/iso8583.service';
import { IsoCpGatewayController, IsoGatewayController, IsoReversalGatewayController } from './iso8583/iso-gateway.controller';
import { IsoGatewayService } from './iso8583/iso-gateway.service';

@Module({ imports: [HealthModule], controllers: [DashboardController, TransactionsController, Iso8583Controller, IsoGatewayController, IsoCpGatewayController, IsoReversalGatewayController, ApplicationConfigurationController, FeatureFlagsController, DynamicContentController, MetricsController, UsersController, CustomersController, NotificationsController, AuditController, MonitoringController, ReportsController], providers: [DashboardService, AuditService, RealtimeGateway, MetricsService, Iso8583Service, IsoGatewayService, { provide: APP_INTERCEPTOR, useClass: MetricsInterceptor }], exports: [AuditService, RealtimeGateway, MetricsService] })
export class CoreApiModule {}
