import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import type { AuthenticatedRequest } from '../auth/auth.types';
import { IS_PUBLIC } from '../auth/decorators/public.decorator';
import { DeviceBindingService } from './device-binding.service';

/**
 * Runs after AuthGuard: every request from a mobile customer must be signed by
 * the device bound to its session. Admin (cookie) sessions are not device-bound.
 * Login and refresh are public and verify their signatures in AuthService.
 */
@Injectable()
export class DeviceSignatureGuard implements CanActivate {
  constructor(private readonly reflector: Reflector, private readonly devices: DeviceBindingService) {}
  async canActivate(context: ExecutionContext): Promise<boolean> {
    if (this.reflector.getAllAndOverride<boolean>(IS_PUBLIC, [context.getHandler(), context.getClass()])) return true;
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    if (request.principal?.type !== 'MOBILE_USER') return true;
    Object.assign(request, { device: await this.devices.verifyForSession(request.principal.sessionId, request) });
    return true;
  }
}
