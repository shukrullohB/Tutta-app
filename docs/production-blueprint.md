# Tutta Production Blueprint (Flutter + Backend)

## 1) Product Architecture Summary
- Scope: short-term rental marketplace only for Uzbekistan, max stay 30 days.
- Roles: renter and host, with fast role switching.
- Listing modes: `paid_rental` and `free_stay_language_exchange`.
- Premium rule: searching/browsing `free_stay` listings requires active premium.
- Core flows:
  - Auth -> role selection -> renter/host home shell
  - Search -> listing detail -> booking request/instant confirm -> payment
  - Host listing wizard -> moderation -> booking handling -> calendar
  - Chat + notifications + reviews after completed stay only

## 2) MVP vs Full Scope
### MVP
- Onboarding, auth (phone OTP + Google/OneID placeholder), role selector
- Search with city/district/guest/type/basic amenities
- Listing details, booking request, host approve/reject
- Basic chat, favorites, profile/settings
- Premium paywall + free stay gating
- Payment intent abstraction with Click/Payme adapters

### Full Scalable
- Full listing wizard (multi-step + advanced free-stay fields)
- Calendar availability and overbooking prevention
- Moderation workflows and abuse reporting
- Push notifications, analytics events, admin tools
- Rich host profile stats (response rate/time, verified badge)

## 3) Tech Stack Recommendation
- Flutter: Riverpod + StateNotifier/AsyncValue.
- Navigation: GoRouter (typed route names, guarded redirects).
- Network: Dio + centralized `ApiClient` + envelope parser.
- Models: Freezed + json_serializable.
- Secure storage: flutter_secure_storage.
- Caching: cached_network_image.
- Localization: Flutter gen-l10n (`uz`, `ru`, `en`).
- Realtime chat:
  - Preferred: backend WebSocket (Django Channels or FastAPI ws gateway)
  - Fallback: long-polling + optimistic send queue.
- Backend: Django REST + PostgreSQL + Redis (throttles, queues, sockets).

## 4) Folder Structure (Feature-First + Clean)
```txt
mobile/lib/
  app/
    app.dart
    router/
    theme/
    l10n/
  core/
    config/
    enums/
    errors/
    network/
    storage/
    widgets/
  features/
    auth/
    role/
    home/
    listings/
    bookings/
    payments/
    premium/
    chat/
    reviews/
    wishlist/
    profile/
```

## 5) Domain Models
- `User`: id, role flags, premium status, locale, phone/email.
- `HostProfile`: rating, response metrics, languages, verification.
- `Listing`: type, location, price, amenities, policies, active/moderation flags.
- `ListingType`: apartment, room, home_part, free_stay.
- `ListingAmenity`: wifi/ac/kitchen/etc.
- `Booking`: dates, guests, status, payment status, total.
- `BookingStatus`: pending, confirmed, cancelled, completed.
- `Payment`: provider, status, amount, external transaction id.
- `Subscription`: plan, validity window, active flag.
- `Review`: booking-bound review (host/listing).
- `Conversation` + `Message`: participants, last message, delivery state.
- `AvailabilityCalendar`: per-day status/price override.
- `Favorite`: user-listing pair.
- `Notification`: type, payload, read flag.
- `LanguagePreference`: ui language + learning/teaching sets.
- `FreeStayProfile`: languages, cultural notes, co-living preference.

## 6) Screen Map
- Splash, onboarding, auth, OTP verify, role selector.
- Home renter, search, filters sheet, results list/map.
- Listing details, booking request, payment, booking success.
- Favorites, chat list, chat detail, my bookings.
- Profile, settings, support.
- Host dashboard, create listing wizard, edit listing, host bookings/requests.
- Premium paywall/subscription management.
- Reviews submission/history.

## 7) API Map (REST + Realtime)
- Auth: `/auth/register|login|refresh|logout|google|oneid|otp/*`
- Users: `/users/me`, `/users/{id}`, `/host-profiles/{id}`
- Listings: `/listings`, `/listings/{id}`, `/listings/{id}/publish|unpublish`
- Search: `/listings?city=&district=&guests=&type=&q=&min_price=&max_price=`
- Availability: `/listings/{id}/availability`, `/hosts/{id}/calendar`
- Bookings: `/bookings`, `/bookings/{id}`, `/confirm|cancel|complete`
- Reviews: `/reviews`, `/reviews?listing_id=`
- Favorites: `/favorites`, `/favorites/{listingId}`
- Chat REST bootstrap: `/chat/threads`, `/chat/threads/{id}/messages`
- Chat realtime: `ws://.../chat/threads/{id}`
- Payments: `/payments/intents`, `/payments/webhooks/{provider}`
- Subscriptions: `/subscriptions/plans`, `/subscriptions/activate`
- Notifications: `/notifications`, `/notifications/{id}/read`
- Moderation: `/admin/moderation/listings|users|reviews`

