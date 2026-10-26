import { BadRequestException } from '@nestjs/common';
import { Iso8583Service } from './iso8583.service';

describe('Iso8583Service', () => {
  const service = new Iso8583Service();
  it('builds the primary bitmap for a financial request', () => {
    expect(service.validate('0200', { 3: '000000', 4: '000000001000', 7: '0929123456', 11: '123456', 41: 'AFGHAN01', 42: 'EMIMERCHANT0001', 49: '971' }).bitmap).toBe('3220000000C08000');
  });
  it('rejects unsafe or unsupported fields', () => {
    expect(() => service.validate('0200', { 2: '4111111111111111' })).toThrow(BadRequestException);
  });
  it('maps request MTIs to response MTIs', () => expect(service.responseMti('0200')).toBe('0210'));
});
