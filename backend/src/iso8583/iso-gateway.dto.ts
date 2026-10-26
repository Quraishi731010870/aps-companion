import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsNotEmpty, IsObject, IsOptional, IsString, Length, Matches, MaxLength } from 'class-validator';

const sensitive = { writeOnly: true, description: 'Sensitive value: never logged or persisted.' } as const;
class AmountDto { @ApiProperty({ example: '100.00' }) @IsString() @Matches(/^\d{1,16}(\.\d{1,2})?$/) amount!: string; }
class CardDto { @ApiProperty({ example: '411111******1111', ...sensitive }) @IsString() @Matches(/^\d{12,19}$/) card!: string; }
class PanDto { @ApiProperty({ example: '411111******1111', ...sensitive }) @IsString() @Matches(/^\d{12,19}$/) pan!: string; }
class PinTrackDto {
  @ApiProperty({ example: 'ENCRYPTED_PIN_BLOCK', ...sensitive }) @IsString() @IsNotEmpty() @MaxLength(64) pin!: string;
  @ApiProperty({ example: 'ENCRYPTED_OR_TOKENIZED_TRACK2', ...sensitive }) @IsString() @IsNotEmpty() @MaxLength(128) track2!: string;
}
export class WalletToWalletRequest extends AmountDto {
  @ApiProperty({ example: 'WALLET-001' }) @IsString() @IsNotEmpty() @MaxLength(64) sourceWallet!: string;
  @ApiProperty({ example: 'WALLET-002' }) @IsString() @IsNotEmpty() @MaxLength(64) destWallet!: string;
  @ApiProperty({ example: 'AFN' }) @IsString() @Length(3, 3) currency!: string;
}
export class WalletToCardRequest extends AmountDto {
  @ApiProperty({ example: 'WALLET-001' }) @IsString() @IsNotEmpty() sourceWallet!: string;
  @ApiProperty({ example: 'CARD_TOKEN_DESTINATION', ...sensitive }) @IsString() @IsNotEmpty() destWallet!: string;
}
export class SavePaymentRequest extends AmountDto {
  @ApiProperty({ ...sensitive }) @IsString() @Matches(/^\d{12,19}$/) pan!: string;
  @ApiProperty({ example: 'BILL-001' }) @IsString() @IsNotEmpty() bill!: string;
  @ApiProperty({ ...sensitive }) @IsString() @Matches(/^\d{3,4}$/) cvv!: string;
  @ApiProperty({ example: '2912', ...sensitive }) @IsString() @Matches(/^\d{4}$/) expiryDate!: string;
  @ApiProperty({ ...sensitive }) @IsString() @Matches(/^\d{4,8}$/) otp!: string;
  @ApiProperty({ example: '123456' }) @IsString() @Length(6, 6) stan!: string;
  @ApiProperty({ example: '625912345678' }) @IsString() @Length(12, 12) rrn!: string;
}
export class PurchaseRequest extends AmountDto {
  @ApiProperty({ ...sensitive }) @IsString() @Matches(/^\d{12,19}$/) card!: string;
  @ApiProperty({ ...sensitive }) @IsString() @Matches(/^\d{3,4}$/) cvv!: string;
  @ApiProperty({ ...sensitive }) @IsString() @Matches(/^\d{4}$/) expiryDate!: string;
  @ApiProperty({ ...sensitive }) @IsString() @Matches(/^\d{4,8}$/) otp!: string;
  @ApiProperty({ example: '123456' }) @IsString() @Length(6, 6) stan!: string;
  @ApiProperty({ example: '625912345678' }) @IsString() @Length(12, 12) rrn!: string;
  @ApiProperty({ example: 'MERCHANT-001' }) @IsString() @IsNotEmpty() merchant!: string;
}
export class NamingInquiryRequest extends PanDto { @ApiProperty({ example: 'AFN' }) @IsString() @Length(3, 3) currency!: string; }
export class CashOutRequest extends CardDto {
  @ApiProperty({ ...sensitive }) @IsString() @Matches(/^\d{3,4}$/) cvv!: string;
  @ApiProperty({ ...sensitive }) @IsString() @Matches(/^\d{4}$/) expiryDate!: string;
  @ApiProperty({ example: '100.00' }) @IsString() @Matches(/^\d{1,16}(\.\d{1,2})?$/) amount!: string;
  @ApiProperty({ ...sensitive }) @IsString() @IsNotEmpty() track2!: string;
  @ApiProperty({ ...sensitive }) @IsString() @IsNotEmpty() pin!: string;
  @ApiProperty({ example: 'WALLET-001' }) @IsString() @IsNotEmpty() wallet!: string;
}
export class CashInRequest extends CardDto { @ApiProperty({ example: '100.00' }) @IsString() amount!: string; @ApiProperty() @IsString() @IsNotEmpty() wallet!: string; }
export class CardToWalletRequest extends CardDto {
  @ApiProperty({ ...sensitive }) @IsString() cvv!: string; @ApiProperty({ ...sensitive }) @IsString() expiryDate!: string;
  @ApiProperty() @IsString() @IsNotEmpty() wallet!: string; @ApiProperty({ example: '100.00' }) @IsString() amount!: string;
}
export class CardToCardRequest extends AmountDto {
  @ApiProperty({ ...sensitive }) @IsString() sourceCard!: string; @ApiProperty({ ...sensitive }) @IsString() destCard!: string;
  @ApiProperty({ ...sensitive }) @IsString() cvv!: string; @ApiProperty({ ...sensitive }) @IsString() expiryDate!: string;
  @ApiProperty({ ...sensitive }) @IsString() otp!: string; @ApiProperty() @IsString() rrn!: string;
  @ApiProperty({ default: false }) @IsBoolean() qr!: boolean;
}
export class BillInfoRequest { @ApiProperty() @IsString() @IsNotEmpty() billNo!: string; @ApiProperty({ ...sensitive }) @IsString() card!: string; }
export class BalanceInquiryRequest extends PanDto {
  @ApiProperty({ ...sensitive }) @IsString() cvv!: string; @ApiProperty({ ...sensitive }) @IsString() expiryDate!: string;
  @ApiProperty() @IsString() @Length(3, 3) currency!: string; @ApiProperty({ ...sensitive }) @IsString() pin!: string;
  @ApiProperty({ ...sensitive }) @IsString() track2!: string;
}
export class CustomIsoRequest {
  @ApiProperty({ ...sensitive }) @IsString() pan!: string; @ApiProperty() @IsString() processingCode!: string;
  @ApiProperty() @IsString() amount!: string; @ApiProperty() @IsString() stan!: string; @ApiProperty() @IsString() localDateTime!: string;
  @ApiPropertyOptional({ ...sensitive }) @IsOptional() @IsString() expiryDate?: string; @ApiProperty() @IsString() mcc!: string;
  @ApiProperty() @IsString() posEntryMode!: string; @ApiProperty() @IsString() acqInst!: string; @ApiProperty() @IsString() rrn!: string;
  @ApiProperty() @IsString() terminalId!: string; @ApiProperty() @IsString() merchantId!: string; @ApiProperty() @IsString() field43!: string;
  @ApiProperty({ type: 'object', additionalProperties: { type: 'string' } }) @IsObject() field48!: Record<string, string>;
  @ApiProperty() @IsString() currency!: string; @ApiProperty({ ...sensitive }) @IsString() pinBlock!: string;
}
export class CpRequest extends CardDto implements AmountDto, PinTrackDto {
  @ApiProperty() @IsString() amount!: string; @ApiProperty({ ...sensitive }) @IsString() track2!: string;
  @ApiProperty({ ...sensitive }) @IsString() pin!: string; @ApiProperty() @IsString() merchant!: string;
}
export class CpWalletToCardRequest extends WalletToCardRequest implements PinTrackDto { @ApiProperty({ ...sensitive }) @IsString() track2!: string; @ApiProperty({ ...sensitive }) @IsString() pin!: string; }
export class CpSavePaymentRequest extends PanDto implements AmountDto, PinTrackDto { @ApiProperty() @IsString() amount!: string; @ApiProperty() @IsString() bill!: string; @ApiProperty({ ...sensitive }) @IsString() track2!: string; @ApiProperty({ ...sensitive }) @IsString() pin!: string; }
export class CpPurchaseRequest extends CpRequest {}
export class CpNamingInquiryRequest extends NamingInquiryRequest {}
export class CpCashOutRequest extends CpRequest { @ApiProperty() @IsString() wallet!: string; }
export class CpCashInRequest extends CashInRequest implements PinTrackDto { @ApiProperty({ ...sensitive }) @IsString() track2!: string; @ApiProperty({ ...sensitive }) @IsString() pin!: string; }
export class CpCardToWalletRequest extends CpCashInRequest {}
export class CpCardToCardRequest extends AmountDto implements PinTrackDto {
  @ApiProperty({ ...sensitive }) @IsString() sourceCard!: string; @ApiProperty({ ...sensitive }) @IsString() destCard!: string;
  @ApiProperty({ ...sensitive }) @IsString() track2!: string; @ApiProperty({ ...sensitive }) @IsString() pin!: string; @ApiProperty() @IsBoolean() qr!: boolean;
}
export class CpBillInfoRequest extends BillInfoRequest implements PinTrackDto { @ApiProperty({ ...sensitive }) @IsString() track2!: string; @ApiProperty({ ...sensitive }) @IsString() pin!: string; }
export class CpBalanceInquiryRequest extends PanDto implements PinTrackDto { @ApiProperty() @IsString() currency!: string; @ApiProperty({ ...sensitive }) @IsString() track2!: string; @ApiProperty({ ...sensitive }) @IsString() pin!: string; }

export class IsoResponseDto {
  @ApiProperty() stan!: string; @ApiProperty() rrn!: string; @ApiProperty() responseCode!: string; @ApiProperty() responseDescription!: string;
  @ApiProperty({ type: 'object', additionalProperties: { type: 'string' } }) data!: Record<string, string>;
}
