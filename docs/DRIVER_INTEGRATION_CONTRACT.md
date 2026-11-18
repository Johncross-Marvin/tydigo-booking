# Future operations boundary (Booking side only)
No Driver app, operational backend or deployment is implemented.

Booking IDs are server-generated UUIDs and remain stable across integrations.
Envelope version 1: event_id UUID, booking_id UUID, event_type, sequence integer, occurred_at UTC timestamp, payload object, producer identifier.
Events: booking.created; booking.accepted_for_dispatch; collector.assigned; pickup.in_progress; collection.evidence_submitted; pickup.completed; delivery.confirmed; booking.cancelled.

Future transport must use authenticated server-to-server requests, signed raw event bodies, key identifiers, bounded timestamp validity and replay protection. Unique event IDs plus per-booking sequence guard duplicate and out-of-order processing. Out-of-order events go to reconciliation, not arbitrary status overwrite. Persist receipt and disposition in an audit trail.

Booking remains authoritative for customer identity, bookings, quotes, payment and customer-facing status. Completion evidence cannot mark payment paid or award rewards without independent Booking-side validation. Only permitted collection display information crosses the boundary. Never transmit customer auth tokens, KYC documents or unrestricted database credentials. A collector assignment is displayed only after authenticated evidence is reconciled. Until integration exists, show actual awaiting_assignment/scheduled/unavailable/pending states.

Database outbox schema is reserved; publishing, webhook ingestion, signature verification and reconciliation workers are not implemented.

