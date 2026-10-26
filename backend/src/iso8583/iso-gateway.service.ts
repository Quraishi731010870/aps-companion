import { BadGatewayException, GatewayTimeoutException, Injectable, ServiceUnavailableException } from '@nestjs/common';
import { RuntimeConfig } from '../configuration/runtime-config.service';

@Injectable()
export class IsoGatewayService {
  constructor(private readonly config: RuntimeConfig) {}

  async post(path: string, body?: object, query?: Record<string, string>) {
    if (!this.config.isoApiBaseUrl) throw new ServiceUnavailableException({ code: 'ISO_GATEWAY_NOT_CONFIGURED', message: 'Configure ISO_API_BASE_URL to enable processor requests.' });
    const url = new URL(path, `${this.config.isoApiBaseUrl}/`);
    for (const [key, value] of Object.entries(query ?? {})) url.searchParams.set(key, value);
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), this.config.isoApiTimeoutMs);
    try {
      const response = await fetch(url, { method: 'POST', headers: { 'content-type': 'application/json', accept: 'application/json' }, body: body ? JSON.stringify(body) : undefined, signal: controller.signal });
      const payload: unknown = await response.json().catch(() => undefined);
      if (!response.ok) throw new BadGatewayException({ code: 'ISO_PROCESSOR_REJECTED', message: 'The ISO processor rejected the request.', upstreamStatus: response.status });
      if (!payload || typeof payload !== 'object') throw new BadGatewayException({ code: 'ISO_PROCESSOR_RESPONSE_INVALID', message: 'The ISO processor returned an invalid response.' });
      return payload;
    } catch (error) {
      if (error instanceof BadGatewayException) throw error;
      if (error instanceof Error && error.name === 'AbortError') throw new GatewayTimeoutException({ code: 'ISO_PROCESSOR_TIMEOUT', message: 'The ISO processor did not respond in time.' });
      throw new BadGatewayException({ code: 'ISO_PROCESSOR_UNAVAILABLE', message: 'The ISO processor is unavailable.' });
    } finally { clearTimeout(timeout); }
  }
}
