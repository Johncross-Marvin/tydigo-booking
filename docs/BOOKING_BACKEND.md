# Booking backend deployment and API contracts

The dedicated hosted Booking project is `tydigo-booking`, reference `auplmtypaptzxjqeqhhf`, in `eu-west-1`. Its public schema has 21 tables protected by RLS. Elevated implementations, administrator capabilities, audit logs, reward configuration, payment events and the integration inbox/outbox live in the unexposed `private` schema. Supabase owns the `auth` and `storage` schemas.

| Migration | Hosted state |
| --- | --- |
| 20261118160542 booking_foundation | Previously applied and recorded |
| 20261118212826 booking_operations | Applied atomically and verified in migration history |
| 20261118214241 harden_booking_rpcs | Applied atomically and verified in migration history |
| 20261118214613 booking_outcome_evidence | Applied atomically and verified in migration history |

## Customer API

- Auth signup creates the immutable canonical household, estate or business customer account in the same transaction. Email confirmation is enabled. The app checks the Auth UUID against the canonical record on sign-in and restoration.
- `create_organization`, `set_organization_member` and `save_address` manage scoped Estate and Business premises. Addresses with proposed coverage require an operations reviewer to call `verify_address_coverage` before quoting.
- `list_collection_slots(address)` returns open windows for an eligible address. `request_quote(address, category, slot, quantity, unit, prepared?, destination?)` returns a server price in integer kobo, itemization and expiry from configured rules. Send requires preparation confirmation and an eligible destination.
- Both services require a configured and authorized destination. Drive can automatically select the only eligible destination. Payments staff review refunds and operations staff use `record_booking_outcome` to attest scheduling, collection and delivery with distinct evidence references. The RPC requires a paid booking, ordered transitions and MFA. A delivery record does not certify recycling or award EcoPoints.
- `create_booking(quote, idempotency)` checks email, active customer status, KYC approval, organization permission, quote expiry and slot capacity. The same quote and idempotency key returns the existing booking. `cancel_booking` and `reschedule_booking` only change eligible unpaid orders. Payment-intent or paid orders go to support review.
- `submit_verification_document(requirement, object_path)` links a private upload to the current application and changes the account to submitted once all active requirements are present. Staff review sets status and creates a separate audit event. Corrections and resubmission use a new application record.
- `review_verification`, `update_support_ticket`, `review_refund` and `get_operational_audit` require the relevant staff capability and MFA level 2. Staff membership is server managed. Booking, payment and support exception queues are exposed through capability-scoped RLS reads.
- Receipts, booking history, support tickets, refunds, payments and rewards are owner scoped. Organization member access to premises and bookings does not grant access to another member's payment orders. Customer clients cannot directly write payment state, rewards, verified coverage or approval status.

## Storage and Realtime

Three private buckets are deployed. `verification` and `support-evidence` accept PDF, JPEG and PNG up to 10 MB. `receipt-attachments` accepts PDF up to 5 MB and is server written. Customers read within their own UUID paths. Approved MFA staff can issue short-lived signed links through the authorized Storage client for submitted verification documents.

Booking, payment, verification and support changes write customer notifications. Only the owner-readable `customer_notifications` table is added to the Realtime publication by this migration. The app watches that table to refetch authoritative data after a notification or reconnect. It resumes account checks on foreground. Hosted publication and row policies are confirmed. WebSocket delivery with signed-in users still needs staging verification.

## Payments

`paystack-checkout` accepts POST `{action: "initialize" | "verify", booking_id}`. The function validates the caller with Supabase Auth. Initialization gets the amount and reference from the server. Verification matches the provider's reference, amount, currency, mode and transaction ID. `paystack-webhook` checks the SHA-512 HMAC of the raw request body and verifies successful charges independently with Paystack. The settlement RPC is service-role-only and atomically creates the receipt. Duplicate settlement delivery returns the same receipt. Failure and abandonment are stored on the payment order without overwriting a successful settlement.

Both function endpoints are deployed. Payment code is sandbox-only and rejects sandbox use on the dedicated production project. A staging Supabase project needs `PAYSTACK_TEST_SECRET_KEY` and `PAYSTACK_TEST_CALLBACK_URL` through its Edge Function secret store. The live public key, callback and webhook coordinates do not provide the server credential needed for verification. Production checkout remains unavailable. Refund requests, staff review and service-only full-refund reconciliation are present. Provider refund execution and partial refund automation require separate approval and implementation.

Provider references: [Paystack webhooks](https://paystack.com/docs/payments/webhooks/) and [transaction API](https://paystack.com/docs/api/transaction/).

## Integration boundary

Booking writes durable `booking.created`, `booking.status_changed` and verified-payment `booking.ready_for_assignment` events with stable Booking UUIDs and a per-booking sequence. The service-only inbox deduplicates event IDs and booking sequences. It stages accepted event envelopes for reconciliation and does not apply operational completion or award rewards. External credentials, authenticated partner transport, dispatch, evidence resolution and verified recycling outcomes remain deferred.

## Verification and release gates

- Isolated PostgreSQL tests apply all migrations and exercise account creation, confirmed email checks, owner/member permissions, KYC submissions and correction, two quoted booking flows, capacity, idempotency, payment outcomes and settlement replay, refund reconciliation, Storage policies, reward write protection and integration privileges.
- Deno tests cover webhook body/signature binding and provider reference, currency, amount, status and environment matching.
- Hosted checks verified migration history, buckets, RLS, invocation failures for anonymous access and disabled webhook processing, and notification publication. The final Security Advisor run returned zero warnings and eight informational findings for intentionally client-inaccessible tables.
- Staging deployment and real email, Storage HTTP, Realtime and Paystack provider tests await a separate staging project and credentials. No synthetic data was inserted in production for this change.
- Supply approved coverage, destinations, time windows, prices and category-specific verification requirements. Use staged staff accounts to verify MFA and signed document access. Configure custom SMTP and apply the recovery-code email template in staging, then enable `EXPO_PUBLIC_ENABLE_PASSWORD_RECOVERY` in that build.
- GitHub verification runs TypeScript, lint, PostgreSQL and Deno checks. The manual production job requires a successful check run on main, the protected `booking-production` environment and `BOOKING_PRODUCTION_DEPLOY_ENABLED=true`. Configure authorized reviewers and rotated deployment credentials before enabling it. This job has not run.
