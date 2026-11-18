# Deployment and legacy migration
The migration was applied atomically through the Management API to dedicated project auplmtypaptzxjqeqhhf after verifying an empty public schema, zero Auth users and no storage buckets or custom signup triggers. Do not apply it to the old project. CLI linkage is not configured.

Before rollout:
1. Select/create the dedicated project in the authorized organization and region.
2. Inspect the empty live schema; apply versioned migration and run SQL/RLS security tests in isolation.
3. Enable hosted email confirmation, secure SMTP, redirect allowlist, password policy and signup abuse controls.
4. Configure approved document requirements, service coverage, waste eligibility and pricing. Seed no invented operational records.
5. Provision staff through an audited server-only process and require MFA.
6. Supply server-side Paystack sandbox credentials; implement and test payment endpoints before enabling checkout.
7. Exercise genuine signup, email confirmation, account restoration, upload, review and sign-out on Android and iOS.

Legacy migration requires a separate inventory and approval. Join legacy identities by Auth UUID and authoritative registration evidence. Do not map legacy corporate/driver/other categories to business or household automatically. Preserve contracts, payment references, historical receipts and KYC provenance. Obtain a verified mapping and reconcile conflicts in a supervised queue. Prefer invitation/re-enrollment if cross-project Auth migration cannot securely preserve identity. Rehearse in isolation, record row counts/hashes and retain rollback mapping. No real accounts have been migrated.

The dedicated target was supplied during implementation. Email confirmation remains enabled, the mobile redirect is allowlisted, and minimum password length is 12. Management API credentials were used transiently, never stored in the app. Rotate credentials shared in chat. Docker is unavailable on PATH; live SQL tests ran in a rolled-back transaction. iOS native builds require macOS or an authorized EAS setup.

