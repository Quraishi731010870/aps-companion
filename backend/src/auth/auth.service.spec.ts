import { ConflictException, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import type { Request } from 'express';
import type { RuntimeConfig } from '../configuration/runtime-config.service';
import type { PrismaService } from '../database/prisma.service';
import type { DeviceBindingService } from '../devices/device-binding.service';
import { AuthService } from './auth.service';
import type { RegisterDto } from './dto/login.dto';

const dto: RegisterDto = { displayName: ' Test Customer ', phone: '+93701234567', password: 'a-long-password', device: { installationId: 'install-0123456789abcdef', platform: 'IOS', publicKey: 'k'.repeat(43) } };
const request = {} as Request;

function setup({ enabled = true, duplicate = false } = {}) {
  const created: Record<string, unknown[]> = { user: [], customer: [], account: [], securityEvent: [] };
  const table = (name: string) => ({ create: jest.fn(async ({ data }: { data: object }) => { created[name].push(data); return { id: `${name}-1`, ...data }; }) });
  const database = { user: table('user'), customer: table('customer'), account: table('account'), securityEvent: table('securityEvent') };
  const prisma = {
    $transaction: jest.fn(async (work: (db: typeof database) => unknown) => {
      if (duplicate) throw new Prisma.PrismaClientKnownRequestError('Unique constraint failed', { code: 'P2002', clientVersion: 'test' });
      return work(database);
    }),
    session: { create: jest.fn(async () => ({ id: 'session-1' })), update: jest.fn() },
  } as unknown as PrismaService;
  const config = { selfRegistrationEnabled: enabled, jwtRefreshTtlDays: 30, jwtAccessSecret: 'a'.repeat(32), jwtRefreshSecret: 'b'.repeat(32), jwtAccessTtl: '15m' } as RuntimeConfig;
  const devices = { verifyNewKey: jest.fn(), bind: jest.fn(async () => 'device-1') } as unknown as DeviceBindingService;
  return { auth: new AuthService(prisma, config, devices), created, devices };
}

describe('AuthService.register', () => {
  it('creates a customer with an empty wallet, binds the device and signs in', async () => {
    const { auth, created, devices } = setup();
    const result = await auth.register(dto, request);

    expect(devices.verifyNewKey).toHaveBeenCalledWith(dto.device.publicKey, request);
    expect(devices.bind).toHaveBeenCalledWith('user-1', dto.device);
    expect(created.user[0]).toMatchObject({ phone: '+93701234567', displayName: 'Test Customer', principalType: 'MOBILE_USER', status: 'ACTIVE' });
    expect((created.user[0] as { passwordHash: string }).passwordHash).not.toContain('a-long-password');
    expect(created.customer[0]).toMatchObject({ kycStatus: 'PENDING' });
    expect((created.account[0] as { accountNo: string }).accountNo).toMatch(/^WALLET-[A-Z2-9]{10}$/);
    expect(result).toMatchObject({ displayName: 'Test Customer', principal: { type: 'MOBILE_USER', sessionId: 'session-1' } });
    expect(typeof result.accessToken).toBe('string');
  });

  it('refuses a phone number that is already registered', async () => {
    await expect(setup({ duplicate: true }).auth.register(dto, request)).rejects.toBeInstanceOf(ConflictException);
  });

  it('is unavailable when self-registration is disabled', async () => {
    const { auth, devices } = setup({ enabled: false });
    await expect(auth.register(dto, request)).rejects.toBeInstanceOf(NotFoundException);
    expect(devices.verifyNewKey).not.toHaveBeenCalled();
  });
});
