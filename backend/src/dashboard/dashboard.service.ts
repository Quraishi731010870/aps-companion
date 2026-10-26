import { Injectable } from '@nestjs/common';
import { AccountStatus, TransactionStatus } from '@prisma/client';
import { PrismaService } from '../database/prisma.service';

@Injectable()
export class DashboardService {
  constructor(private readonly prisma: PrismaService) {}
  async summary() {
    const [usersTotal, usersActive, customersTotal, customersActive, transactionsTotal, grouped, amount, latest, trend, monitoredServices] = await Promise.all([
      this.prisma.user.count(), this.prisma.user.count({ where: { status: AccountStatus.ACTIVE } }),
      this.prisma.customer.count(), this.prisma.customer.count({ where: { status: AccountStatus.ACTIVE } }),
      this.prisma.transaction.count(), this.prisma.transaction.groupBy({ by: ['status'], _count: true }),
      this.prisma.transaction.aggregate({ _sum: { amount: true } }),
      this.prisma.transaction.findMany({ take: 10, orderBy: { createdAt: 'desc' }, include: { transactionType: true, customer: { include: { user: true } } } }),
      this.prisma.$queryRaw<Array<{ bucket: Date; count: bigint }>>`SELECT date_trunc('day', created_at) AS bucket, count(*) AS count FROM transactions WHERE created_at >= now() - interval '14 days' GROUP BY 1 ORDER BY 1`,
      this.prisma.monitoringService.findMany({ where: { enabled: true }, include: { checks: { take: 1, orderBy: { checkedAt: 'desc' } } } }),
    ]);
    const count = (status: TransactionStatus) => grouped.find((row) => row.status === status)?._count ?? 0;
    const successful = count(TransactionStatus.SUCCESS);
    const recentActivity = latest.map((item) => ({ id: item.transactionId, type: item.transactionType.name, customer: item.customer?.user.displayName, amount: item.amount.toString(), currency: item.currency, status: item.status, createdAt: item.createdAt }));
    return { usersTotal, usersActive, customersTotal, customersActive, transactionsTotal, successfulTransactions: successful, failedTransactions: count(TransactionStatus.FAILED), pendingTransactions: count(TransactionStatus.PENDING) + count(TransactionStatus.PROCESSING), reversedTransactions: count(TransactionStatus.REVERSED), successRate: transactionsTotal ? Number(((successful / transactionsTotal) * 100).toFixed(2)) : 0, transactionAmount: amount._sum.amount?.toString() ?? '0', trend: trend.map(row => ({ label: row.bucket.toISOString().slice(0, 10), value: Number(row.count) })), services: monitoredServices.map(service => ({ name: service.name, status: service.checks[0]?.status?.toLowerCase() ?? 'unavailable' })), recentTransactions: recentActivity, recentActivity };
  }
  async stats() {
    const byStatus = await this.prisma.transaction.groupBy({ by: ['status'], _count: true, _sum: { amount: true } });
    const byCurrency = await this.prisma.transaction.groupBy({ by: ['currency'], _count: true, _sum: { amount: true } });
    const byType = await this.prisma.transaction.groupBy({ by: ['transactionTypeId'], _count: true, _sum: { amount: true } });
    const types = await this.prisma.transactionType.findMany();
    const overTime = await this.prisma.$queryRaw<Array<{ bucket: Date; count: bigint; amount: string }>>`SELECT date_trunc('day', created_at) AS bucket, count(*) AS count, coalesce(sum(amount),0)::text AS amount FROM transactions WHERE created_at >= now() - interval '30 days' GROUP BY 1 ORDER BY 1`;
    return { byStatus: byStatus.map((row) => ({ status: row.status, count: row._count, amount: row._sum.amount?.toString() ?? '0' })), byCurrency: byCurrency.map((row) => ({ currency: row.currency, count: row._count, amount: row._sum.amount?.toString() ?? '0' })), byType: byType.map((row) => ({ type: types.find((type) => type.id === row.transactionTypeId)?.name ?? 'Unknown', count: row._count, amount: row._sum.amount?.toString() ?? '0' })), overTime: overTime.map((row) => ({ date: row.bucket, count: Number(row.count), amount: row.amount })) };
  }
}
