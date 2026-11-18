# TYDIGO Booking
Tap. Sort. Picked.

Independent Expo / React Native / TypeScript customer application. The old project at C:/MobileApps/TydigoApp is a read-only reference and was not changed.

## Run
Use pnpm. Install with `pnpm install --frozen-lockfile`, then `pnpm start`, `pnpm android`, `pnpm ios` or `pnpm web`.
Copy .env.example to an untracked .env and configure the dedicated Booking Supabase project.
The untracked local .env connects to dedicated project auplmtypaptzxjqeqhhf. Missing configuration visibly disables sign-in on other installations.

## Structure
- src/app: one Expo Router tree; public registration/sign-in and guarded customer routes.
- src/navigation/registry.ts: Booking-only screen inventory.
- src/domain: canonical account validation and transaction eligibility.
- src/auth: session restoration, confirmed-email validation and canonical account lookup.
- src/components: brand tokens, typography, cards, controls and safe scrolling.
- supabase/migrations: independent Booking schema deployed to auplmtypaptzxjqeqhhf.
- tests: isolated account-policy tests, no production users or documents.
- docs: architecture, integration contract, migration policy and milestone status.

App IDs: com.tydigo.booking (Android and iOS); scheme: tydigo-booking.
Official logo PNGs were copied from the reference project's assets/brand. App uses Inter.
SDK 58 is the version returned by the new Expo blank TypeScript template; no SDK changes were made to the reference app.

Read docs/IMPLEMENTATION_STATUS.md before deployment. This is an implemented foundation, not a production-ready release.

See [Booking backend deployment and API contracts](docs/BOOKING_BACKEND.md) for the current migration inventory, hosted verification and release gates.

