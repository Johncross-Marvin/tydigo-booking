# Booking architecture
## Identity and authorization
Exactly household, estate and business are accepted. The Auth insert trigger validates the category supplied at registration and creates customer_accounts in the same database transaction. An invalid category or missing name aborts signup rather than producing a partial account. Metadata is only initial input: later authorization reads customer_accounts, never editable metadata. Auth UUID is the canonical primary key.

Clients have SELECT only on accounts. No category, approval or status mutation grants exist. Login validates Auth email confirmation and canonical identity mapping. Missing/invalid accounts show recovery error, never Household. Each installation has one Supabase client/session. Native persistence uses SecureStore; web uses sessionStorage. Session state and protected screen tree are replaced on logout. Remote logout failures remain visibly blocked and must be resolved; complete offline token-clearing behavior remains a release blocker.

Supabase email confirmations must be enabled on the hosted project. Local config enables confirmations. Redirect URL is tydigo-booking://sign-in. Client does not consume verification-session URL tokens. Email is confirmed by Supabase before returning to explicit password login. Expired/resend/recovery UI and device verification remain incomplete.

## Verification
Pending verification permits dashboard, profile, help and verification. Commercial data has no public mutation grants. Private verification bucket accepts PDF/JPEG/PNG up to 10MB within the caller UUID folder. Upload cannot overwrite reviewed objects. Submission RPC validates requirement category, storage existence, account state and confirmed email. Completing all active requirements transitions to submitted, never approved.

Authorized review RPC requires a private staff membership and MFA assurance level 2, supports review/approve/reject/corrections and appends an audit row. Public signup cannot create staff membership. Staff provisioning, review queue UI, signed reviewer document retrieval, malware inspection, retention and realtime review refresh are outstanding. No document requirements are seeded: business-approved requirements must be supplied per category.

## Data ownership
customer_accounts owns identity/category/status; customer_addresses stores locations.
verification_requirements/documents and private review_audit support verification.
service_availability/waste_categories represent configured eligibility.
quotes, bookings and payment_orders are server-owned commercial records.
rewards_ledger, customer_notifications and support_tickets belong to individual customers.
private integration_events reserves durable, sequenced Booking-side events.
All exposed tables have RLS and explicit grants. No old users were copied.
Organization membership, recurring schedules, receipts and pricing rules need later migrations.

## Drive and Send
Separate route parameters and explanatory flows select Drive (supported waste transport) or Send (eligible separated material transport). Unknown service parameters are rejected. Send must eventually enforce preparation and approved destination eligibility. Neither service currently submits commercial bookings. Address/category/quantity/time-window forms, authoritative quotation and checkout are not released.

## Payments design (not implemented)
Initialize Paystack only from an authenticated server function after account/KYC, quote ownership and expiry validation. Generate a unique server reference; bind amount in integer kobo, currency and booking. Verify provider response and signed webhook against persisted expected reference/amount/currency. A browser callback only triggers re-query. Apply payment updates and event append atomically and idempotently. Track failures, refunds and partial refunds in append-only provider events. Issue receipt only from verified settled records. No public key or secret from the legacy project has been reused.

References consulted: Supabase React Native Auth quickstart https://supabase.com/docs/guides/auth/quickstarts/react-native and changelog https://supabase.com/changelog.md; Expo project creation https://docs.expo.dev/get-started/create-a-project/.

