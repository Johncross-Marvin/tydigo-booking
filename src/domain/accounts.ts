export const accountTypes = ['household', 'estate', 'business'] as const;
export type AccountType = typeof accountTypes[number];
export type Account = { auth_user_id: string; account_type: AccountType; display_name: string; status: 'active' | 'suspended' | 'closed'; verification_status: 'not_started' | 'submitted' | 'under_review' | 'corrections_required' | 'approved' | 'rejected' };
export function isAccountType(value: unknown): value is AccountType {
  return typeof value === 'string' && accountTypes.includes(value as AccountType);
}
export function resolveAccount(value: unknown, authUserId: string): Account {
  const row = value as Account | null;
  if (!row || row.auth_user_id !== authUserId || !isAccountType(row.account_type)) throw new Error('Your account could not be securely resolved. Please contact support.');
  if (row.status !== 'active') throw new Error('This account is unavailable. Please contact support.');
  if (!['not_started','submitted','under_review','corrections_required','approved','rejected'].includes(row.verification_status)) throw new Error('Verification status could not be resolved.');
  return row;
}
export function canTransact(account: Account): boolean { return account.status === 'active' && account.verification_status === 'approved'; }

