/** Mirrors PaymentOperation in Flutter's lib/src/domain/payment_transaction.dart. */
export const transactionTypes = [
  { code: '702', label: 'Balance Inquiry' },
  { code: '651', label: 'Name Inquiry' },
  { code: '785', label: 'W2C · Bank Push' },
  { code: '781', label: 'C2W · Bank Pull' },
  { code: '689', label: 'P2P · Card to Card' },
  { code: '774', label: 'Purchase' },
  { code: '511', label: 'Bill Info' },
  { code: '512', label: 'Bill Payment' },
  { code: '508', label: 'Save Payment' },
  { code: '618', label: 'Cash-In' },
  { code: '700', label: 'Cash-Out' },
] as const

export type TransactionTypeCode = typeof transactionTypes[number]['code']
