import { Body, Controller, ForbiddenException, Post, Req } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiProperty, ApiTags } from '@nestjs/swagger';
import { TransactionStatus } from '@prisma/client';
import { IsEnum, IsIn, IsNotEmpty, IsOptional, IsString, Length, Matches, MaxLength } from 'class-validator';
import type { AuthenticatedRequest } from '../auth/auth.types';
import { Permissions } from '../auth/decorators/permissions.decorator';
import { AuditService } from '../audit/audit.service';
import { RuntimeConfig } from '../configuration/runtime-config.service';
import { PrismaService } from '../database/prisma.service';
import { RealtimeGateway } from '../realtime/realtime.gateway';
import { Iso8583Service, type IsoFields } from './iso8583.service';

enum IsoScenario { APPROVED = 'APPROVED', INSUFFICIENT_FUNDS = 'INSUFFICIENT_FUNDS', TIMEOUT = 'TIMEOUT' }

class IsoMessageDto {
  @ApiProperty({ example: '0200', description: 'ISO 8583 request message type.' })
  @IsString() @Matches(/^0[128][012]0$/) mti!: string;
  @ApiProperty({ example: '000000', description: 'DE 3 processing code.' })
  @IsString() @Length(6, 6) @Matches(/^\d{6}$/) processingCode!: string;
  @ApiProperty({ example: '000000001000', description: 'DE 4 amount in minor units (10.00).' })
  @IsString() @Length(12, 12) @Matches(/^\d{12}$/) amountMinor!: string;
  @ApiProperty({ example: '123456', description: 'DE 11 system trace audit number.' })
  @IsString() @Length(6, 6) @Matches(/^\d{6}$/) stan!: string;
  @ApiProperty({ example: 'AFGHAN01', description: 'DE 41 terminal identifier.' })
  @IsString() @Length(8, 8) terminalId!: string;
  @ApiProperty({ example: 'EMIMERCHANT0001', description: 'DE 42 merchant identifier.' })
  @IsString() @Length(15, 15) merchantId!: string;
  @ApiProperty({ example: '971', description: 'DE 49 ISO 4217 numeric currency code (971 = AFN).' })
  @IsString() @Length(3, 3) @Matches(/^\d{3}$/) currencyCode!: string;
  @ApiProperty({ example: '0929123456', required: false, description: 'DE 7 MMDDhhmmss; generated when omitted.' })
  @IsOptional() @IsString() @Length(10, 10) @Matches(/^\d{10}$/) transmissionDateTime?: string;
}

class ValidateIsoMessageDto extends IsoMessageDto {}

class SimulateIsoTransactionDto extends IsoMessageDto {
  @ApiProperty({ enum: IsoScenario, example: IsoScenario.APPROVED })
  @IsEnum(IsoScenario) scenario!: IsoScenario;
  @ApiProperty({ example: '774', description: 'Existing Afghan EMI transaction type code.' })
  @IsString() @IsNotEmpty() @MaxLength(32) transactionType!: string;
  @ApiProperty({ example: 'DEMO-WALLET-001' })
  @IsString() @IsNotEmpty() @MaxLength(160) source!: string;
  @ApiProperty({ example: 'DEMO-MEMBER-01' })
  @IsString() @IsNotEmpty() @MaxLength(160) destination!: string;
  @ApiProperty({ example: 'swagger-iso-8583-000001' })
  @IsString() @IsNotEmpty() @MaxLength(128) idempotencyKey!: string;
  @ApiProperty({ example: 'AFN', enum: ['AFN', 'USD'] })
  @IsString() @IsIn(['AFN', 'USD']) currency!: string;
}

@ApiTags('iso-8583')
@ApiBearerAuth()
@Controller({ path: 'iso8583', version: '1' })
export class Iso8583Controller {
  constructor(
    private readonly iso: Iso8583Service,
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly realtime: RealtimeGateway,
    private readonly config: RuntimeConfig,
  ) {}

  @Post('validate')
  @Permissions('transactions.view')
  @ApiOperation({ summary: 'Validate and preview a safe ISO 8583 message and primary bitmap' })
  validate(@Body() dto: ValidateIsoMessageDto) {
    return this.iso.validate(dto.mti, this.requestFields(dto));
  }

