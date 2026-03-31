# Tutta Integration Checklist (Flutter + Backend)

Bu checklist Flutter va Backend jamoasi bir xil ketma-ketlikda ishlashi uchun.

## 1. Branch Strategy

- Base branch (development): `feature/backend`
- Backend feature branchlar:
  - `feature/auth-api`
  - `feature/listing-api`
  - `feature/booking-system`
  - `feature/chat-system`
  - `feature/payment-integration`
- Mobile feature branchlar:
  - `feature/mobile-auth`
  - `feature/mobile-listings`
  - `feature/mobile-bookings`
  - `feature/mobile-chat`
  - `feature/mobile-payments`

## 2. Source Of Truth

- UI/API mapping: `docs/ui-api-mapping.md`
- API o'zgarsa avval hujjat yangilanadi, keyin kod.

## 3. Environment Setup Check

### Backend

- [ ] `.env` configured
- [ ] `python manage.py migrate` success
- [ ] `python manage.py runserver` success
- [ ] API reachable at `http://127.0.0.1:8000`

### Mobile

- [ ] Flutter SDK version fixed
- [ ] `flutter pub get` success
- [ ] Base URL configured for backend
- [ ] Auth token secure storage configured

## 4. Feature Integration Matrix

## 4.1 Auth

- Backend:
  - [ ] `POST /api/auth/register`
  - [ ] `POST /api/auth/login`
  - [ ] `POST /api/auth/refresh`
  - [ ] `POST /api/auth/logout`
  - [ ] `GET /api/users/me`
- Mobile:
  - [ ] Login screen connected
  - [ ] Register screen connected
  - [ ] Token refresh flow implemented
  - [ ] Logout clears local session
- QA:
  - [ ] Invalid login handled
  - [ ] Expired access token auto-refresh works

## 4.2 Listings

- Backend:
  - [ ] `GET /api/listings`
  - [ ] `GET /api/listings/{id}`
  - [ ] `POST /api/listings`
  - [ ] `PATCH /api/listings/{id}/manage`
  - [ ] `POST /api/listings/{id}/publish`
  - [ ] `POST /api/listings/{id}/unpublish`
- Mobile:
  - [ ] Home feed connected
  - [ ] Listing detail connected
  - [ ] Host create listing connected
  - [ ] Host listing manage connected
- QA:
  - [ ] Image upload works
  - [ ] Filter/search works

## 4.3 Bookings

- Backend:
  - [ ] `POST /api/bookings`
  - [ ] `GET /api/bookings`
  - [ ] `POST /api/bookings/{id}/confirm`
  - [ ] `POST /api/bookings/{id}/cancel`
- Mobile:
  - [ ] Guest booking create connected
  - [ ] Guest bookings list connected
  - [ ] Host reservation list connected
  - [ ] Confirm/cancel actions connected
- QA:
  - [ ] Date overlap blocked
  - [ ] Host cannot book own listing

## 4.4 Reviews

- Backend:
  - [ ] `POST /api/reviews`
  - [ ] `GET /api/reviews`
- Mobile:
  - [ ] Review create UI connected
  - [ ] Review list in listing detail connected

## 4.5 Chat

- Backend:
  - [ ] Thread list endpoint
  - [ ] Message list endpoint
  - [ ] Send message endpoint
- Mobile:
  - [ ] Chat list connected
  - [ ] Thread messages connected
  - [ ] Send message connected

## 4.6 Payments

- Backend:
  - [ ] Payment init endpoint
  - [ ] Payment webhook endpoint
  - [ ] Booking-payment link ready
- Mobile:
  - [ ] Payment UI connected
  - [ ] Payment result handling connected

## 5. API Smoke Test (har merge oldidan)

- [ ] Register -> Login -> Me
- [ ] Listings list -> detail
- [ ] Booking create -> host confirm
- [ ] Booking cancel
- [ ] Review create/list

## 6. PR Checklist

- [ ] Feature branch up-to-date with `feature/backend`
- [ ] `check`/tests passed locally
- [ ] Docs updated (`ui-api-mapping.md` if contract changed)
- [ ] No secrets committed (`.env` not tracked)
- [ ] PR description includes:
  - scope
  - endpoint changes
  - test evidence

## 7. Weekly Sync Agenda (30 min)

- [ ] Contract changes review
- [ ] Blockers (backend/mobile)
- [ ] Next sprint priorities
- [ ] Regression risks
