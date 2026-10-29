import type { AuthenticatedRequest } from '../auth/auth.types';
import type { CardCryptoService } from '../cards/card-crypto.service';
import type { PrismaService } from '../database/prisma.service';
import { TransactionsController } from './transactions.controller';

const admin = { principal: { sub: 'admin-1', type: 'ADMIN', sessionId: 's', roles: [], permissions: ['transactions.view'] } } as unknown as AuthenticatedRequest;

function controller() {
  const findFirst = jest.fn().mockResolvedValue({ transactionId: 'AFG-1', transactionType: { code: '774', name: 'Purchase' }, customer: null, events: [], amount: 1, status: 'PENDING' });
  return { transactions: new TransactionsController({ transaction: { findFirst } } as unknown as PrismaService, {} as CardCryptoService), findFirst };
}

describe('TransactionsController.detail', () => {
  it('looks up a transaction number without comparing it to the UUID column', async () => {
    const { transactions, findFirst } = controller();
    await transactions.detail('AFG-1793277289027-731', admin);
    expect(findFirst.mock.calls[0][0].where.AND[0]).toEqual({ OR: [{ transactionId: 'AFG-1793277289027-731' }] });
  });

  it('still accepts the internal UUID', async () => {
    const { transactions, findFirst } = controller();
    const id = '3f1c2a8e-5b6d-4c7e-9f00-112233445566';
    await transactions.detail(id, admin);
    expect(findFirst.mock.calls[0][0].where.AND[0]).toEqual({ OR: [{ id }, { transactionId: id }] });
  });
});

describe('TransactionsController.create status checks', () => {
  const mobile = { principal: { sub: 'user-1', type: 'MOBILE_USER', sessionId: 's', roles: [], permissions: [] } } as unknown as AuthenticatedRequest;
  const dto = { transactionType: 774, source: 'WALLET-AF000001', destination: 'M-1', amount: 10, currency: 'AFN', reference: 'r', idempotencyKey: 'k-1' };
  function create(customer: object, savedCard: object | null = null) {
    const transactionCreate = jest.fn().mockResolvedValue({ transactionId: 'AFG-1', status: 'PENDING', createdAt: new Date() });
    const prisma = {
      transaction: { findUnique: jest.fn().mockResolvedValue(null), create: transactionCreate },
      transactionType: { findUnique: jest.fn().mockResolvedValue({ id: 't', enabled: true, financial: true }) },
      customer: { findUnique: jest.fn().mockResolvedValue(customer) },
      savedCard: { findFirst: jest.fn().mockResolvedValue(savedCard) },
    } as unknown as PrismaService;
    return { transactions: new TransactionsController(prisma, {} as CardCryptoService), transactionCreate };
  }

  it('refuses payments from a customer an operator deactivated or blocked', async () => {
    const { transactions, transactionCreate } = create({ id: 'c', status: 'BLOCKED', accounts: [{ id: 'a' }] });
    await expect(transactions.create(dto, mobile)).rejects.toMatchObject({ response: { code: 'CUSTOMER_UNAVAILABLE' } });
    expect(transactionCreate).not.toHaveBeenCalled();
  });

  it('refuses financial payments when the wallet is not active', async () => {
    const { transactions } = create({ id: 'c', status: 'ACTIVE', accounts: [] });
    await expect(transactions.create(dto, mobile)).rejects.toMatchObject({ response: { code: 'ACCOUNT_UNAVAILABLE' } });
  });

  it('refuses a saved card an operator blocked', async () => {
    const { transactions } = create({ id: 'c', status: 'ACTIVE', accounts: [{ id: 'a' }] }, { maskedPan: '603799******1234', status: 'BLOCKED' });
    await expect(transactions.create({ ...dto, cardToken: 'ctok_1' }, mobile)).rejects.toMatchObject({ response: { code: 'CARD_UNAVAILABLE' } });
  });

  it('accepts an active customer, wallet and card', async () => {
    const { transactions, transactionCreate } = create({ id: 'c', status: 'ACTIVE', accounts: [{ id: 'a' }] }, { maskedPan: '603799******1234', status: 'ACTIVE' });
    await expect(transactions.create({ ...dto, cardToken: 'ctok_1' }, mobile)).resolves.toMatchObject({ status: 'PENDING' });
    expect(transactionCreate.mock.calls[0][0].data.sourceReference).toBe('603799******1234');
  });
});
