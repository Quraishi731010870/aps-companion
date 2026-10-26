import { Injectable } from '@nestjs/common';
import { AuditResult, Prisma } from '@prisma/client';
import { PrismaService } from '../database/prisma.service';

@Injectable()
export class AuditService {
  constructor(private readonly prisma: PrismaService) {}
  record(input: { actorId?: string; actorSnapshot: string; action: string; resource: string; resourceId?: string; oldValue?: unknown; newValue?: unknown; requestId: string; result?: AuditResult; ipAddress?: string; userAgent?: string }) {
    return this.prisma.auditLog.create({ data: { ...input, result: input.result ?? AuditResult.SUCCESS, oldValue: input.oldValue as Prisma.InputJsonValue | undefined, newValue: input.newValue as Prisma.InputJsonValue | undefined } });
  }
}
