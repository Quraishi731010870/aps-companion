import type { Request } from 'express';

export interface AuthPrincipal {
  sub: string;
  type: 'ADMIN' | 'MOBILE_USER';
  sessionId: string;
  roles: string[];
  permissions: string[];
}

export type AuthenticatedRequest = Request & { principal: AuthPrincipal; requestId?: string };
