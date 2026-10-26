import { ArgumentsHost, Catch, ExceptionFilter, HttpException, HttpStatus } from '@nestjs/common';
import type { Request, Response } from 'express';

@Catch()
export class ApiExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost): void {
    const response = host.switchToHttp().getResponse<Response>();
    const request = host.switchToHttp().getRequest<Request>();
    const status = exception instanceof HttpException ? exception.getStatus() : HttpStatus.INTERNAL_SERVER_ERROR;
    const payload = exception instanceof HttpException ? exception.getResponse() : undefined;
    const message = this.messageFor(status, payload);
    const code = this.codeFor(status, payload);

    response.status(status).json({
      success: false,
      code,
      message,
      requestId: (request as Request & { requestId?: string }).requestId ?? response.getHeader('X-Request-Id') ?? 'unknown',
      timestamp: new Date().toISOString(),
    });
  }

  private messageFor(status: number, payload: string | object | undefined): string {
    if (status >= 500) return 'An internal service error occurred.';
    if (typeof payload === 'string') return payload;
    if (payload && 'message' in payload) {
      const message = (payload as { message: unknown }).message;
      return Array.isArray(message) ? message.join('; ') : String(message);
    }
    return 'The request could not be processed.';
  }

  private codeFor(status: number, payload: string | object | undefined): string {
    if (payload && typeof payload === 'object' && 'code' in payload) return String((payload as { code: unknown }).code);
    return `HTTP_${status}`;
  }
}
