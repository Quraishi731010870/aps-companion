import { TransactionStatus } from '@prisma/client';

export class InvalidTransactionTransitionError extends Error {}

const transitions: Record<TransactionStatus, readonly TransactionStatus[]> = {
  PENDING: ['PROCESSING', 'CANCELLED', 'FAILED'],
  PROCESSING: ['SUCCESS', 'FAILED', 'TIMEOUT'],
  SUCCESS: ['REVERSED'],
  FAILED: [],
  REVERSED: [],
  CANCELLED: [],
  TIMEOUT: ['REVERSED', 'PROCESSING'],
};

export function assertTransactionTransition(from: TransactionStatus, to: TransactionStatus): void {
  if (!transitions[from].includes(to)) throw new InvalidTransactionTransitionError(`Transaction cannot move from ${from} to ${to}.`);
}
