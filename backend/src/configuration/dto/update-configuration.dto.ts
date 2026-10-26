import { ApiProperty } from '@nestjs/swagger';
import { IsBoolean, IsObject, IsOptional, IsString, MaxLength } from 'class-validator';

export class UpdateConfigurationDto { @ApiProperty({ type: 'object', additionalProperties: true }) @IsObject() value!: Record<string, unknown>; @IsOptional() @IsString() @MaxLength(500) description?: string; }
export class UpdateFeatureDto { @IsBoolean() enabled!: boolean; @IsOptional() @IsObject() configuration?: Record<string, unknown>; @IsOptional() @IsString() @MaxLength(32) minimumVersion?: string; }
