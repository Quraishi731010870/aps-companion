import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsDefined, IsNotEmpty, IsString, Matches, MaxLength, MinLength, ValidateNested } from 'class-validator';
import { DeviceBindingDto } from '../../devices/device-binding.dto';

export class LoginDto {
  @ApiProperty() @IsString() @IsNotEmpty() @MaxLength(254) identifier!: string;
  @ApiProperty({ writeOnly: true }) @IsString() @MinLength(8) @MaxLength(200) password!: string;
  @ApiProperty({ type: DeviceBindingDto }) @IsDefined() @ValidateNested() @Type(() => DeviceBindingDto) device!: DeviceBindingDto;
}

/** Self sign-up for a customer; the request is signed with the key in `device`, like login. */
export class RegisterDto {
  @ApiProperty() @IsString() @MinLength(2) @MaxLength(120) displayName!: string;
  @ApiProperty({ example: '+93701234567' }) @Matches(/^\+937\d{8}$/, { message: 'phone must be an Afghan mobile number in the form +937XXXXXXXX' }) phone!: string;
  @ApiProperty({ writeOnly: true }) @IsString() @MinLength(10) @MaxLength(200) password!: string;
  @ApiProperty({ type: DeviceBindingDto }) @IsDefined() @ValidateNested() @Type(() => DeviceBindingDto) device!: DeviceBindingDto;
}

export class AdminLoginDto {
  @ApiProperty() @IsString() @IsNotEmpty() @MaxLength(254) operator!: string;
  @ApiProperty({ writeOnly: true }) @IsString() @MinLength(8) @MaxLength(200) password!: string;
}

export class RefreshDto {
  @ApiProperty({ writeOnly: true }) @IsString() @IsNotEmpty() refreshToken!: string;
}
