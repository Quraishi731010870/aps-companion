import { UnauthorizedException } from '@nestjs/common';
import { AccountStatus } from '@prisma/client';
import type { Request } from 'express';
import { generateKeyPairSync, randomBytes, sign, type KeyObject } from 'node:crypto';
import type { PrismaService } from '../database/prisma.service';
import type { RedisService } from '../database/redis.service';
import { DeviceBindingService } from './device-binding.service';
import { canonicalRequest } from './request-signature';

interface DeviceRow { id: string; userId: string; installationId: string; publicKey: string | null; status: AccountStatus; boundAt: Date | null }

function keyPair() {
  const { privateKey, publicKey } = generateKeyPairSync('ed25519');
  return { privateKey, raw: (publicKey.export({ format: 'jwk' }) as { x: string }).x };
}

function signedRequest(privateKey: KeyObject, { method = 'POST', path = '/api/v1/transactions', body = '{"amount":10}', nonce = randomBytes(16).toString('base64url') } = {}): Request {
  const bytes = Buffer.from(body);
  const parts = { method, path, timestamp: String(Date.now()), nonce, body: bytes };
  const headers: Record<string, string> = {
    'x-request-timestamp': parts.timestamp,
    'x-request-nonce': nonce,
    'x-device-signature': sign(null, Buffer.from(canonicalRequest(parts)), privateKey).toString('base64url'),
  };
  return { method, originalUrl: path, path, rawBody: bytes, header: (name: string) => headers[name] } as unknown as Request;
}

function setup() {
  const devices: DeviceRow[] = [];
  const sessions = new Map<string, { userId: string; deviceId: string }>();
  const events: string[] = [];
  const nonces = new Set<string>();
  const find = (where: { userId_installationId: { userId: string; installationId: string } }) =>
    devices.find((d) => d.userId === where.userId_installationId.userId && d.installationId === where.userId_installationId.installationId);
  const prisma = {
    device: {
      findUnique: async ({ where }: { where: Parameters<typeof find>[0] }) => find(where) ?? null,
      upsert: async ({ where, create, update }: { where: Parameters<typeof find>[0]; create: Omit<DeviceRow, 'id' | 'status'>; update: Partial<DeviceRow> }) => {
        const existing = find(where);
        if (existing) return Object.assign(existing, update);
        const row = { ...create, id: `device-${devices.length + 1}`, status: AccountStatus.ACTIVE } as DeviceRow;
        devices.push(row);
        return row;
      },
    },
    session: {
      findUnique: async ({ where }: { where: { id: string } }) => {
        const session = sessions.get(where.id);
        return session ? { userId: session.userId, device: devices.find((d) => d.id === session.deviceId) ?? null } : null;
      },
    },
    securityEvent: { create: async ({ data }: { data: { type: string } }) => { events.push(data.type); } },
  } as unknown as PrismaService;
  const redis = {
    ready: async () => ({
      set: async (key: string) => { if (nonces.has(key)) return null; nonces.add(key); return 'OK'; },
    }),
  } as unknown as RedisService;
  return { service: new DeviceBindingService(prisma, redis), devices, sessions, events };
}

async function errorCode(promise: Promise<unknown>): Promise<unknown> {
  try { await promise; return undefined; } catch (error) {
    const body = error instanceof UnauthorizedException ? error.getResponse() : undefined;
    return typeof body === 'object' && body && 'code' in body ? body.code : 'OTHER';
  }
}

const binding = (publicKey: string) => ({ installationId: 'install-0123456789abcdef', platform: 'ANDROID' as const, publicKey });

describe('DeviceBindingService', () => {
  it('binds a new device once its key proves possession, and records the event', async () => {
    const { service, devices, events } = setup();
    const key = keyPair();
    await service.verifyNewKey(key.raw, signedRequest(key.privateKey, { path: '/api/v1/auth/login' }));
    const id = await service.bind('user-1', binding(key.raw));
    expect(devices).toHaveLength(1);
    expect(devices[0]).toMatchObject({ id, publicKey: key.raw, userId: 'user-1' });
    expect(events).toEqual(['DEVICE_BOUND']);
  });

  it('rejects a login signed with a different key than the one registered', async () => {
    const { service } = setup();
    const key = keyPair();
    const other = keyPair();
    expect(await errorCode(service.verifyNewKey(key.raw, signedRequest(other.privateKey)))).toBe('DEVICE_SIGNATURE_INVALID');
  });

  it('refuses to rebind a known installation to a new key', async () => {
    const { service, events } = setup();
    const original = keyPair();
    await service.bind('user-1', binding(original.raw));
    expect(await errorCode(service.bind('user-1', binding(keyPair().raw)))).toBe('DEVICE_KEY_MISMATCH');
    expect(events).toContain('DEVICE_KEY_MISMATCH');
  });

  it('verifies session requests against the bound device and blocks replays', async () => {
    const { service, sessions } = setup();
    const key = keyPair();
    const deviceId = await service.bind('user-1', binding(key.raw));
    sessions.set('session-1', { userId: 'user-1', deviceId });

    const request = signedRequest(key.privateKey);
    await expect(service.verifyForSession('session-1', request)).resolves.toMatchObject({ id: deviceId });
    expect(await errorCode(service.verifyForSession('session-1', request))).toBe('DEVICE_SIGNATURE_REPLAYED');
  });

  it('rejects requests signed by another device and raises a security event', async () => {
    const { service, sessions, events } = setup();
    const key = keyPair();
    sessions.set('session-1', { userId: 'user-1', deviceId: await service.bind('user-1', binding(key.raw)) });

    expect(await errorCode(service.verifyForSession('session-1', signedRequest(keyPair().privateKey)))).toBe('DEVICE_SIGNATURE_INVALID');
    expect(events).toContain('DEVICE_SIGNATURE_REJECTED');
  });

  it('rejects sessions with no bound device or a blocked device', async () => {
    const { service, sessions, devices } = setup();
    const key = keyPair();
    const deviceId = await service.bind('user-1', binding(key.raw));
    sessions.set('session-1', { userId: 'user-1', deviceId });
    expect(await errorCode(service.verifyForSession('missing', signedRequest(key.privateKey)))).toBe('DEVICE_NOT_BOUND');

    devices[0].status = AccountStatus.DISABLED;
    expect(await errorCode(service.verifyForSession('session-1', signedRequest(key.privateKey)))).toBe('DEVICE_NOT_BOUND');
  });

  it('requires the signature headers', async () => {
    const { service, sessions } = setup();
    const key = keyPair();
    sessions.set('session-1', { userId: 'user-1', deviceId: await service.bind('user-1', binding(key.raw)) });
    const unsigned = { method: 'GET', originalUrl: '/api/v1/cards', path: '/api/v1/cards', header: () => undefined } as unknown as Request;
    expect(await errorCode(service.verifyForSession('session-1', unsigned))).toBe('DEVICE_SIGNATURE_REQUIRED');
  });
});
