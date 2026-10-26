import { Body, Controller, Get, Post, Req, Res, UnauthorizedException, VERSION_NEUTRAL, Version } from '@nestjs/common';
import { PrincipalType } from '@prisma/client';
import type { Request, Response } from 'express';
import { AuthService } from './auth.service';
import type { AuthenticatedRequest } from './auth.types';
import { Public } from './decorators/public.decorator';
import { AdminLoginDto } from './dto/login.dto';
import { RuntimeConfig } from '../configuration/runtime-config.service';

@Controller('admin/v1/auth')
export class AdminAuthController {
  constructor(private readonly auth: AuthService, private readonly config: RuntimeConfig) {}
  @Public() @Version(VERSION_NEUTRAL) @Get('csrf')
  csrf(@Res({ passthrough: true }) response: Response) {
    const csrfToken = this.auth.csrfToken();
    response.cookie('admin_csrf', csrfToken, { httpOnly: true, sameSite: 'strict', secure: process.env.NODE_ENV === 'production', path: '/' });
    return { csrfToken };
  }
  @Public() @Version(VERSION_NEUTRAL) @Post('login')
  async login(@Body() dto: AdminLoginDto, @Req() request: Request, @Res({ passthrough: true }) response: Response) {
    this.validateCsrf(request);
    const result = await this.auth.login(dto.operator, dto.password, PrincipalType.ADMIN);
    response.cookie(this.config.adminCookieName, result.accessToken, { httpOnly: true, sameSite: 'strict', secure: this.config.nodeEnv === 'production', path: '/', maxAge: this.config.adminSessionTtlMinutes * 60_000 });
    return this.sessionResponse(result.principal, result.displayName);
  }
  @Version(VERSION_NEUTRAL) @Get('session') session(@Req() request: AuthenticatedRequest) { return this.sessionResponse(request.principal, 'Administrator'); }
  @Version(VERSION_NEUTRAL) @Post('logout') async logout(@Req() request: AuthenticatedRequest, @Res({ passthrough: true }) response: Response) {
    this.validateCsrf(request);
    await this.auth.logout(request.principal.sessionId);
    response.clearCookie(this.config.adminCookieName, { path: '/', secure: this.config.nodeEnv === 'production', sameSite: 'strict' });
  }
  private validateCsrf(request: Request): void {
    const header = request.header('x-csrf-token');
    if (!header || header !== request.cookies?.admin_csrf) throw new UnauthorizedException({ code: 'CSRF_INVALID', message: 'The CSRF token is invalid.' });
  }
  private sessionResponse(principal: { sub: string; roles: string[]; permissions: string[] }, displayName: string) {
    return { adminId: principal.sub, displayName, role: principal.roles[0] ?? 'ADMIN', permissions: principal.permissions, expiresAt: new Date(Date.now() + this.config.adminSessionTtlMinutes * 60_000).toISOString() };
  }
}
