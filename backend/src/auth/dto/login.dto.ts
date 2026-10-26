import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, MaxLength, MinLength } from 'class-validator';

export class LoginDto {
  @ApiProperty() @IsString() @IsNotEmpty() @MaxLength(254) identifier!: string;
  @ApiProperty({ writeOnly: true }) @IsString() @MinLength(8) @MaxLength(200) password!: string;
}

export class AdminLoginDto {
  @ApiProperty() @IsString() @IsNotEmpty() @MaxLength(254) operator!: string;
  @ApiProperty({ writeOnly: true }) @IsString() @MinLength(8) @MaxLength(200) password!: string;
}

export class RefreshDto {
  @ApiProperty({ writeOnly: true }) @IsString() @IsNotEmpty() refreshToken!: string;
}
