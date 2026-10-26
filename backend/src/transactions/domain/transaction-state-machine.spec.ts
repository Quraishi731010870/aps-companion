import { TransactionStatus } from '@prisma/client';
import { assertTransactionTransition, InvalidTransactionTransitionError } from './transaction-state-machine';

describe('transaction state machine', () => {
  it.each([[TransactionStatus.PENDING, TransactionStatus.PROCESSING], [TransactionStatus.PROCESSING, TransactionStatus.SUCCESS], [TransactionStatus.SUCCESS, TransactionStatus.REVERSED], [TransactionStatus.TIMEOUT, TransactionStatus.PROCESSING]])('allows %s to %s', (from, to) => expect(() => assertTransactionTransition(from, to)).not.toThrow());
  it.each([[TransactionStatus.SUCCESS, TransactionStatus.PROCESSING], [TransactionStatus.FAILED, TransactionStatus.SUCCESS], [TransactionStatus.REVERSED, TransactionStatus.SUCCESS]])('rejects %s to %s', (from, to) => expect(() => assertTransactionTransition(from, to)).toThrow(InvalidTransactionTransitionError));
});
