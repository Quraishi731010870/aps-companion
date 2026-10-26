import { Injectable, Logger, NestMiddleware } from '@nestjs/common';
import type { NextFunction, Request, Response } from 'express';
import { randomUUID } from 'node:crypto';

@Injectable()
export class RequestContextMiddleware implements NestMiddleware {
  private readonly logger = new Logger('HTTP');

  use(request: Request, response: Response, next: NextFunction): void {
    const supplied = request.header('x-request-id');
    const requestId = supplied && supplied.length <= 128 ? supplied : randomUUID();
    const started = Date.now();
    response.setHeader('X-Request-Id', requestId);
    Object.assign(request, { requestId });
    response.on('finish', () => this.logger.log(JSON.stringify({
      requestId,
      method: request.method,
      path: request.originalUrl.split('?')[0],
      status: response.statusCode,
      durationMs: Date.now() - started,
    })));
    next();
  }
}
