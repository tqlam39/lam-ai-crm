/** The form uses billions; persisted monetary amounts always use integer VND. */
export function billionsToVnd(input: string): number | '' {
  if (!input || input === ',' || input === '.') return '';
  if (!/^\d{0,6}([.,]\d{0,9})?$/.test(input)) throw new Error('Giá không hợp lệ');
  const [whole = '', fraction = ''] = input.replace(',', '.').split('.');
  return Number(BigInt(whole || '0') * 1_000_000_000n + BigInt(fraction.padEnd(9, '0')));
}
export function vndToBillions(amount: number | '' | undefined): string {
  if (amount === '' || amount === undefined || amount === null) return '';
  return (amount / 1_000_000_000).toFixed(9).replace(/\.?0+$/, '').replace('.', ',') || '0';
}
