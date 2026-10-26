import { Body, Controller, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiOperation, ApiTags } from '@nestjs/swagger';
import { IsString, Length } from 'class-validator';
import { Permissions } from '../auth/decorators/permissions.decorator';
import { BalanceInquiryRequest, BillInfoRequest, CardToCardRequest, CardToWalletRequest, CashInRequest, CashOutRequest, CpBalanceInquiryRequest, CpBillInfoRequest, CpCardToCardRequest, CpCardToWalletRequest, CpCashInRequest, CpCashOutRequest, CpNamingInquiryRequest, CpPurchaseRequest, CpRequest, CpSavePaymentRequest, CpWalletToCardRequest, CustomIsoRequest, IsoResponseDto, NamingInquiryRequest, PurchaseRequest, SavePaymentRequest, WalletToCardRequest, WalletToWalletRequest } from './iso-gateway.dto';
import { IsoGatewayService } from './iso-gateway.service';

class ReversalQuery { @IsString() @Length(12, 32) rrn!: string; }

@ApiTags('ISO 8583') @ApiBearerAuth() @Permissions('transactions.view') @Controller({ path: 'iso', version: '1' })
export class IsoGatewayController {
  constructor(private readonly gateway: IsoGatewayService) {}
  @Post('walletToWallet') @ApiOperation({ summary: 'Wallet to wallet' }) @ApiOkResponse({ type: IsoResponseDto }) walletToWallet(@Body() body: WalletToWalletRequest) { return this.gateway.post('api/iso/walletToWallet', body); }
  @Post('walletToCard') @ApiOperation({ summary: 'Wallet to card' }) @ApiOkResponse({ type: IsoResponseDto }) walletToCard(@Body() body: WalletToCardRequest) { return this.gateway.post('api/iso/walletToCard', body); }
  @Post('savePayment') @ApiOperation({ summary: 'Save payment' }) @ApiOkResponse({ type: IsoResponseDto }) savePayment(@Body() body: SavePaymentRequest) { return this.gateway.post('api/iso/savePayment', body); }
  @Post('request') @ApiOperation({ summary: 'Custom ISO request' }) @ApiOkResponse({ type: IsoResponseDto }) request(@Body() body: CustomIsoRequest) { return this.gateway.post('api/iso/request', body); }
  @Post('purchase') @ApiOperation({ summary: 'Purchase' }) @ApiOkResponse({ type: IsoResponseDto }) purchase(@Body() body: PurchaseRequest) { return this.gateway.post('api/iso/purchase', body); }
  @Post('ni') @ApiOperation({ summary: 'Naming inquiry' }) @ApiOkResponse({ type: IsoResponseDto }) ni(@Body() body: NamingInquiryRequest) { return this.gateway.post('api/iso/ni', body); }
  @Post('cash-out') @ApiOperation({ summary: 'Cash out' }) @ApiOkResponse({ type: IsoResponseDto }) cashOut(@Body() body: CashOutRequest) { return this.gateway.post('api/iso/cash-out', body); }
  @Post('cash-in') @ApiOperation({ summary: 'Cash in' }) @ApiOkResponse({ type: IsoResponseDto }) cashIn(@Body() body: CashInRequest) { return this.gateway.post('api/iso/cash-in', body); }
  @Post('cardToWallet') @ApiOperation({ summary: 'Card to wallet' }) @ApiOkResponse({ type: IsoResponseDto }) cardToWallet(@Body() body: CardToWalletRequest) { return this.gateway.post('api/iso/cardToWallet', body); }
  @Post('cardToCard') @ApiOperation({ summary: 'Card to card' }) @ApiOkResponse({ type: IsoResponseDto }) cardToCard(@Body() body: CardToCardRequest) { return this.gateway.post('api/iso/cardToCard', body); }
  @Post('billInfo') @ApiOperation({ summary: 'Bill information' }) @ApiOkResponse({ type: IsoResponseDto }) billInfo(@Body() body: BillInfoRequest) { return this.gateway.post('api/iso/billInfo', body); }
  @Post('balance') @ApiOperation({ summary: 'Balance inquiry' }) @ApiOkResponse({ type: IsoResponseDto }) balance(@Body() body: BalanceInquiryRequest) { return this.gateway.post('api/iso/balance', body); }
}

