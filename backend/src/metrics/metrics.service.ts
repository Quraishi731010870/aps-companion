import { Injectable } from '@nestjs/common';
import { TransactionStatus } from '@prisma/client';
import { Counter, Gauge, Histogram, Registry, collectDefaultMetrics } from 'prom-client';
import { PrismaService } from '../database/prisma.service';

@Injectable()
export class MetricsService {
  readonly registry = new Registry();
  private readonly transactions = new Gauge({ name: 'afghanpay_transactions_total_by_status', help: 'Persisted transaction count by status', labelNames: ['status'], registers: [this.registry] });
  private readonly amount = new Gauge({ name: 'afghanpay_transaction_amount_total', help: 'Persisted transaction amount by currency and status', labelNames: ['currency', 'status'], registers: [this.registry] });
  readonly httpRequests = new Counter({ name: 'afghanpay_http_requests_total', help: 'HTTP requests', labelNames: ['method', 'route', 'status'], registers: [this.registry] });
  readonly httpDuration = new Histogram({ name: 'afghanpay_http_request_duration_seconds', help: 'HTTP request duration', labelNames: ['method', 'route'], buckets: [0.01, 0.05, 0.1, 0.25, 0.5, 1, 2, 5], registers: [this.registry] });
  constructor(private readonly prisma: PrismaService) { collectDefaultMetrics({ register: this.registry, prefix: 'afghanpay_process_' }); }
  async render(): Promise<string> {
    const [statuses, amounts] = await Promise.all([this.prisma.transaction.groupBy({ by: ['status'], _count: true }), this.prisma.transaction.groupBy({ by: ['currency', 'status'], _sum: { amount: true } })]);
    this.transactions.reset(); this.amount.reset();
    for (const status of Object.values(TransactionStatus)) this.transactions.set({ status }, statuses.find((row) => row.status === status)?._count ?? 0);
    for (const row of amounts) this.amount.set({ currency: row.currency, status: row.status }, Number(row._sum.amount ?? 0));
    return this.registry.metrics();
  }
}
