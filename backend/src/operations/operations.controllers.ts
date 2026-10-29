import { Body, Controller, Get, NotFoundException, Param, ParseUUIDPipe, Patch, Post, Put, Query, Req } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { AccountStatus, NotificationStatus, Prisma } from '@prisma/client';
import argon2 from 'argon2';
import { Transform, Type } from 'class-transformer';
import { IsDateString, IsEmail, IsEnum, IsIn, IsInt, IsObject, IsOptional, IsString, Max, MaxLength, Min, MinLength } from 'class-validator';
import { Permissions } from '../auth/decorators/permissions.decorator';
import type { AuthenticatedRequest } from '../auth/auth.types';
import { availableActions } from '../customers/status-control';
import { PrismaService } from '../database/prisma.service';
import { HealthService } from '../health/health.service';
import { RealtimeGateway } from '../realtime/realtime.gateway';

class PageQuery { @IsOptional() @Type(() => Number) @IsInt() @Min(0) page = 0; @IsOptional() @Type(() => Number) @IsInt() @Min(1) @Max(100) pageSize = 25; @IsOptional() @IsString() @MaxLength(200) search?: string; }
class CreateUserDto { @IsEmail() email!: string; @IsString() @MinLength(2) @MaxLength(160) displayName!: string; @IsString() @MinLength(12) @MaxLength(200) developmentPassword!: string; @IsString() roleCode!: string; }
class UpdateUserDto { @IsOptional() @IsString() @MinLength(2) @MaxLength(160) displayName?: string; @IsOptional() @IsEmail() email?: string; }
class CustomerQuery extends PageQuery { @IsOptional() @Transform(({ value }) => typeof value === 'string' ? value.toUpperCase() : value) @IsEnum(AccountStatus) status?: AccountStatus; @IsOptional() @IsIn(['createdAt:desc', 'createdAt:asc', 'name:asc', 'name:desc']) sort = 'createdAt:desc'; @IsOptional() @IsDateString() dateFrom?: string; @IsOptional() @IsDateString() dateTo?: string; @IsOptional() @IsDateString() lastActivityFrom?: string; @IsOptional() @IsDateString() lastActivityTo?: string; }
class StatusDto { @IsEnum(AccountStatus) status!: AccountStatus; }
class NotificationDto { @IsString() @MaxLength(200) title!: string; @IsString() @MaxLength(4000) body!: string; @IsOptional() @IsObject() data?: Record<string, unknown>; }

