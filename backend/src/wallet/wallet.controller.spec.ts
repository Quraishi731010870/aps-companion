import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import type { AuthenticatedRequest } from '../auth/auth.types';
import type { PrismaService } from '../database/prisma.service';
import { WalletController } from './wallet.controller';

const request = (type: 'MOBILE_USER' | 'ADMIN') => ({ principal: { sub: 'user-1', type, sessionId: 's', roles: [], permissions: [] } }) as unknown as AuthenticatedRequest;

function controller(account: object | null) {
  const findFirst = jest.fn().mockResolvedValue(account);
  return { wallet: new WalletController({ account: { findFirst } } as unknown as PrismaService), findFirst };
}

describe('WalletController', () => {
  it("returns the customer's own wallet with a numeric balance", async () => {
    const { wallet, findFirst } = controller({ accountNo: 'WALLET-AF000001', currency: 'AFN', availableBalance: new Prisma.Decimal('125.50') });
    await expect(wallet.current(request('MOBILE_USER'))).resolves.toEqual({ walletId: 'WALLET-AF000001', currency: 'AFN', availableBalance: 125.5 });
    expect(findFirst.mock.calls[0][0].where.customer).toEqual({ userId: 'user-1' });
  });

  it('reports a missing wallet and refuses admins', async () => {
    await expect(controller(null).wallet.current(request('MOBILE_USER'))).rejects.toBeInstanceOf(NotFoundException);
    await expect(controller(null).wallet.current(request('ADMIN'))).rejects.toBeInstanceOf(ForbiddenException);
  });
});
