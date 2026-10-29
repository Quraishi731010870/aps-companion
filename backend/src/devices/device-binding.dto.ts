import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsOptional, IsString, Matches, MaxLength } from 'class-validator';

export const DEVICE_PLATFORMS = ['ANDROID', 'IOS', 'WEB'] as const;

/** Sent with mobile login so the server can bind this installation's Ed25519 key to the customer. */
export class DeviceBindingDto {
  @ApiProperty() @IsString() @Matches(/^[A-Za-z0-9_-]{16,128}$/) installationId!: string;
  @ApiProperty({ enum: DEVICE_PLATFORMS }) @IsIn(DEVICE_PLATFORMS) platform!: (typeof DEVICE_PLATFORMS)[number];
  @ApiProperty({ description: 'Raw Ed25519 public key, base64url (32 bytes).' }) @IsString() @Matches(/^[A-Za-z0-9_-]{43}$/) publicKey!: string;
  @ApiPropertyOptional() @IsOptional() @IsString() @MaxLength(160) name?: string;
}