@ApiTags('users') @Controller({ path: 'users', version: '1' })
export class UsersController {
  constructor(private readonly prisma: PrismaService, private readonly realtime: RealtimeGateway) {}
  @Get() @Permissions('users.view') async list(@Query() query: PageQuery) {
    const where = query.search ? { OR: [{ displayName: { contains: query.search, mode: 'insensitive' as const } }, { email: { contains: query.search, mode: 'insensitive' as const } }, { phone: { contains: query.search } }] } : {};
    const [items, total] = await this.prisma.$transaction([this.prisma.user.findMany({ where, skip: query.page * query.pageSize, take: query.pageSize, orderBy: { createdAt: 'desc' }, select: { id: true, email: true, phone: true, displayName: true, principalType: true, status: true, createdAt: true, updatedAt: true, roles: { select: { role: { select: { code: true, name: true } } } } } }), this.prisma.user.count({ where })]);
    return { items, total, page: query.page, pageSize: query.pageSize };
  }
  @Get(':id') @Permissions('users.view') async detail(@Param('id') id: string) { const user = await this.prisma.user.findUnique({ where: { id }, select: { id: true, email: true, phone: true, displayName: true, principalType: true, status: true, createdAt: true, updatedAt: true, roles: { include: { role: true } }, devices: true, sessions: { select: { id: true, status: true, expiresAt: true, lastSeenAt: true, createdAt: true } } } }); if (!user) throw new NotFoundException({ code: 'USER_NOT_FOUND', message: 'User not found.' }); return user; }
  @Post() @Permissions('users.create') async create(@Body() dto: CreateUserDto, @Req() request: AuthenticatedRequest) {
    const role = await this.prisma.role.findUnique({ where: { code: dto.roleCode } }); if (!role) throw new NotFoundException({ code: 'ROLE_NOT_FOUND', message: 'Role not found.' });
    return this.prisma.$transaction(async (db) => { const user = await db.user.create({ data: { email: dto.email.toLowerCase(), displayName: dto.displayName, passwordHash: await argon2.hash(dto.developmentPassword, { type: argon2.argon2id }), principalType: 'ADMIN', status: AccountStatus.ACTIVE, roles: { create: { roleId: role.id, grantedBy: request.principal.sub } } } }); await db.auditLog.create({ data: { actorId: request.principal.sub, actorSnapshot: request.principal.sub, action: 'USER_CREATE', resource: 'user', resourceId: user.id, newValue: { email: user.email, displayName: user.displayName, role: role.code }, requestId: request.requestId ?? 'unknown', result: 'SUCCESS' } }); return { id: user.id, email: user.email, displayName: user.displayName, status: user.status }; });
  }
  @Put(':id') @Permissions('users.update') async update(@Param('id') id: string, @Body() dto: UpdateUserDto, @Req() request: AuthenticatedRequest) { return this.prisma.$transaction(async (db) => { const old = await db.user.findUniqueOrThrow({ where: { id } }); const user = await db.user.update({ where: { id }, data: dto }); await db.auditLog.create({ data: { actorId: request.principal.sub, actorSnapshot: request.principal.sub, action: 'USER_UPDATE', resource: 'user', resourceId: id, oldValue: { email: old.email, displayName: old.displayName }, newValue: { email: user.email, displayName: user.displayName }, requestId: request.requestId ?? 'unknown', result: 'SUCCESS' } }); return user; }); }
  @Patch(':id/status') @Permissions('users.disable') async status(@Param('id') id: string, @Body() dto: StatusDto, @Req() request: AuthenticatedRequest) { const user = await this.prisma.$transaction(async (db) => { const old = await db.user.findUniqueOrThrow({ where: { id } }); const updated = await db.user.update({ where: { id }, data: { status: dto.status, disabledAt: dto.status === AccountStatus.DISABLED ? new Date() : null } }); if (dto.status !== AccountStatus.ACTIVE) await db.session.updateMany({ where: { userId: id, status: 'ACTIVE' }, data: { status: 'REVOKED', revokedAt: new Date(), refreshTokenHash: null } }); await db.auditLog.create({ data: { actorId: request.principal.sub, actorSnapshot: request.principal.sub, action: 'USER_STATUS_UPDATE', resource: 'user', resourceId: id, oldValue: { status: old.status }, newValue: { status: updated.status }, requestId: request.requestId ?? 'unknown', result: 'SUCCESS' } }); return updated; }); this.realtime.userStatusChanged({ userId: id, status: user.status }); return user; }
}