## 8) PostgreSQL Schema (Core)
- `users`, `host_profiles`, `subscriptions`
- `listings`, `listing_images`, `listing_free_stay_profiles`
- `listing_amenities` (join), `favorites`
- `availability_days` (listing_id + date unique)
- `bookings` (status, payment_status, unique business constraints)
- `payments` (provider + external_id unique)
- `reviews` (unique booking_id to enforce one review per completed booking)
- `chat_threads`, `chat_thread_participants`, `chat_messages`
- `notifications`
- All business tables: `created_at`, `updated_at`, `deleted_at` (soft delete where needed), `created_by`, `updated_by`.

Indexes:
- Listings: `(is_active, city, district, listing_type)`, GIN for text search.
- Bookings: `(listing_id, start_date, end_date, status)`.
- Payments: `(provider, external_transaction_id)` unique.
- Messages: `(thread_id, created_at desc)`.

## 9) Business Rules
- Stay length: `check_out - check_in <= 30 days`.
- Booking overlap: reject if active booking intersects selected range.
- Reviews only if booking status is `completed` and reviewer is participant.
- Free-stay search gating: deny listing search unless premium.
- Host phone visibility: return phone only when listing setting allows it.
- Moderation: listing visible only when active and approved.
- Cancellation policy: configurable windows + role-specific constraints.
- Instant confirm:
  - On: auto-confirm booking when constraints pass.
  - Off: pending host approval.

## 10) UI/UX Style Guide
- Direction: minimal, modern, clean white/neutral base + warm accent.
- Palette:
  - Primary `#0B4D8C`
  - Accent `#D98C2B`
  - Surface `#F6F7F9`
  - Text `#111827` / secondary `#6B7280`
- Typography: SF Pro / Manrope fallback.
- Spacing scale: 4/8/12/16/24/32.
- Cards: large radius (20-24), subtle border and shadow.
- Bottom nav: 4-5 tabs max with role-aware destinations.
- Chips: compact filter chips with selected state contrast.
- Premium badge: small pill with accent background + crown icon.
- Empty states: icon + short action-oriented copy + CTA.

## 11) Current Implementation Status (March 27, 2026)
- Existing scaffold already covers Phase 1 baseline:
  - app bootstrap, router, theme, l10n, auth, role selector, home shell.
- Newly fixed:
  - search reliability (city matching less strict)
  - filters now actually apply (types + amenities + district)
  - free stay toggle triggers immediate re-search
  - loading state is visible during search
  - listings API repository added and runtime-toggle ready
  - backend listing endpoint extended for richer query params
  - booking creation hardened with 30-day rule and guest-limit validation
  - booking completion lifecycle endpoint added (`/api/bookings/{id}/complete`)
  - booking create/confirm paths made transaction-safe against race conflicts
  - host create-listing flow upgraded to multi-step wizard with paid/free-stay branches
  - backend listings schema expanded for city/district, stay limits, phone visibility, free-stay profile
  - moderation workflow added for listings (`draft/pending/approved/rejected`)
  - public listing feed now hides non-approved listings by design
  - host edit-listing flow added (mobile route/screen + repository update method)
  - editing listing content now resubmits it to moderation (`pending`)
  - availability calendar added (`/api/listings/{id}/availability`, mobile host screen)
  - booking creation now blocks dates marked unavailable in host calendar
  - booking UI now consumes availability and prevents selecting blocked dates before submit
  - launch readiness checklist added for migrations/tests/smoke paths
  - checkout calendar upgraded from static mock to availability-aware month grid
  - notifications foundation added (backend module + mobile notifications screen)
  - automatic in-app notifications on booking and listing moderation lifecycle events
  - push-device token registry API added (`register/unregister`) for FCM/APNs bridge

## 12) Next Phase Plan
1. Stabilize API contracts for listings/search and booking lifecycle.
2. Complete host listing wizard with free-stay branch.
3. Implement availability calendar + overlap-safe booking transaction.
4. Add websocket chat delivery/read receipts.
5. Add subscription lifecycle + premium entitlement cache.
