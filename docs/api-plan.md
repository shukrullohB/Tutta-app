# Tutta – API Plan

## Auth
- POST /auth/register
- POST /auth/login
- GET /auth/profile

---

## Listings
- GET /listings
- GET /listings/:id
- POST /listings
- PUT /listings/:id
- DELETE /listings/:id

---

## Listing Images
- POST /listings/:id/images
- DELETE /listings/:id/images/:imageId

---

## Bookings
- GET /bookings/my
- POST /bookings
- PATCH /bookings/:id/cancel
- PATCH /bookings/:id/confirm

---

## Reviews
- POST /reviews
- GET /listings/:id/reviews

---

## Chat
- GET /chats
- GET /chats/:id/messages
- POST /chats/:id/messages

---

## Payments
- POST /payments/create
- POST /payments/callback
- GET /payments/:id

---

## Premium
- POST /premium/subscribe
- GET /premium/status

---

## Skill Exchange
- POST /skill-exchange
- GET /skill-exchange
- GET /skill-exchange/:id