@ApiTags('customers') @Controller({ path: 'customers', version: '1' }) @Permissions('customers.view')
export class CustomersController {
  constructor(private readonly prisma: PrismaService) {}
  @Get() async list(@Query() query: CustomerQuery) {
    const where: Prisma.CustomerWhereInput = { status: query.status, createdAt: range(query.dateFrom, query.dateTo), updatedAt: range(query.lastActivityFrom, query.lastActivityTo), OR: query.search ? [{ customerNo: { contains: query.search, mode: 'insensitive' } }, { user: { displayName: { contains: query.search, mode: 'insensitive' } } }, { user: { phone: { contains: query.search } } }] : undefined };
    const [field, direction] = query.sort.split(':'); const order = direction === 'asc' ? 'asc' : 'desc';
    const orderBy: Prisma.CustomerOrderByWithRelationInput = field === 'name' ? { user: { displayName: order } } : { createdAt: order };
    const [rows, total] = await this.prisma.$transaction([this.prisma.customer.findMany({ where, skip: query.page * query.pageSize, take: query.pageSize, orderBy, include: { user: true } }), this.prisma.customer.count({ where })]);
    return { items: rows.map((row) => ({ id: row.id, customerNo: row.customerNo, name: row.user.displayName, phoneMasked: maskPhone(row.user.phone), status: row.status.toLowerCase(), createdAt: row.createdAt, lastActivityAt: row.updatedAt })), total, page: query.page, pageSize: query.pageSize };
  }
  /** Masked data only: no PAN, device keys or push tokens leave this endpoint. `actions` are what customers.manage may apply. */
  @Get(':id') async detail(@Param('id', ParseUUIDPipe) id: string) {
    const row = await this.prisma.customer.findUnique({ where: { id }, include: { user: { include: { devices: { orderBy: { createdAt: 'desc' } } } }, accounts: { orderBy: { createdAt: 'asc' } }, savedCards: { where: { revokedAt: null }, orderBy: { createdAt: 'desc' } }, transactions: { take: 20, orderBy: { createdAt: 'desc' }, include: { transactionType: true } } } });
    if (!row) throw new NotFoundException({ code: 'CUSTOMER_NOT_FOUND', message: 'Customer not found.' });
    const control = (status: AccountStatus) => ({ status: status.toLowerCase(), actions: availableActions(status) });
    return { id: row.id, customerNo: row.customerNo, name: row.user.displayName, phoneMasked: maskPhone(row.user.phone), emailMasked: row.user.email?.replace(/^(.{2}).*(@.*)$/, '$1***$2'), kycStatus: row.kycStatus.toLowerCase(), ...control(row.status), createdAt: row.createdAt, lastActivityAt: row.updatedAt,
      accounts: row.accounts.map((account) => ({ id: account.id, type: account.type, maskedNumber: account.accountNo.replace(/.(?=.{4})/g, '*'), currency: account.currency, availableBalance: Number(account.availableBalance), ...control(account.status) })),
      cards: row.savedCards.map((card) => ({ id: card.id, maskedPan: card.maskedPan, createdAt: card.createdAt, ...control(card.status) })),
      devices: row.user.devices.map((device) => ({ id: device.id, platform: device.platform, name: device.name, boundAt: device.boundAt, lastSeenAt: device.lastSeenAt, ...control(device.status) })),
      activity: row.transactions.map((transaction) => ({ id: transaction.transactionId, event: `${transaction.transactionType.name}: ${transaction.status}`, at: transaction.createdAt })) };
  }
}

@ApiTags('notifications') @Controller({ path: 'notifications', version: '1' })
export class NotificationsController {
  constructor(private readonly prisma: PrismaService, private readonly realtime: RealtimeGateway) {}
  @Get() @Permissions('notifications.view') async list(@Query() query: PageQuery) { const [items, total] = await this.prisma.$transaction([this.prisma.notification.findMany({ skip: query.page * query.pageSize, take: query.pageSize, orderBy: { createdAt: 'desc' } }), this.prisma.notification.count()]); return { items, total, page: query.page, pageSize: query.pageSize }; }
  @Post() @Permissions('notifications.create') async create(@Body() dto: NotificationDto, @Req() request: AuthenticatedRequest) { const item = await this.prisma.$transaction(async (db) => { const created = await db.notification.create({ data: { ...dto, data: dto.data as Prisma.InputJsonValue | undefined, status: NotificationStatus.QUEUED, createdBy: request.principal.sub } }); await db.auditLog.create({ data: { actorId: request.principal.sub, actorSnapshot: request.principal.sub, action: 'NOTIFICATION_CREATE', resource: 'notification', resourceId: created.id, newValue: { title: created.title, status: created.status }, requestId: request.requestId ?? 'unknown', result: 'SUCCESS' } }); return created; }); this.realtime.notificationCreated({ id: item.id, createdAt: item.createdAt }); return item; }
  @Patch(':id') @Permissions('notifications.create') async update(@Param('id') id: string, @Body() dto: NotificationDto) { return this.prisma.notification.update({ where: { id }, data: { ...dto, data: dto.data as Prisma.InputJsonValue | undefined } }); }
}

@ApiTags('audit') @Controller({ path: 'audit-logs', version: '1' }) @Permissions('audit.view')
export class AuditController { constructor(private readonly prisma: PrismaService) {} @Get() async list(@Query() query: PageQuery) { const [items, total] = await this.prisma.$transaction([this.prisma.auditLog.findMany({ skip: query.page * query.pageSize, take: query.pageSize, orderBy: { createdAt: 'desc' } }), this.prisma.auditLog.count()]); return { items, total, page: query.page, pageSize: query.pageSize }; } }

