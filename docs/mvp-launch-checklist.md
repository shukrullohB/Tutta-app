# Tutta MVP Launch Checklist

## Backend
- Apply migrations in order:
  - `python manage.py migrate`
- Validate schema endpoints:
  - `GET /api/schema/`
  - `GET /api/docs/`
- Run tests:
  - `python manage.py test apps.listings apps.bookings`

## Mobile
- Fetch dependencies:
  - `flutter pub get`
- Codegen refresh if models changed:
  - `flutter pub run build_runner build --delete-conflicting-outputs`
- Run tests:
  - `flutter test`
- Run static analysis:
  - `flutter analyze`

## Core Flows To Smoke Test
1. Auth -> role selector -> renter home.
2. Search + filters + premium gate for free stay.
3. Listing details -> booking request with availability-aware date picking.
4. Host create listing (paid and free stay branches).
5. Host edit listing -> moderation resets to `pending`.
6. Host availability calendar -> block/unblock dates.
7. Booking rejects blocked dates and overlaps.
8. Admin listing approve/reject visibility behavior.
9. Notifications list and mark-read actions.
10. Booking/listing actions generate in-app notifications for target users.
11. Push device token register/unregister endpoints work for authenticated users.

## Production Flags
- Mobile runtime flags:
  - `USE_FAKE_AUTH=false`
  - `USE_FAKE_LISTINGS=false`
  - `USE_FAKE_BOOKINGS=false`
  - `USE_FAKE_PAYMENTS=false`
  - `USE_FAKE_REVIEWS=false`
  - `USE_FAKE_CHAT=false`

## Known Follow-ups (Post-MVP Hardening)
- Add server-side pagination/filters for availability range (`from`, `to`).
- Add payment reconciliation webhooks for real Click/Payme credentials.
- Wire FCM/APNs sender worker using registered push device tokens.