@ApiTags('ISO CP') @ApiBearerAuth() @Permissions('transactions.view') @Controller({ path: 'iso/cp', version: '1' })
export class IsoCpGatewayController {
  constructor(private readonly gateway: IsoGatewayService) {}
  @Post() @ApiOperation({ summary: 'Card payment' }) @ApiOkResponse({ type: IsoResponseDto }) cp(@Body() body: CpRequest) { return this.gateway.post('api/iso/cp', body); }
  @Post('walletToCard') @ApiOperation({ summary: 'CP wallet to card' }) @ApiOkResponse({ type: IsoResponseDto }) walletToCard(@Body() body: CpWalletToCardRequest) { return this.gateway.post('api/iso/cp/walletToCard', body); }
  @Post('savePayment') @ApiOperation({ summary: 'CP save payment' }) @ApiOkResponse({ type: IsoResponseDto }) savePayment(@Body() body: CpSavePaymentRequest) { return this.gateway.post('api/iso/cp/savePayment', body); }
  @Post('purchase') @ApiOperation({ summary: 'CP purchase' }) @ApiOkResponse({ type: IsoResponseDto }) purchase(@Body() body: CpPurchaseRequest) { return this.gateway.post('api/iso/cp/purchase', body); }
  @Post('ni') @ApiOperation({ summary: 'CP naming inquiry' }) @ApiOkResponse({ type: IsoResponseDto }) ni(@Body() body: CpNamingInquiryRequest) { return this.gateway.post('api/iso/cp/ni', body); }
  @Post('cash-out') @ApiOperation({ summary: 'CP cash out' }) @ApiOkResponse({ type: IsoResponseDto }) cashOut(@Body() body: CpCashOutRequest) { return this.gateway.post('api/iso/cp/cash-out', body); }
  @Post('cash-in') @ApiOperation({ summary: 'CP cash in' }) @ApiOkResponse({ type: IsoResponseDto }) cashIn(@Body() body: CpCashInRequest) { return this.gateway.post('api/iso/cp/cash-in', body); }
  @Post('cardToWallet') @ApiOperation({ summary: 'CP card to wallet' }) @ApiOkResponse({ type: IsoResponseDto }) cardToWallet(@Body() body: CpCardToWalletRequest) { return this.gateway.post('api/iso/cp/cardToWallet', body); }
  @Post('cardToCard') @ApiOperation({ summary: 'CP card to card' }) @ApiOkResponse({ type: IsoResponseDto }) cardToCard(@Body() body: CpCardToCardRequest) { return this.gateway.post('api/iso/cp/cardToCard', body); }
  @Post('billInfo') @ApiOperation({ summary: 'CP bill information' }) @ApiOkResponse({ type: IsoResponseDto }) billInfo(@Body() body: CpBillInfoRequest) { return this.gateway.post('api/iso/cp/billInfo', body); }
  @Post('balance') @ApiOperation({ summary: 'CP balance inquiry' }) @ApiOkResponse({ type: IsoResponseDto }) balance(@Body() body: CpBalanceInquiryRequest) { return this.gateway.post('api/iso/cp/balance', body); }
}

@ApiTags('ISO Reversal') @ApiBearerAuth() @Controller({ path: 'iso/reversal', version: '1' })
export class IsoReversalGatewayController {
  constructor(private readonly gateway: IsoGatewayService) {}
  @Post() @ApiOperation({ summary: 'Submit reversal (MTI 1420)' }) @Permissions('transactions.reverse') @ApiOkResponse({ type: IsoResponseDto }) reversal(@Query() query: ReversalQuery) { return this.gateway.post('api/iso/reversal', undefined, { rrn: query.rrn }); }
  @Post('repeat') @ApiOperation({ summary: 'Repeat reversal (MTI 1421)' }) @Permissions('transactions.reverse') @ApiOkResponse({ type: IsoResponseDto }) repeat(@Query() query: ReversalQuery) { return this.gateway.post('api/iso/reversal/repeat', undefined, { rrn: query.rrn }); }
}
