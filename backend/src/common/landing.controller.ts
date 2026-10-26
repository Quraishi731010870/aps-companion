import { Controller, Get, VERSION_NEUTRAL } from '@nestjs/common';
import { ApiExcludeController } from '@nestjs/swagger';
import { Public } from '../auth/decorators/public.decorator';

@ApiExcludeController()
@Public()
@Controller({ version: VERSION_NEUTRAL })
export class LandingController {
  @Get()
  index() {
    return {
      success: true,
      service: 'Afghan EMI Backend API',
      status: 'ok',
      apiVersion: 'v1',
      endpoints: {
        health: '/health',
        swagger: '/api/docs',
        api: '/api/v1',
        adminPortal: 'http://localhost:8082',
        adminPortalLan: 'http://10.42.0.1:8082',
      },
    };
  }
}
