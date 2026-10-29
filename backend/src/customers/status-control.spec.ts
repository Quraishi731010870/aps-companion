import { AccountStatus } from '@prisma/client';
import { availableActions, nextStatus, StatusTransitionError } from './status-control';

describe('status-control', () => {
  it('moves through activate, deactivate, block and unblock', () => {
    expect(nextStatus(AccountStatus.PENDING, 'activate')).toBe(AccountStatus.ACTIVE);
    expect(nextStatus(AccountStatus.ACTIVE, 'deactivate')).toBe(AccountStatus.DISABLED);
    expect(nextStatus(AccountStatus.DISABLED, 'activate')).toBe(AccountStatus.ACTIVE);
    expect(nextStatus(AccountStatus.ACTIVE, 'block')).toBe(AccountStatus.BLOCKED);
    expect(nextStatus(AccountStatus.BLOCKED, 'unblock')).toBe(AccountStatus.ACTIVE);
    expect(nextStatus(AccountStatus.LOCKED, 'activate')).toBe(AccountStatus.ACTIVE);
  });

  it('only unblock lifts a block, and a closed item accepts nothing', () => {
    expect(() => nextStatus(AccountStatus.BLOCKED, 'activate')).toThrow(StatusTransitionError);
    expect(() => nextStatus(AccountStatus.BLOCKED, 'deactivate')).toThrow(StatusTransitionError);
    expect(() => nextStatus(AccountStatus.ACTIVE, 'unblock')).toThrow(StatusTransitionError);
    expect(availableActions(AccountStatus.CLOSED)).toEqual([]);
  });

  it('lists the actions the portal may offer', () => {
    expect(availableActions(AccountStatus.ACTIVE)).toEqual(['deactivate', 'block']);
    expect(availableActions(AccountStatus.DISABLED)).toEqual(['activate', 'block']);
    expect(availableActions(AccountStatus.BLOCKED)).toEqual(['unblock']);
  });
});
