import { Equals, IsInt, IsString, Matches, MaxLength } from 'class-validator';
import { ENVELOPE_VERSION } from './card-envelope';

const BASE64URL = /^[A-Za-z0-9_-]+$/;

/** Shape-only validation; decryption in CardCryptoService checks the rest. */
export class CardEnvelopeDto {
  @IsInt() @Equals(ENVELOPE_VERSION) v!: number;
  @IsString() @MaxLength(64) @Matches(BASE64URL) kid!: string;
  @IsString() @MaxLength(1024) @Matches(BASE64URL) ek!: string;
  @IsString() @MaxLength(32) @Matches(BASE64URL) iv!: string;
  @IsString() @MaxLength(1024) @Matches(BASE64URL) ct!: string;
}
