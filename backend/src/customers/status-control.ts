import { AccountStatus } from '@prisma/client';

/** Operator actions on a customer, wallet account, saved card or device. */
export const STATUS_ACTIONS = ['activate', 'deactivate', 'block', 'unblock'] as const;
export type StatusAction = (typeof STATUS_ACTIONS)[number];

export class StatusTransitionError extends Error {
  constructor(readonly action: StatusAction, readonly from: AccountStatus) {
    super(`Cannot ${action} an item that is ${from.toLowerCase()}.`);
  }
}

const transitions: Record<StatusAction, { from: readonly AccountStatus[]; to: AccountStatus }> = {
  // LOCKED is a sign-in lockout; activating clears it.
  activate: { from: [AccountStatus.PENDING, AccountStatus.DISABLED, AccountStatus.LOCKED], to: AccountStatus.ACTIVE },
  deactivate: { from: [AccountStatus.ACTIVE, AccountStatus.PENDING, AccountStatus.LOCKED], to: AccountStatus.DISABLED },
  block: { from: [AccountStatus.ACTIVE, AccountStatus.PENDING, AccountStatus.DISABLED, AccountStatus.LOCKED], to: AccountStatus.BLOCKED },
  // Only unblock lifts a block, so a blocked item is never reactivated by accident.
  unblock: { from: [AccountStatus.BLOCKED], to: AccountStatus.ACTIVE },
};

/** The status an action leads to. CLOSED is final and accepts no action. */
export function nextStatus(current: AccountStatus, action: StatusAction): AccountStatus {
  const rule = transitions[action];
  if (!rule.from.includes(current)) throw new StatusTransitionError(action, current);
  return rule.to;
}

/** Actions the portal may offer for an item in `current`. */
export function availableActions(current: AccountStatus): StatusAction[] {
  return STATUS_ACTIONS.filter((action) => transitions[action].from.includes(current));
}
