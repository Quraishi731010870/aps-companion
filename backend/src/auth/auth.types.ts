import type { Request } from 'express';

export interface AuthPrincipal {
  sub: string;
  type: 'ADMIN' | 'MOBILE_USER';
  sessionId: string;
  roles: string[];
  permissions: string[];
}

/** `device` is set for mobile customers once DeviceSignatureGuard has verified the request. */
export type AuthenticatedRequest = Request & { principal: AuthPrincipal; requestId?: string; device?: { id: string; signature: string } };
