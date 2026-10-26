import { BadRequestException, Injectable } from '@nestjs/common';

export type IsoFields = Record<number, string>;

const fieldRules: Record<number, { length: number; numeric: boolean }> = {
  3: { length: 6, numeric: true },
  4: { length: 12, numeric: true },
  7: { length: 10, numeric: true },
  11: { length: 6, numeric: true },
  37: { length: 12, numeric: false },
  39: { length: 2, numeric: true },
  41: { length: 8, numeric: false },
  42: { length: 15, numeric: false },
  49: { length: 3, numeric: true },
};

@Injectable()
export class Iso8583Service {
  validate(mti: string, fields: IsoFields) {
    if (!/^0[128][012]0$/.test(mti)) {
      throw new BadRequestException({ code: 'ISO8583_MTI_INVALID', message: 'Unsupported ISO 8583 MTI.' });
    }
    const entries = Object.entries(fields).map(([field, value]) => [Number(field), value] as const);
    if (!entries.length) throw new BadRequestException({ code: 'ISO8583_FIELDS_REQUIRED', message: 'At least one data element is required.' });
    for (const [field, value] of entries) {
      const rule = fieldRules[field];
      if (!rule) throw new BadRequestException({ code: 'ISO8583_FIELD_UNSUPPORTED', message: `DE ${field} is not supported by the safe development profile.` });
      if (value.length !== rule.length || (rule.numeric && !/^\d+$/.test(value))) {
        throw new BadRequestException({ code: 'ISO8583_FIELD_INVALID', message: `DE ${field} must be ${rule.length} ${rule.numeric ? 'numeric' : 'alphanumeric'} characters.` });
      }
    }
    return { mti, bitmap: this.bitmap(entries.map(([field]) => field)), fields };
  }

  responseMti(requestMti: string): string {
    const mapping: Record<string, string> = { '0100': '0110', '0200': '0210', '0400': '0410', '0420': '0430', '0800': '0810' };
    const response = mapping[requestMti];
    if (!response) throw new BadRequestException({ code: 'ISO8583_MTI_UNSUPPORTED', message: 'No response MTI is configured for this request.' });
    return response;
  }

  private bitmap(fields: number[]): string {
    let bitmap = 0n;
    for (const field of fields) {
      if (field < 1 || field > 64) throw new BadRequestException({ code: 'ISO8583_BITMAP_FIELD_INVALID', message: 'Only primary bitmap fields 1-64 are supported.' });
      bitmap |= 1n << BigInt(64 - field);
    }
    return bitmap.toString(16).padStart(16, '0').toUpperCase();
  }
}
