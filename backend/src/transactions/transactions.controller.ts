import { BadRequestException, Body, Controller, ForbiddenException, Get, NotFoundException, Param, Post, Query, Req } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Prisma, TransactionStatus } from '@prisma/client';
import { Transform, Type } from 'class-transformer';
import { IsDateString, IsEnum, IsInt, IsNotEmpty, IsNumber, IsOptional, IsString, Max, MaxLength, Min, ValidateNested } from 'class-validator';
import { Permissions } from '../auth/decorators/permissions.decorator';
import type { AuthenticatedRequest } from '../auth/auth.types';
import { CardCryptoService } from '../cards/card-crypto.service';
import { looksLikePan, maskPan } from '../cards/card-envelope';
import { CardEnvelopeDto } from '../cards/card-envelope.dto';
import { PrismaService } from '../database/prisma.service';

class TransactionQuery {
  @IsOptional() @Type(() => Number) @IsInt() @Min(0) page = 0;
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) @Max(100) pageSize = 25;
  @IsOptional() @IsString() search?: string;
  @IsOptional() @Transform(({ value }) => typeof value === 'string' ? value.toUpperCase() : value) @IsEnum(TransactionStatus) status?: TransactionStatus;
  @IsOptional() @IsString() operation?: string;
  @IsOptional() @IsString() currency?: string;
  @IsOptional() @IsString() responseCode?: string;
  @IsOptional() @IsDateString() dateFrom?: string;
  @IsOptional() @IsDateString() dateTo?: string;
  @IsOptional() @IsString() transactionId?: string;
  @IsOptional() @IsString() reference?: string;
  @IsOptional() @IsString() customer?: string;
  @IsOptional() @IsString() account?: string;
  @IsOptional() @IsString() phone?: string;
  @IsOptional() @IsString() source?: string;
  @IsOptional() @IsString() destination?: string;
  @IsOptional() @IsString() channel?: string;
  @IsOptional() @Type(() => Number) @IsNumber({ maxDecimalPlaces: 2 }) @Min(0) amountFrom?: number;
  @IsOptional() @Type(() => Number) @IsNumber({ maxDecimalPlaces: 2 }) @Min(0) amountTo?: number;
  @IsOptional() @IsString() sort = 'createdAt:desc';
}
class CreateTransactionDto {
  @Type(() => Number) @IsInt() transactionType!: number;
  @IsString() @IsNotEmpty() @MaxLength(160) source!: string;
  @IsString() @IsNotEmpty() @MaxLength(160) destination!: string;
  @Type(() => Number) @IsNumber({ maxDecimalPlaces: 2 }) @Min(0) amount!: number;
  @IsString() @MaxLength(3) currency!: string;
  @IsString() @MaxLength(160) reference!: string;
  @IsString() @IsNotEmpty() @MaxLength(128) idempotencyKey!: string;
  /** Pay with a vaulted card (source is then its masked PAN). */
  @IsOptional() @IsString() @MaxLength(64) cardToken?: string;
  /** Pay with a one-off card, encrypted by the app (see cards/card-envelope.ts). */
  @IsOptional() @ValidateNested() @Type(() => CardEnvelopeDto) encryptedCard?: CardEnvelopeDto;
}

@ApiTags('transactions') @Controller({ path: 'transactions', version: '1' })
export class TransactionsController {
  constructor(private readonly prisma: PrismaService, private readonly cards: CardCryptoService) {}
  @Post() async create(@Body() dto: CreateTransactionDto, @Req() request: AuthenticatedRequest) {
    const existing = await this.prisma.transaction.findUnique({ where: { idempotencyKey: dto.idempotencyKey }, include: { transactionType: true } });
    if (existing) return { id: existing.transactionId, status: existing.status, createdAt: existing.createdAt, responseCode: existing.responseCode, responseDescription: existing.responseDescription, duplicate: true };
    const transactionType = await this.prisma.transactionType.findUnique({ where: { code: String(dto.transactionType) } });
    if (!transactionType || !transactionType.enabled) throw new NotFoundException({ code: 'TRANSACTION_TYPE_UNAVAILABLE', message: 'This transaction type is not available.' });
    const customer = await this.prisma.customer.findUnique({ where: { userId: request.principal.sub }, include: { accounts: { where: { status: 'ACTIVE' }, take: 1 } } });
    const sourceReference = await this.resolveSource(dto, customer?.id);
    const now = new Date(); const identifier = `AFG-${now.getTime()}-${Math.floor(Math.random() * 1000).toString().padStart(3, '0')}`;
    const transaction = await this.prisma.transaction.create({ data: { transactionTypeId: transactionType.id, customerId: customer?.id, sourceAccountId: customer?.accounts[0]?.id, transactionId: identifier, idempotencyKey: dto.idempotencyKey, amount: dto.amount.toFixed(2), currency: dto.currency.toUpperCase(), direction: transactionType.financial ? 'DEBIT' : 'NON_FINANCIAL', channel: 'MOBILE', sourceReference, destinationReference: dto.destination, deviceId: request.device?.id, deviceSignature: request.device?.signature, status: 'PENDING', events: { create: { toStatus: 'PENDING', eventType: 'CREATED', safeMetadata: { reference: dto.reference } } } } });
    return { id: transaction.transactionId, status: transaction.status, createdAt: transaction.createdAt, responseDescription: 'Transaction accepted for processing.' };
  }
  /**
   * The funding card is never stored in clear: a vault token or an encrypted
   * card resolves to its masked PAN, and a raw card number is refused.
   */
  private async resolveSource(dto: CreateTransactionDto, customerId: string | undefined): Promise<string> {
    if (dto.cardToken && dto.encryptedCard) throw new BadRequestException({ code: 'CARD_SOURCE_AMBIGUOUS', message: 'Send either a saved card or a new card, not both.' });
    if (dto.cardToken) {
      const card = customerId ? await this.prisma.savedCard.findFirst({ where: { token: dto.cardToken, customerId, revokedAt: null }, select: { maskedPan: true } }) : null;
      if (!card) throw new NotFoundException({ code: 'CARD_NOT_FOUND', message: 'Card not found.' });
      return card.maskedPan;
    }
    if (dto.encryptedCard) return maskPan(this.cards.open(dto.encryptedCard).pan);
    if (looksLikePan(dto.source)) throw new BadRequestException({ code: 'CARD_NUMBER_NOT_ENCRYPTED', message: 'Card numbers must be sent encrypted.' });
    return dto.source;
  }

