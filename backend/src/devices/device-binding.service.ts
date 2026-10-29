import { Injectable, UnauthorizedException } from '@nestjs/common';
import { AccountStatus, AlertSeverity, type Prisma } from '@prisma/client';
import type { Request } from 'express';
import { PrismaService } from '../database/prisma.service';
import { RedisService } from '../database/redis.service';
import type { DeviceBindingDto } from './device-binding.dto';
import { NONCE_TTL_MS, readSignedRequest, SignatureError, SignedRequest, verifySignedRequest } from './request-signature';

export const KEY_ALGORITHM = 'Ed25519';

export interface VerifiedDevice { id: string; signature: string }

type DeviceFailure = SignatureError['code'] | 'DEVICE_SIGNATURE_REPLAYED' | 'DEVICE_NOT_BOUND' | 'DEVICE_KEY_MISMATCH';

/**
 * Binds an installation's Ed25519 key to a customer at login and checks the
 * device signature on every later request (APS p.27, p.49).
 */
@Injectable()
export class DeviceBindingService {
  constructor(private readonly prisma: PrismaService, private readonly redis: RedisService) {}

  /** Login: proves the caller holds the private key it is registering. Runs before the password check. */
  async verifyNewKey(publicKey: string, request: Request): Promise<void> {
    const signed = this.signedRequest(request);
    this.verify(publicKey, signed);
    await this.consumeNonce(publicKey, signed.nonce);
  }

  /** Records the device for [userId]; a known installation must keep the key it was bound with. */
  async bind(userId: string, device: DeviceBindingDto): Promise<string> {
    const existing = await this.prisma.device.findUnique({ where: { userId_installationId: { userId, installationId: device.installationId } } });
    if (existing?.publicKey && existing.publicKey !== device.publicKey) {
      await this.securityEvent(userId, 'DEVICE_KEY_MISMATCH', AlertSeverity.HIGH, { deviceId: existing.id });
      throw this.rejected('DEVICE_KEY_MISMATCH');
    }
    if (existing && existing.status !== AccountStatus.ACTIVE) throw this.rejected('DEVICE_NOT_BOUND');
    const now = new Date();
    const saved = await this.prisma.device.upsert({
      where: { userId_installationId: { userId, installationId: device.installationId } },
      create: { userId, installationId: device.installationId, platform: device.platform, name: device.name, publicKey: device.publicKey, keyAlgorithm: KEY_ALGORITHM, boundAt: now, lastSeenAt: now },
      update: { platform: device.platform, name: device.name, publicKey: device.publicKey, keyAlgorithm: KEY_ALGORITHM, boundAt: existing?.boundAt ?? now, lastSeenAt: now },
    });
    if (!existing?.publicKey) await this.securityEvent(userId, 'DEVICE_BOUND', AlertSeverity.WARNING, { deviceId: saved.id, platform: device.platform });
    return saved.id;
  }

  /** Every authenticated mobile request: the signature must come from the device bound to this session. */
  async verifyForSession(sessionId: string, request: Request): Promise<VerifiedDevice> {
    const session = await this.prisma.session.findUnique({
      where: { id: sessionId },
      select: { userId: true, device: { select: { id: true, publicKey: true, status: true } } },
    });
    const device = session?.device;
    if (!session || !device?.publicKey || device.status !== AccountStatus.ACTIVE) throw this.rejected('DEVICE_NOT_BOUND');
    const signed = this.signedRequest(request);
    try {
      this.verify(device.publicKey, signed);
    } catch (error) {
      if (error instanceof UnauthorizedException && this.codeOf(error) === 'DEVICE_SIGNATURE_INVALID') {
        await this.securityEvent(session.userId, 'DEVICE_SIGNATURE_REJECTED', AlertSeverity.HIGH, { deviceId: device.id, path: request.path });
      }
      throw error;
    }
    await this.consumeNonce(device.publicKey, signed.nonce);
    return { id: device.id, signature: signed.signature };
  }

  private signedRequest(request: Request): SignedRequest {
    try {
      return readSignedRequest(request.method, request.originalUrl, (name) => request.header(name), (request as Request & { rawBody?: Buffer }).rawBody);
    } catch (error) {
      throw error instanceof SignatureError ? this.rejected(error.code) : error;
    }
  }

  private verify(publicKey: string, signed: SignedRequest): void {
    try { verifySignedRequest(publicKey, signed); }
    catch (error) { throw error instanceof SignatureError ? this.rejected(error.code) : this.rejected('DEVICE_SIGNATURE_INVALID'); }
  }

  /** Each nonce is accepted once per key while its timestamp could still pass the freshness check. */
  private async consumeNonce(publicKey: string, nonce: string): Promise<void> {
    const client = await this.redis.ready();
    const stored = await client.set(`device-nonce:${publicKey}:${nonce}`, '1', 'PX', NONCE_TTL_MS, 'NX');
    if (stored !== 'OK') throw this.rejected('DEVICE_SIGNATURE_REPLAYED');
  }

  private rejected(code: DeviceFailure): UnauthorizedException {
    return new UnauthorizedException({ code, message: 'This device could not be verified.' });
  }

  private codeOf(error: UnauthorizedException): unknown {
    const body = error.getResponse();
    return typeof body === 'object' && body && 'code' in body ? body.code : undefined;
  }

  private async securityEvent(userId: string, type: string, severity: AlertSeverity, safeMetadata: Prisma.InputJsonObject): Promise<void> {
    await this.prisma.securityEvent.create({ data: { userId, type, severity, safeMetadata } });
  }
}
