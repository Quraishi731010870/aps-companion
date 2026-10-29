import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { AdminAuthController } from './admin-auth.controller';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { DeviceBindingService } from '../devices/device-binding.service';
import { DeviceSignatureGuard } from '../devices/device-signature.guard';
import { AuthGuard } from './guards/auth.guard';
import { PermissionsGuard } from './guards/permissions.guard';

@Module({
  controllers: [AuthController, AdminAuthController],
  providers: [AuthService, DeviceBindingService, { provide: APP_GUARD, useClass: AuthGuard }, { provide: APP_GUARD, useClass: DeviceSignatureGuard }, { provide: APP_GUARD, useClass: PermissionsGuard }],
  exports: [AuthService],
})
export class AuthModule {}
