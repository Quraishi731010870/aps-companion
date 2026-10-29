import { Body, ConflictException, Controller, NotFoundException, Param, ParseUUIDPipe, Patch, Req } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { AccountStatus, Prisma, SessionStatus } from '@prisma/client';
import { IsIn, IsString, MaxLength, MinLength } from 'class-validator';
import { Permissions } from '../auth/decorators/permissions.decorator';
import type { AuthenticatedRequest } from '../auth/auth.types';
import { PrismaService } from '../database/prisma.service';
import { RealtimeGateway } from '../realtime/realtime.gateway';
import { nextStatus, STATUS_ACTIONS, StatusTransitionError, type StatusAction } from './status-control';

export class StatusActionDto {
  @IsIn(STATUS_ACTIONS) action!: StatusAction;
  /** Why the operator acted; kept in the audit log. */
  @IsString() @MinLength(3) @MaxLength(500) reason!: string;
}

export interface StatusChange { id: string; status: string }

type Db = Prisma.TransactionClient;

/**
 * Operator controls over a customer and the banking data they hold: the
 * customer itself, wallet accounts, saved cards and bound devices. Every change
 * follows status-control.ts, is audited with the operator's reason, and takes
 * effect at once (sessions are revoked when access is withdrawn).
 */
@ApiTags('customers') @Controller({ path: 'customers', version: '1' }) @Permissions('customers.manage')
export class CustomerControlsController {
  constructor(private readonly prisma: PrismaService, private readonly realtime: RealtimeGateway) {}

  @Patch(':id/status') async customer(@Param('id', ParseUUIDPipe) id: string, @Body() dto: StatusActionDto, @Req() request: AuthenticatedRequest): Promise<StatusChange> {
    const result = await this.prisma.$transaction(async (db) => {
      const customer = await db.customer.findUnique({ where: { id }, select: { status: true, userId: true } });
      if (!customer) throw notFound('CUSTOMER_NOT_FOUND', 'Customer not found.');
      const status = transition(customer.status, dto.action);
      const now = new Date();
      await db.customer.update({ where: { id }, data: { status } });
      // The user row is what sign-in and every authenticated request check.
      await db.user.update({
        where: { id: customer.userId },
        data: status === AccountStatus.ACTIVE
          ? { status, failedLoginCount: 0, lockedUntil: null, disabledAt: null, activatedAt: now }
          : { status, disabledAt: now },
      });
      if (status !== AccountStatus.ACTIVE) await revokeSessions(db, { userId: customer.userId });
      await audit(db, request, dto, 'CUSTOMER_STATUS_UPDATE', 'customer', id, customer.status, status);
      return { status, userId: customer.userId };
    });
    this.realtime.userStatusChanged({ userId: result.userId, status: result.status });
    return { id, status: result.status.toLowerCase() };
  }

  @Patch(':id/accounts/:accountId/status') account(@Param('id', ParseUUIDPipe) id: string, @Param('accountId', ParseUUIDPipe) accountId: string, @Body() dto: StatusActionDto, @Req() request: AuthenticatedRequest): Promise<StatusChange> {
    return this.prisma.$transaction(async (db) => {
      const account = await db.account.findFirst({ where: { id: accountId, customerId: id }, select: { status: true } });
      if (!account) throw notFound('ACCOUNT_NOT_FOUND', 'Account not found.');
      const status = transition(account.status, dto.action);
      await db.account.update({ where: { id: accountId }, data: { status } });
      await audit(db, request, dto, 'ACCOUNT_STATUS_UPDATE', 'account', accountId, account.status, status);
      return { id: accountId, status: status.toLowerCase() };
    });
  }

  @Patch(':id/cards/:cardId/status') card(@Param('id', ParseUUIDPipe) id: string, @Param('cardId', ParseUUIDPipe) cardId: string, @Body() dto: StatusActionDto, @Req() request: AuthenticatedRequest): Promise<StatusChange> {
    return this.prisma.$transaction(async (db) => {
      // A card the customer removed is gone for good; it is not reactivated here.
      const card = await db.savedCard.findFirst({ where: { id: cardId, customerId: id, revokedAt: null }, select: { status: true } });
      if (!card) throw notFound('CARD_NOT_FOUND', 'Card not found.');
      const status = transition(card.status, dto.action);
      await db.savedCard.update({ where: { id: cardId }, data: { status } });
      await audit(db, request, dto, 'CARD_STATUS_UPDATE', 'saved_card', cardId, card.status, status);
      return { id: cardId, status: status.toLowerCase() };
    });
  }

  @Patch(':id/devices/:deviceId/status') device(@Param('id', ParseUUIDPipe) id: string, @Param('deviceId', ParseUUIDPipe) deviceId: string, @Body() dto: StatusActionDto, @Req() request: AuthenticatedRequest): Promise<StatusChange> {
    return this.prisma.$transaction(async (db) => {
      const device = await db.device.findFirst({ where: { id: deviceId, user: { customer: { id } } }, select: { status: true } });
      if (!device) throw notFound('DEVICE_NOT_FOUND', 'Device not found.');
      const status = transition(device.status, dto.action);
      await db.device.update({ where: { id: deviceId }, data: { status } });
      if (status !== AccountStatus.ACTIVE) await revokeSessions(db, { deviceId });
      await audit(db, request, dto, 'DEVICE_STATUS_UPDATE', 'device', deviceId, device.status, status);
      return { id: deviceId, status: status.toLowerCase() };
    });
  }
}

function transition(current: AccountStatus, action: StatusAction): AccountStatus {
  try {
    return nextStatus(current, action);
  } catch (error) {
    if (error instanceof StatusTransitionError) throw new ConflictException({ code: 'STATUS_TRANSITION_INVALID', message: error.message });
    throw error;
  }
}

function notFound(code: string, message: string): NotFoundException {
  return new NotFoundException({ code, message });
}

function revokeSessions(db: Db, where: { userId: string } | { deviceId: string }) {
  return db.session.updateMany({ where: { ...where, status: SessionStatus.ACTIVE }, data: { status: SessionStatus.REVOKED, revokedAt: new Date(), refreshTokenHash: null } });
}

function audit(db: Db, request: AuthenticatedRequest, dto: StatusActionDto, action: string, resource: string, resourceId: string, from: AccountStatus, to: AccountStatus) {
  return db.auditLog.create({ data: { actorId: request.principal.sub, actorSnapshot: request.principal.sub, action, resource, resourceId, oldValue: { status: from }, newValue: { status: to, action: dto.action, reason: dto.reason.trim() }, requestId: request.requestId ?? 'unknown', result: 'SUCCESS' } });
}
