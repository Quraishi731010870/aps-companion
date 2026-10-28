import { Body, Controller, Delete, ForbiddenException, Get, HttpCode, NotFoundException, Param, Post, Req } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { ValidateNested } from 'class-validator';
import { randomBytes } from 'node:crypto';
import type { AuthenticatedRequest } from '../auth/auth.types';
import { AuditService } from '../audit/audit.service';
import { PrismaService } from '../database/prisma.service';
import { CardCryptoService } from './card-crypto.service';
import { maskPan } from './card-envelope';
import { CardEnvelopeDto } from './card-envelope.dto';

class SaveCardDto {
  @ValidateNested() @Type(() => CardEnvelopeDto) encryptedCard!: CardEnvelopeDto;
}

interface SavedCardView { token: string; maskedPan: string; expiryMonth: number | null; expiryYear: number | null; holderName: string | null }

/**
 * Card vault for mobile customers. Cards arrive encrypted (see card-envelope.ts),
 * are stored encrypted at rest, and only a random token plus the masked PAN is
 * ever returned.
 */
@ApiTags('cards') @ApiBearerAuth() @Controller({ path: 'cards', version: '1' })
export class CardsController {
  constructor(private readonly prisma: PrismaService, private readonly crypto: CardCryptoService, private readonly audit: AuditService) {}

  /** Public key the app encrypts card data with; the app pins its `kid`. */
  @Get('encryption-key') encryptionKey(@Req() request: AuthenticatedRequest) {
    this.requireCustomer(request);
    return this.crypto.publicKey();
  }

  @Post() async save(@Body() dto: SaveCardDto, @Req() request: AuthenticatedRequest): Promise<SavedCardView> {
    const customerId = await this.customerId(request);
    const card = this.crypto.open(dto.encryptedCard);
    const vault = this.crypto.vaultCipher();
    const fingerprint = vault.fingerprint(card.pan);
    const data = {
      panCiphertext: vault.encrypt(card.pan, customerId),
      maskedPan: maskPan(card.pan),
      expiryMonth: card.expMonth ?? null,
      expiryYear: card.expYear ?? null,
      holderName: card.holder?.trim() || null,
      keyId: this.crypto.publicKey().kid,
    };
    // Re-saving the same card returns the existing token instead of a duplicate.
    const saved = await this.prisma.savedCard.upsert({
      where: { customerId_panFingerprint: { customerId, panFingerprint: fingerprint } },
      update: { ...data, revokedAt: null },
      create: { ...data, customerId, panFingerprint: fingerprint, token: `ctok_${randomBytes(24).toString('base64url')}` },
    });
    await this.audit.record({ actorId: request.principal.sub, actorSnapshot: request.principal.type, action: 'CARD_SAVED', resource: 'saved_card', resourceId: saved.id, newValue: { maskedPan: saved.maskedPan }, requestId: request.requestId ?? '' });
    return view(saved);
  }

  @Get() async list(@Req() request: AuthenticatedRequest): Promise<SavedCardView[]> {
    const customerId = await this.customerId(request);
    const cards = await this.prisma.savedCard.findMany({ where: { customerId, revokedAt: null }, orderBy: { createdAt: 'desc' } });
    return cards.map(view);
  }

  @Delete(':token') @HttpCode(204) async revoke(@Param('token') token: string, @Req() request: AuthenticatedRequest): Promise<void> {
    const customerId = await this.customerId(request);
    const { count } = await this.prisma.savedCard.updateMany({ where: { token, customerId, revokedAt: null }, data: { revokedAt: new Date() } });
    if (count === 0) throw new NotFoundException({ code: 'CARD_NOT_FOUND', message: 'Card not found.' });
    await this.audit.record({ actorId: request.principal.sub, actorSnapshot: request.principal.type, action: 'CARD_REVOKED', resource: 'saved_card', requestId: request.requestId ?? '' });
  }

  private requireCustomer(request: AuthenticatedRequest): void {
    if (request.principal.type !== 'MOBILE_USER') throw new ForbiddenException({ code: 'CUSTOMERS_ONLY', message: 'Only customers can manage cards.' });
  }

  private async customerId(request: AuthenticatedRequest): Promise<string> {
    this.requireCustomer(request);
    const customer = await this.prisma.customer.findUnique({ where: { userId: request.principal.sub }, select: { id: true } });
    if (!customer) throw new ForbiddenException({ code: 'CUSTOMERS_ONLY', message: 'Only customers can manage cards.' });
    return customer.id;
  }
}

function view(card: SavedCardView): SavedCardView {
  return { token: card.token, maskedPan: card.maskedPan, expiryMonth: card.expiryMonth, expiryYear: card.expiryYear, holderName: card.holderName };
}
