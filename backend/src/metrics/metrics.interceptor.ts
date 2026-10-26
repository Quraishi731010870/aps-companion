import { CallHandler, ExecutionContext, Injectable, NestInterceptor } from '@nestjs/common';
import type { Observable } from 'rxjs';
import { finalize } from 'rxjs/operators';
import type { Request, Response } from 'express';
import { MetricsService } from './metrics.service';

@Injectable()
export class MetricsInterceptor implements NestInterceptor {
  constructor(private readonly metrics: MetricsService) {}
  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    if (context.getType() !== 'http') return next.handle();
    const request = context.switchToHttp().getRequest<Request>();
    const response = context.switchToHttp().getResponse<Response>();
    const route = request.route?.path ? `${request.baseUrl}${request.route.path}` : request.path;
    const end = this.metrics.httpDuration.startTimer({ method: request.method, route });
    return next.handle().pipe(finalize(() => { end(); this.metrics.httpRequests.inc({ method: request.method, route, status: String(response.statusCode) }); }));
  }
}
