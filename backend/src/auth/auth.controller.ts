import { Body, Controller, Get, Post, Req } from '@nestjs/common';
import { PrincipalType } from '@prisma/client';
import type { Request } from 'express';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import type { AuthenticatedRequest } from './auth.types';
import { AuthService } from './auth.service';
import { LoginDto, RefreshDto } from './dto/login.dto';
import { Public } from './decorators/public.decorator';

@ApiTags('authentication')
@Controller({ path: 'auth', version: '1' })
export class AuthController {
  constructor(private readonly auth: AuthService) {}
  /** Customers only; binds the device key sent in `device` (the request is signed with it). */
  @Public() @Post('login') login(@Body() dto: LoginDto, @Req() request: Request) { return this.auth.login(dto.identifier, dto.password, PrincipalType.MOBILE_USER, { binding: dto.device, request }); }
  @Public() @Post('refresh') refresh(@Body() dto: RefreshDto, @Req() request: Request) { return this.auth.refresh(dto.refreshToken, request); }
  @ApiBearerAuth() @Post('logout') async logout(@Req() request: AuthenticatedRequest) { await this.auth.logout(request.principal.sessionId); return { success: true }; }
  @ApiBearerAuth() @Get('me') me(@Req() request: AuthenticatedRequest) { return request.principal; }
}
