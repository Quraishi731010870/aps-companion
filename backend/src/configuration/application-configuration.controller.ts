import { Body, Controller, Get, NotFoundException, Param, Put, Query, Req, Res } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { ConfigurationScope, Prisma } from '@prisma/client';
import type { Response } from 'express';
import { AuditService } from '../audit/audit.service';
import { Permissions } from '../auth/decorators/permissions.decorator';
import { Public } from '../auth/decorators/public.decorator';
import type { AuthenticatedRequest } from '../auth/auth.types';
import { PrismaService } from '../database/prisma.service';
import { RealtimeGateway } from '../realtime/realtime.gateway';
import { UpdateConfigurationDto, UpdateFeatureDto } from './dto/update-configuration.dto';
import { IsBoolean, IsObject, IsOptional, IsString, MaxLength } from 'class-validator';

class UpdateContentDto {
  @IsString() @MaxLength(200) title!: string;
  @IsString() @MaxLength(10000) body!: string;
  @IsOptional() @IsBoolean() enabled?: boolean;
  @IsOptional() @IsObject() metadata?: Record<string, unknown>;
}

@ApiTags('configuration') @Controller({ path: 'configuration', version: '1' })
export class ApplicationConfigurationController {
  constructor(private readonly prisma: PrismaService, private readonly audit: AuditService, private readonly realtime: RealtimeGateway) {}
  @Get() @Permissions('configuration.view') list() { return this.prisma.systemConfiguration.findMany({ orderBy: { key: 'asc' } }); }
  @Put(':key') @Permissions('configuration.update') async update(@Param('key') key: string, @Body() dto: UpdateConfigurationDto, @Req() request: AuthenticatedRequest) {
    const existing = await this.prisma.systemConfiguration.findUnique({ where: { key } });
    const updated = await this.prisma.$transaction(async (database) => {
      const config = await database.systemConfiguration.upsert({ where: { key }, update: { value: dto.value as Prisma.InputJsonValue, description: dto.description, version: { increment: 1 }, updatedBy: request.principal.sub }, create: { key, value: dto.value as Prisma.InputJsonValue, description: dto.description ?? '', scope: ConfigurationScope.PUBLIC_MOBILE, updatedBy: request.principal.sub } });
      await database.auditLog.create({ data: { actorId: request.principal.sub, actorSnapshot: request.principal.sub, action: 'CONFIGURATION_UPDATE', resource: 'system_configuration', resourceId: config.id, oldValue: existing?.value as Prisma.InputJsonValue | undefined, newValue: config.value as Prisma.InputJsonValue, requestId: request.requestId ?? 'unknown', result: 'SUCCESS' } });
      return config;
    });
    this.realtime.configurationUpdated({ key, version: updated.version, updatedAt: updated.updatedAt });
    return updated;
  }
  @Public() @Get('mobile/current') async mobile(@Res({ passthrough: true }) response: Response) {
    const [configuration, features, content] = await Promise.all([this.prisma.systemConfiguration.findMany({ where: { scope: ConfigurationScope.PUBLIC_MOBILE }, orderBy: { key: 'asc' } }), this.prisma.featureFlag.findMany({ orderBy: { key: 'asc' } }), this.prisma.dynamicContent.findMany({ where: { enabled: true }, orderBy: { key: 'asc' } })]);
    const version = Math.max(0, ...configuration.map((item) => item.version), ...features.map((item) => item.version), ...content.map((item) => item.version));
    const updatedAt = [...configuration, ...features, ...content].reduce<Date | null>((latest, item) => !latest || item.updatedAt > latest ? item.updatedAt : latest, null);
    const etag = `W/"mobile-config-${version}"`;
    response.setHeader('ETag', etag);
    response.setHeader('Cache-Control', 'private, max-age=60');
    return { version, updatedAt, configuration: Object.fromEntries(configuration.map((item) => [item.key, item.value])), features: features.map(({ key, name, enabled, platform, minimumVersion, configuration: value }) => ({ key, name, enabled, platform, minimumVersion, configuration: value })), content: content.map(({ key, locale, platform, title, body, metadata, version: itemVersion }) => ({ key, locale, platform, title, body, metadata, version: itemVersion })) };
  }
}

