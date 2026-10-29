import { ConflictException, NotFoundException } from '@nestjs/common';
import { AccountStatus } from '@prisma/client';
import type { AuthenticatedRequest } from '../auth/auth.types';
import type { PrismaService } from '../database/prisma.service';
import type { RealtimeGateway } from '../realtime/realtime.gateway';
import { CustomerControlsController } from './customer-controls.controller';

const request = { principal: { sub: 'admin-1', type: 'ADMIN', sessionId: 's', roles: [], permissions: ['customers.manage'] }, requestId: 'req-1' } as unknown as AuthenticatedRequest;
const CUSTOMER = '11111111-1111-4111-8111-111111111111';
const ITEM = '22222222-2222-4222-8222-222222222222';

function setup(found: { status: AccountStatus; userId?: string } | null) {
  const db = {
    customer: { findUnique: jest.fn().mockResolvedValue(found), update: jest.fn() },
    user: { update: jest.fn() },
    account: { findFirst: jest.fn().mockResolvedValue(found), update: jest.fn() },
    savedCard: { findFirst: jest.fn().mockResolvedValue(found), update: jest.fn() },
    device: { findFirst: jest.fn().mockResolvedValue(found), update: jest.fn() },
    session: { updateMany: jest.fn() },
    auditLog: { create: jest.fn() },
  };
  const prisma = { $transaction: (run: (tx: typeof db) => unknown) => run(db) } as unknown as PrismaService;
  const realtime = { userStatusChanged: jest.fn() } as unknown as RealtimeGateway & { userStatusChanged: jest.Mock };
  return { db, realtime, controls: new CustomerControlsController(prisma, realtime) };
}

describe('CustomerControlsController', () => {
  it('blocks a customer, signs them out everywhere and audits the reason', async () => {
    const { db, realtime, controls } = setup({ status: AccountStatus.ACTIVE, userId: 'user-1' });
    await expect(controls.customer(CUSTOMER, { action: 'block', reason: ' Suspected fraud ' }, request)).resolves.toEqual({ id: CUSTOMER, status: 'blocked' });
    expect(db.customer.update).toHaveBeenCalledWith({ where: { id: CUSTOMER }, data: { status: AccountStatus.BLOCKED } });
    expect(db.user.update.mock.calls[0][0].data.status).toBe(AccountStatus.BLOCKED);
    expect(db.session.updateMany.mock.calls[0][0].where).toEqual({ userId: 'user-1', status: 'ACTIVE' });
    expect(db.auditLog.create.mock.calls[0][0].data).toMatchObject({ action: 'CUSTOMER_STATUS_UPDATE', resourceId: CUSTOMER, oldValue: { status: 'ACTIVE' }, newValue: { status: 'BLOCKED', action: 'block', reason: 'Suspected fraud' } });
    expect(realtime.userStatusChanged).toHaveBeenCalledWith({ userId: 'user-1', status: AccountStatus.BLOCKED });
  });

  it('unblocking a customer clears any sign-in lockout and keeps sessions', async () => {
    const { db, controls } = setup({ status: AccountStatus.BLOCKED, userId: 'user-1' });
    await controls.customer(CUSTOMER, { action: 'unblock', reason: 'Cleared by compliance' }, request);
    expect(db.user.update.mock.calls[0][0].data).toMatchObject({ status: AccountStatus.ACTIVE, failedLoginCount: 0, lockedUntil: null });
    expect(db.session.updateMany).not.toHaveBeenCalled();
  });

  it('refuses a transition the rules do not allow', async () => {
    const { db, controls } = setup({ status: AccountStatus.BLOCKED });
    await expect(controls.card(CUSTOMER, ITEM, { action: 'activate', reason: 'Try it' }, request)).rejects.toBeInstanceOf(ConflictException);
    expect(db.savedCard.update).not.toHaveBeenCalled();
    expect(db.auditLog.create).not.toHaveBeenCalled();
  });

  it("only touches items that belong to the customer", async () => {
    const { db, controls } = setup(null);
    await expect(controls.account(CUSTOMER, ITEM, { action: 'block', reason: 'Court order' }, request)).rejects.toBeInstanceOf(NotFoundException);
    expect(db.account.findFirst.mock.calls[0][0].where).toEqual({ id: ITEM, customerId: CUSTOMER });
    await expect(controls.card(CUSTOMER, ITEM, { action: 'block', reason: 'Stolen' }, request)).rejects.toBeInstanceOf(NotFoundException);
    expect(db.savedCard.findFirst.mock.calls[0][0].where).toEqual({ id: ITEM, customerId: CUSTOMER, revokedAt: null });
  });

  it('deactivating a device ends the sessions bound to it', async () => {
    const { db, controls } = setup({ status: AccountStatus.ACTIVE });
    await expect(controls.device(CUSTOMER, ITEM, { action: 'deactivate', reason: 'Lost phone' }, request)).resolves.toEqual({ id: ITEM, status: 'disabled' });
    expect(db.session.updateMany.mock.calls[0][0].where).toEqual({ deviceId: ITEM, status: 'ACTIVE' });
  });
});
