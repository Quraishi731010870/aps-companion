import { Body, Controller, Get, Post, Req } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import type { AuthenticatedRequest } from './auth.types';
import { AuthService } from './auth.service';
import { LoginDto, RefreshDto } from './dto/login.dto';
import { Public } from './decorators/public.decorator';

@ApiTags('authentication')
@Controller({ path: 'auth', version: '1' })
export class AuthController {
  constructor(private readonly auth: AuthService) {}
  @Public() @Post('login') login(@Body() dto: LoginDto) { return this.auth.login(dto.identifier, dto.password); }
  @Public() @Post('refresh') refresh(@Body() dto: RefreshDto) { return this.auth.refresh(dto.refreshToken); }
  @ApiBearerAuth() @Post('logout') async logout(@Req() request: AuthenticatedRequest) { await this.auth.logout(request.principal.sessionId); return { success: true }; }
  @ApiBearerAuth() @Get('me') me(@Req() request: AuthenticatedRequest) { return request.principal; }
}
