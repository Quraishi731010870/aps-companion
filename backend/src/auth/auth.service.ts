import { Injectable, UnauthorizedException } from '@nestjs/common';
import { AccountStatus, PrincipalType, SessionStatus } from '@prisma/client';
import argon2 from 'argon2';
import jwt, { type SignOptions } from 'jsonwebtoken';
import { createHash, randomBytes } from 'node:crypto';
import { PrismaService } from '../database/prisma.service';
import { RuntimeConfig } from '../configuration/runtime-config.service';
import type { AuthPrincipal } from './auth.types';

@Injectable()
export class AuthService {
  constructor(private readonly prisma: PrismaService, private readonly config: RuntimeConfig) {}

  async login(identifier: string, password: string, expectedType?: PrincipalType) {
    const normalized = identifier.trim().toLowerCase();
    const user = await this.prisma.user.findFirst({
      where: { OR: [{ email: { equals: normalized, mode: 'insensitive' } }, { phone: identifier.trim() }] },
      include: { roles: { include: { role: { include: { permissions: { include: { permission: true } } } } } } },
    });
    if (user?.lockedUntil && user.lockedUntil > new Date()) {
      await this.recordAttempt(user.id, normalized, false, 'ACCOUNT_LOCKED');
      throw new UnauthorizedException({ code: 'ACCOUNT_LOCKED', message: 'The account is temporarily locked. Try again later.' });
    }
    const valid = user ? await argon2.verify(user.passwordHash, password) : false;
    if (!user || !valid || user.status !== AccountStatus.ACTIVE || (expectedType && user.principalType !== expectedType)) {
      await this.recordAttempt(user?.id, normalized, false, 'INVALID_CREDENTIALS');
      if (user) {
        const failures = user.failedLoginCount + 1;
        await this.prisma.user.update({ where: { id: user.id }, data: { failedLoginCount: failures, lockedUntil: failures >= 5 ? new Date(Date.now() + 15 * 60_000) : null } });
      }
      throw new UnauthorizedException({ code: 'INVALID_CREDENTIALS', message: 'The supplied credentials are invalid.' });
    }
    await this.recordAttempt(user.id, normalized, true);
    await this.prisma.user.update({ where: { id: user.id }, data: { failedLoginCount: 0, lockedUntil: null } });
    const session = await this.prisma.session.create({
      data: { userId: user.id, expiresAt: new Date(Date.now() + this.config.jwtRefreshTtlDays * 86_400_000) },
    });
    return { ...(await this.issueTokens(user, session.id)), displayName: user.displayName };
  }

  async refresh(refreshToken: string) {
    const decoded = this.verifyRefresh(refreshToken);
    const tokenHash = this.hash(refreshToken);
    const session = await this.prisma.session.findFirst({
      where: { id: decoded.sessionId, refreshTokenHash: tokenHash, status: SessionStatus.ACTIVE, expiresAt: { gt: new Date() } },
      include: { user: { include: { roles: { include: { role: { include: { permissions: { include: { permission: true } } } } } } } } },
    });
    if (!session || session.user.status !== AccountStatus.ACTIVE) throw new UnauthorizedException({ code: 'SESSION_INVALID', message: 'The session is invalid or expired.' });
    return { ...(await this.issueTokens(session.user, session.id)), displayName: session.user.displayName };
  }

  async logout(sessionId: string): Promise<void> {
    await this.prisma.session.updateMany({ where: { id: sessionId }, data: { status: SessionStatus.REVOKED, revokedAt: new Date(), refreshTokenHash: null } });
  }

  verifyAccess(token: string): AuthPrincipal {
    try { return jwt.verify(token, this.config.jwtAccessSecret, { algorithms: ['HS256'], issuer: 'afghanpay-api', audience: 'afghanpay-clients' }) as AuthPrincipal; }
    catch { throw new UnauthorizedException({ code: 'TOKEN_INVALID', message: 'The access token is invalid or expired.' }); }
  }

  async authenticateAccess(token: string): Promise<AuthPrincipal> {
    const principal = this.verifyAccess(token);
    const session = await this.prisma.session.findFirst({
      where: { id: principal.sessionId, userId: principal.sub, status: SessionStatus.ACTIVE, expiresAt: { gt: new Date() }, user: { status: AccountStatus.ACTIVE } },
      select: { id: true },
    });
    if (!session) throw new UnauthorizedException({ code: 'SESSION_INVALID', message: 'The session is invalid or expired.' });
    return principal;
  }

  csrfToken(): string { return randomBytes(32).toString('base64url'); }

  private verifyRefresh(token: string): AuthPrincipal {
    try { return jwt.verify(token, this.config.jwtRefreshSecret, { algorithms: ['HS256'], issuer: 'afghanpay-api', audience: 'afghanpay-refresh' }) as AuthPrincipal; }
    catch { throw new UnauthorizedException({ code: 'REFRESH_TOKEN_INVALID', message: 'The refresh token is invalid or expired.' }); }
  }

  private async issueTokens(user: { id: string; principalType: PrincipalType; roles: Array<{ role: { code: string; permissions: Array<{ permission: { code: string } }> } }> }, sessionId: string) {
    const roles = user.roles.map((entry) => entry.role.code);
    const permissions = [...new Set(user.roles.flatMap((entry) => entry.role.permissions.map((item) => item.permission.code)))];
    const payload: AuthPrincipal = { sub: user.id, type: user.principalType, sessionId, roles, permissions };
    const accessToken = jwt.sign(payload, this.config.jwtAccessSecret, { algorithm: 'HS256', issuer: 'afghanpay-api', audience: 'afghanpay-clients', expiresIn: this.config.jwtAccessTtl as SignOptions['expiresIn'], jwtid: randomBytes(16).toString('hex') });
    const refreshToken = jwt.sign(payload, this.config.jwtRefreshSecret, { algorithm: 'HS256', issuer: 'afghanpay-api', audience: 'afghanpay-refresh', expiresIn: `${this.config.jwtRefreshTtlDays}d`, jwtid: randomBytes(16).toString('hex') });
    await this.prisma.session.update({ where: { id: sessionId }, data: { refreshTokenHash: this.hash(refreshToken), lastSeenAt: new Date() } });
    return { accessToken, refreshToken, expiresIn: this.config.jwtAccessTtl, principal: payload };
  }

  private hash(value: string): string { return createHash('sha256').update(value).digest('hex'); }
  private async recordAttempt(userId: string | undefined, identifier: string, successful: boolean, failureCode?: string) {
    await this.prisma.loginAttempt.create({ data: { userId, identifierHash: this.hash(identifier), successful, failureCode } });
  }
}
