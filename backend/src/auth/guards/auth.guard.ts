import { CanActivate, ExecutionContext, ForbiddenException, Injectable, UnauthorizedException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import type { Request } from 'express';
import { AuthService } from '../auth.service';
import { IS_PUBLIC } from '../decorators/public.decorator';

@Injectable()
export class AuthGuard implements CanActivate {
  constructor(private readonly reflector: Reflector, private readonly auth: AuthService) {}
  async canActivate(context: ExecutionContext): Promise<boolean> {
    if (this.reflector.getAllAndOverride<boolean>(IS_PUBLIC, [context.getHandler(), context.getClass()])) return true;
    const request = context.switchToHttp().getRequest<Request>();
    const bearer = request.header('authorization')?.match(/^Bearer (.+)$/i)?.[1];
    const cookie = (request.cookies?.['__Host-admin_session'] ?? request.cookies?.admin_session) as string | undefined;
    const token = bearer ?? cookie;
    if (!token) throw new UnauthorizedException({ code: 'AUTH_REQUIRED', message: 'Authentication is required.' });
    Object.assign(request, { principal: await this.auth.authenticateAccess(token) });
    if (cookie && !['GET', 'HEAD', 'OPTIONS'].includes(request.method)) {
      const csrfHeader = request.header('x-csrf-token');
      if (!csrfHeader || csrfHeader !== request.cookies?.admin_csrf) throw new ForbiddenException({ code: 'CSRF_INVALID', message: 'The CSRF token is invalid.' });
    }
    return true;
  }
}
