/** E.164 as the database stores phone numbers (caregivers, supporters). */
export const E164 = /^\+[1-9][0-9]{6,14}$/;

/**
 * A phone number as the member typed it, in E.164, or null when it cannot
 * be one. Spaces, dots, hyphens and parentheses are dropped. A number with a
 * leading "+" keeps its own country code; one without is read as a North
 * American number: ten digits get "+1", eleven digits starting with 1 get
 * "+". Anything else, letters included, is null. The value is never logged.
 */
export function normalisePhone(input: string): string | null {
  const value = input.trim();
  if (value.length === 0 || value.length > 32) return null;
  if (!/^\+?[0-9 ().-]+$/.test(value)) return null;
  const digits = value.replace(/[^0-9]/g, "");
  let e164: string;
  if (value.startsWith("+")) e164 = `+${digits}`;
  else if (digits.length === 10) e164 = `+1${digits}`;
  else if (digits.length === 11 && digits.startsWith("1")) e164 = `+${digits}`;
  else return null;
  return E164.test(e164) ? e164 : null;
}