@ApiTags('monitoring') @Controller({ path: 'monitoring', version: '1' }) @Permissions('monitoring.view')
export class MonitoringController {
  constructor(private readonly prisma: PrismaService, private readonly health: HealthService) {}
  @Get('health') async healthCheck() { const health = await this.health.check(); const status = (value: string) => value === 'ok' ? 'healthy' : 'critical'; return { services: [{ name: 'Backend API', status: 'healthy', checkedAt: health.timestamp }, { name: 'PostgreSQL', status: status(health.dependencies.database.status), checkedAt: health.timestamp }, { name: 'Redis', status: status(health.dependencies.redis.status), checkedAt: health.timestamp }], integrations: { zabbix: 'unavailable', grafana: process.env.GRAFANA_BASE_URL ? 'healthy' : 'unavailable' }, infrastructure: [], alerts: { critical: await this.prisma.alert.count({ where: { status: 'OPEN', severity: 'CRITICAL' } }), high: await this.prisma.alert.count({ where: { status: 'OPEN', severity: 'HIGH' } }), warning: await this.prisma.alert.count({ where: { status: 'OPEN', severity: 'WARNING' } }), info: await this.prisma.alert.count({ where: { status: 'OPEN', severity: 'INFO' } }) } }; }
  @Get('transactions') async transactionMonitoring() { const rows = await this.prisma.transaction.groupBy({ by: ['status'], _count: true, _avg: { processingTimeMs: true } }); const count = (name: string) => rows.find((row) => row.status === name)?._count ?? 0; const volume = rows.reduce((sum, row) => sum + row._count, 0); const successful = count('SUCCESS'); const failed = count('FAILED'); return { volume, successRate: volume ? successful * 100 / volume : 0, failureRate: volume ? failed * 100 / volume : 0, declineRate: volume ? failed * 100 / volume : 0, pending: count('PENDING') + count('PROCESSING'), reversals: count('REVERSED'), latencyMs: rows.reduce((sum, row) => sum + Number(row._avg.processingTimeMs ?? 0), 0) / Math.max(rows.length, 1), trend: [], byType: [], byResponseCode: [], latencyTrend: [] }; }
  @Get('services') services() { return this.prisma.monitoringService.findMany({ include: { checks: { take: 1, orderBy: { checkedAt: 'desc' } } } }); }
  @Get('alerts') async alerts(@Query() query: PageQuery) { const [rows, total] = await this.prisma.$transaction([this.prisma.alert.findMany({ skip: query.page * query.pageSize, take: query.pageSize, orderBy: { createdAt: 'desc' }, include: { service: true } }), this.prisma.alert.count()]); return { items: rows.map((row) => ({ id: row.id, source: row.service?.name ?? 'AfghanPay', service: row.service?.name, description: row.title, severity: row.severity.toLowerCase(), status: row.status.toLowerCase(), createdAt: row.createdAt, updatedAt: row.updatedAt })), total, page: query.page, pageSize: query.pageSize }; }
}

@ApiTags('reports') @Controller({ path: 'reports', version: '1' }) @Permissions('reports.view')
export class ReportsController { constructor(private readonly prisma: PrismaService) {} @Get('transactions') transactions() { return this.prisma.transaction.groupBy({ by: ['status', 'currency'], _count: true, _sum: { amount: true } }); } @Get('users') async users() { return { total: await this.prisma.user.count(), byStatus: await this.prisma.user.groupBy({ by: ['status'], _count: true }) }; } }

function maskPhone(phone: string | null): string | undefined { return phone?.replace(/.(?=.{4})/g, '*'); }
/** Whole days: `to` includes the end of that day. */
function range(from?: string, to?: string): Prisma.DateTimeFilter | undefined { return from || to ? { gte: from ? new Date(from) : undefined, lt: to ? new Date(new Date(to).getTime() + 86_400_000) : undefined } : undefined; }
