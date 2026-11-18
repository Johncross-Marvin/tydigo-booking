# Local validation — 2026-11-18

- pnpm check: passed after excluding the Node test runner files from the application TypeScript build.
- pnpm test: 6 tests passed, 0 failed. Tests exercise all three account categories, no transaction eligibility before approval, missing accounts, mismatched UUIDs, unsupported roles, suspension and invalid verification states.
- pnpm exec expo export --platform web: passed.

The six Node tests are isolated policy tests. Separate live SQL checks validate the database controls described below. Email delivery, session revocation, KYC upload/review and payments still require end-to-end tests.

Hosted backend migration: applied atomically to auplmtypaptzxjqeqhhf.
Live SQL: supabase/tests/account_security.sql passed via Management API. Canonical creation for all three categories, unsupported category rejection, owner isolation, category mutation denial, unapproved booking denial, nonstaff review denial, metadata spoof resistance and public RLS passed. All fixtures rolled back; follow-up confirmed zero Auth users and customer accounts.
Android/iOS JavaScript bundle exports and Expo dependency compatibility: passed. These are not native APK/IPA builds.
Local database tests: unavailable; Docker and psql were not found on PATH.
Native device interaction and APK/IPA builds: not performed for this new app.

Required next integration matrix: all three real test registrations and confirmed logins; canonical role mutation denied; metadata spoofing denied; cross-owner reads denied; all review states; owner-only document upload/read; nonstaff and non-MFA review denied; sign-out/restart/back navigation; network errors; stale asynchronous requests after logout. Use an isolated backend and synthetic documents, never real identity documents.
