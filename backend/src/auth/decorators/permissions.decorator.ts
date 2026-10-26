import { SetMetadata } from '@nestjs/common';
export const REQUIRED_PERMISSIONS = 'requiredPermissions';
export const Permissions = (...permissions: string[]) => SetMetadata(REQUIRED_PERMISSIONS, permissions);
