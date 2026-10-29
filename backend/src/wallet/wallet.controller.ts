import { Controller, ForbiddenException, Get, NotFoundException, Req } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AccountStatus } from '@prisma/client';
import type { AuthenticatedRequest } from '../auth/auth.types';
import { PrismaService } from '../database/prisma.service';

/** The signed-in customer's own wallet: identifier and balance. */
@ApiTags('wallet') @ApiBearerAuth() @Controller({ path: 'wallet', version: '1' })
export class WalletController {
  constructor(private readonly prisma: PrismaService) {}
  @Get() async current(@Req() request: AuthenticatedRequest) {
    if (request.principal.type !== 'MOBILE_USER') throw new ForbiddenException({ code: 'PERMISSION_DENIED', message: 'Only customers have a wallet.' });
    const account = await this.prisma.account.findFirst({
      where: { type: 'WALLET', status: AccountStatus.ACTIVE, customer: { userId: request.principal.sub } },
      orderBy: { createdAt: 'asc' },
      select: { accountNo: true, currency: true, availableBalance: true },
    });
    if (!account) throw new NotFoundException({ code: 'WALLET_NOT_FOUND', message: 'No wallet is available for this account.' });
    return { walletId: account.accountNo, currency: account.currency, availableBalance: Number(account.availableBalance) };
  }
}