  @Post('simulate')
  @Permissions('transactions.view')
  @ApiOperation({ summary: 'Run a development/UAT ISO 8583 transaction scenario and persist its timeline' })
  async simulate(@Body() dto: SimulateIsoTransactionDto, @Req() request: AuthenticatedRequest) {
    if (this.config.nodeEnv === 'production') {
      throw new ForbiddenException({ code: 'ISO8583_SIMULATION_DISABLED', message: 'ISO 8583 simulation is disabled in production.' });
    }
    const existing = await this.prisma.transaction.findUnique({ where: { idempotencyKey: dto.idempotencyKey }, include: { transactionType: true } });
    if (existing) return { duplicate: true, transactionId: existing.transactionId, status: existing.status, responseCode: existing.responseCode, rrn: existing.rrn };
    const type = await this.prisma.transactionType.findUnique({ where: { code: dto.transactionType } });
    if (!type?.enabled) throw new ForbiddenException({ code: 'TRANSACTION_TYPE_UNAVAILABLE', message: 'The selected transaction type is unavailable.' });

    const requestMessage = this.iso.validate(dto.mti, this.requestFields(dto));
    const rrn = this.rrn(dto.stan);
    const outcome = this.outcome(dto.scenario);
    const responseFields: IsoFields = { ...requestMessage.fields, 37: rrn, 39: outcome.responseCode };
    const responseMessage = this.iso.validate(this.iso.responseMti(dto.mti), responseFields);
    const createdAt = new Date();
    const transactionId = `ISO-${createdAt.getTime()}-${dto.stan}`;
    const transaction = await this.prisma.transaction.create({ data: {
      transactionTypeId: type.id,
      transactionId,
      idempotencyKey: dto.idempotencyKey,
      rrn,
      amount: (Number.parseInt(dto.amountMinor, 10) / 100).toFixed(2),
      currency: dto.currency,
      direction: type.financial ? 'DEBIT' : 'NON_FINANCIAL',
      channel: 'ISO8583_UAT',
      sourceReference: dto.source,
      destinationReference: dto.destination,
      status: outcome.status,
      responseCode: outcome.responseCode,
      responseDescription: outcome.description,
      processingTimeMs: outcome.processingTimeMs,
      completedAt: new Date(createdAt.getTime() + outcome.processingTimeMs),
      events: { create: [
        { toStatus: TransactionStatus.PENDING, eventType: 'ISO8583_REQUEST_ACCEPTED', safeMetadata: { mti: dto.mti, bitmap: requestMessage.bitmap, stan: dto.stan, terminalId: dto.terminalId } },
        { fromStatus: TransactionStatus.PENDING, toStatus: TransactionStatus.PROCESSING, eventType: 'ISO8583_ROUTED', safeMetadata: { profile: 'AFGHAN_EMI_SAFE_UAT' } },
        { fromStatus: TransactionStatus.PROCESSING, toStatus: outcome.status, eventType: `ISO8583_${outcome.status}`, safeMetadata: { responseMti: responseMessage.mti, responseCode: outcome.responseCode, rrn } },
      ] },
    } });
    await this.audit.record({ actorId: request.principal.sub, actorSnapshot: request.principal.sub, action: 'ISO8583_SCENARIO_SIMULATED', resource: 'transaction', resourceId: transaction.id, requestId: request.requestId ?? dto.idempotencyKey, newValue: { scenario: dto.scenario, transactionId, responseCode: outcome.responseCode } });
    this.realtime.transactionUpdated({ transactionId, status: outcome.status });
    return { duplicate: false, transactionId, status: outcome.status, responseCode: outcome.responseCode, responseDescription: outcome.description, rrn, request: requestMessage, response: responseMessage };
  }

  private requestFields(dto: IsoMessageDto): IsoFields {
    return { 3: dto.processingCode, 4: dto.amountMinor, 7: dto.transmissionDateTime ?? this.transmissionDateTime(), 11: dto.stan, 41: dto.terminalId, 42: dto.merchantId, 49: dto.currencyCode };
  }

  private outcome(scenario: IsoScenario) {
    if (scenario === IsoScenario.APPROVED) return { status: TransactionStatus.SUCCESS, responseCode: '00', description: 'Approved', processingTimeMs: 180 };
    if (scenario === IsoScenario.INSUFFICIENT_FUNDS) return { status: TransactionStatus.FAILED, responseCode: '51', description: 'Insufficient funds', processingTimeMs: 210 };
    return { status: TransactionStatus.TIMEOUT, responseCode: '68', description: 'Response received too late', processingTimeMs: 15000 };
  }

  private transmissionDateTime(): string {
    const now = new Date();
    return `${String(now.getUTCMonth() + 1).padStart(2, '0')}${String(now.getUTCDate()).padStart(2, '0')}${String(now.getUTCHours()).padStart(2, '0')}${String(now.getUTCMinutes()).padStart(2, '0')}${String(now.getUTCSeconds()).padStart(2, '0')}`;
  }

  private rrn(stan: string): string {
    const now = new Date();
    const day = Math.floor((Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()) - Date.UTC(now.getUTCFullYear(), 0, 0)) / 86_400_000);
    return `${String(now.getUTCFullYear()).slice(-1)}${String(day).padStart(3, '0')}${String(now.getUTCHours()).padStart(2, '0')}${stan}`;
  }
}