@ApiTags('feature flags') @Controller({ path: 'features', version: '1' })
export class FeatureFlagsController {
  constructor(private readonly prisma: PrismaService, private readonly audit: AuditService, private readonly realtime: RealtimeGateway) {}
  @Get() @Permissions('configuration.view') list() { return this.prisma.featureFlag.findMany({ orderBy: { key: 'asc' } }); }
  @Put(':key') @Permissions('configuration.update') async update(@Param('key') key: string, @Body() dto: UpdateFeatureDto, @Req() request: AuthenticatedRequest) {
    const current = await this.prisma.featureFlag.findUnique({ where: { key } });
    if (!current) throw new NotFoundException({ code: 'FEATURE_NOT_FOUND', message: 'Feature flag not found.' });
    const updated = await this.prisma.$transaction(async (database) => {
      const feature = await database.featureFlag.update({ where: { key }, data: { enabled: dto.enabled, configuration: dto.configuration as Prisma.InputJsonValue | undefined, minimumVersion: dto.minimumVersion, version: { increment: 1 } } });
      await database.auditLog.create({ data: { actorId: request.principal.sub, actorSnapshot: request.principal.sub, action: 'FEATURE_FLAG_UPDATE', resource: 'feature_flag', resourceId: feature.id, oldValue: current as unknown as Prisma.InputJsonValue, newValue: feature as unknown as Prisma.InputJsonValue, requestId: request.requestId ?? 'unknown', result: 'SUCCESS' } });
      return feature;
    });
    this.realtime.featureFlagChanged({ key, version: updated.version, updatedAt: updated.updatedAt });
    return updated;
  }
}

@ApiTags('dynamic content') @Controller({ path: 'content', version: '1' })
export class DynamicContentController {
  constructor(private readonly prisma: PrismaService, private readonly realtime: RealtimeGateway) {}
  @Get() @Permissions('configuration.view') list() { return this.prisma.dynamicContent.findMany({ orderBy: [{ key: 'asc' }, { locale: 'asc' }] }); }
  @Public() @Get('mobile') mobile(@Query('locale') locale = 'en') { return this.prisma.dynamicContent.findMany({ where: { enabled: true, locale: { in: [locale, 'en'] } }, orderBy: { key: 'asc' } }); }
  @Put(':key') @Permissions('configuration.update') async update(@Param('key') key: string, @Query('locale') locale: string = 'en', @Body() dto: UpdateContentDto, @Req() request: AuthenticatedRequest) {
    const existing = await this.prisma.dynamicContent.findUnique({ where: { key_locale_platform: { key, locale, platform: 'ALL' } } });
    const updated = await this.prisma.$transaction(async database => {
      const content = await database.dynamicContent.upsert({ where: { key_locale_platform: { key, locale, platform: 'ALL' } }, update: { title: dto.title, body: dto.body, enabled: dto.enabled, metadata: dto.metadata as Prisma.InputJsonValue | undefined, version: { increment: 1 }, updatedBy: request.principal.sub }, create: { key, locale, title: dto.title, body: dto.body, enabled: dto.enabled ?? true, metadata: dto.metadata as Prisma.InputJsonValue | undefined, updatedBy: request.principal.sub } });
      await database.auditLog.create({ data: { actorId: request.principal.sub, actorSnapshot: request.principal.sub, action: 'DYNAMIC_CONTENT_UPDATE', resource: 'dynamic_content', resourceId: content.id, oldValue: existing as unknown as Prisma.InputJsonValue | undefined, newValue: content as unknown as Prisma.InputJsonValue, requestId: request.requestId ?? 'unknown', result: 'SUCCESS' } });
      return content;
    });
    this.realtime.contentUpdated({ key, version: updated.version, updatedAt: updated.updatedAt });
    return updated;
  }
}
