import { test } from 'node:test';
import { readFile } from 'node:fs/promises';
import { PGlite } from '@electric-sql/pglite';

test('isolated PostgreSQL account and operations contracts', async () => {
 const db = new PGlite();
 try {
  for (const file of [
   'tests/bootstrap.sql',
   'migrations/20261118160542_booking_foundation.sql',
   'migrations/20261118212826_booking_operations.sql',
   'migrations/20261118214241_harden_booking_rpcs.sql',
   'migrations/20261118214613_booking_outcome_evidence.sql',
   'tests/account_security.sql',
   'tests/booking_operations.sql',
  ]) {
   try {
    await db.exec(await readFile(new URL('../supabase/'+file, import.meta.url), 'utf8'));
   } catch (error) {
    throw new Error('SQL suite failed in '+file, { cause: error });
   }
  }
 } finally {
  await db.close();
 }
});