  @Get('stats') @Permissions('transactions.view') async stats() { return this.prisma.transaction.groupBy({ by: ['status'], _count: true, _sum: { amount: true } }); }
  @Get() async list(@Query() query: TransactionQuery, @Req() request: AuthenticatedRequest) {
    if (request.principal.type === 'ADMIN' && !request.principal.permissions.includes('transactions.view')) throw new ForbiddenException({ code: 'PERMISSION_DENIED', message: 'Transaction access is not permitted.' });
    const customerFilter: Prisma.CustomerNullableScalarRelationFilter | undefined = request.principal.type === 'MOBILE_USER' ? { is: { userId: request.principal.sub } } : query.customer || query.phone ? { is: { OR: [{ customerNo: { contains: query.customer ?? '', mode: 'insensitive' } }, { user: { displayName: { contains: query.customer ?? '', mode: 'insensitive' } } }, { user: { phone: { contains: query.phone ?? '' } } }] } } : undefined;
    const where: Prisma.TransactionWhereInput = { customer: customerFilter, status: query.status, currency: query.currency?.toUpperCase(), responseCode: query.responseCode, channel: query.channel ? { contains: query.channel, mode: 'insensitive' } : undefined, transactionId: query.transactionId ? { contains: query.transactionId, mode: 'insensitive' } : undefined, rrn: query.reference ? { contains: query.reference, mode: 'insensitive' } : undefined, sourceReference: query.source ? { contains: query.source, mode: 'insensitive' } : undefined, destinationReference: query.destination ? { contains: query.destination, mode: 'insensitive' } : undefined, amount: query.amountFrom != null || query.amountTo != null ? { gte: query.amountFrom, lte: query.amountTo } : undefined, transactionType: query.operation ? { code: query.operation } : undefined, sourceAccount: query.account ? { accountNo: { contains: query.account, mode: 'insensitive' } } : undefined, createdAt: query.dateFrom || query.dateTo ? { gte: query.dateFrom ? new Date(query.dateFrom) : undefined, lte: query.dateTo ? new Date(query.dateTo) : undefined } : undefined, OR: query.search ? [{ transactionId: { contains: query.search, mode: 'insensitive' } }, { rrn: { contains: query.search, mode: 'insensitive' } }, { sourceReference: { contains: query.search, mode: 'insensitive' } }, { destinationReference: { contains: query.search, mode: 'insensitive' } }] : undefined };
    const [sortField, sortDirection] = query.sort.split(':');
    const orderBy: Prisma.TransactionOrderByWithRelationInput = sortField === 'amount' ? { amount: sortDirection === 'asc' ? 'asc' : 'desc' } : { createdAt: sortDirection === 'asc' ? 'asc' : 'desc' };
    const [items, total] = await this.prisma.$transaction([this.prisma.transaction.findMany({ where, skip: query.page * query.pageSize, take: query.pageSize, orderBy, include: { transactionType: true, customer: { include: { user: true } } } }), this.prisma.transaction.count({ where })]);
    return { items: items.map((item) => ({ id: item.transactionId, rrn: item.rrn, operationCode: Number(item.transactionType.code), operationLabel: item.transactionType.name, customer: item.customer?.user.displayName, amount: Number(item.amount), currency: item.currency, status: item.status.toLowerCase(), source: item.sourceReference, destination: item.destinationReference, channel: item.channel, responseCode: item.responseCode, createdAt: item.createdAt, updatedAt: item.updatedAt })), total, page: query.page, pageSize: query.pageSize };
  }
  @Get(':id') async detail(@Param('id') id: string, @Req() request: AuthenticatedRequest) {
    if (request.principal.type === 'ADMIN' && !request.principal.permissions.includes('transactions.view')) throw new ForbiddenException({ code: 'PERMISSION_DENIED', message: 'Transaction access is not permitted.' });
    const item = await this.prisma.transaction.findFirst({ where: { AND: [{ OR: [{ id }, { transactionId: id }] }, request.principal.type === 'MOBILE_USER' ? { customer: { userId: request.principal.sub } } : {}] }, include: { transactionType: true, customer: { include: { user: true } }, events: { orderBy: { createdAt: 'asc' } } } });
    if (!item) throw new NotFoundException({ code: 'TRANSACTION_NOT_FOUND', message: 'Transaction not found.' });
    return { id: item.transactionId, rrn: item.rrn, operationCode: Number(item.transactionType.code), operationLabel: item.transactionType.name, customer: item.customer?.user.displayName, amount: Number(item.amount), currency: item.currency, status: item.status.toLowerCase(), source: item.sourceReference, destination: item.destinationReference, channel: item.channel, responseCode: item.responseCode, createdAt: item.createdAt, updatedAt: item.updatedAt, timeline: item.events.map((event) => ({ label: event.eventType, at: event.createdAt, detail: `${event.fromStatus ?? 'START'} → ${event.toStatus}` })) };
  }
}
