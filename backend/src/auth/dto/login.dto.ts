import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsDefined, IsNotEmpty, IsString, MaxLength, MinLength, ValidateNested } from 'class-validator';
import { DeviceBindingDto } from '../../devices/device-binding.dto';

export class LoginDto {
  @ApiProperty() @IsString() @IsNotEmpty() @MaxLength(254) identifier!: string;
  @ApiProperty({ writeOnly: true }) @IsString() @MinLength(8) @MaxLength(200) password!: string;
  @ApiProperty({ type: DeviceBindingDto }) @IsDefined() @ValidateNested() @Type(() => DeviceBindingDto) device!: DeviceBindingDto;
}

export class AdminLoginDto {
  @ApiProperty() @IsString() @IsNotEmpty() @MaxLength(254) operator!: string;
  @ApiProperty({ writeOnly: true }) @IsString() @MinLength(8) @MaxLength(200) password!: string;
}

export class RefreshDto {
  @ApiProperty({ writeOnly: true }) @IsString() @IsNotEmpty() refreshToken!: string;
}
