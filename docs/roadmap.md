# Tutta — Roadmap (MVP)

Dates are indicative; adjust to your team speed. Current date: 2026-03-15.

## Phase 0 — Setup & Foundations (Week 1–2)
**Goal:** stable dev workflow and basic architecture.

- Repo structure finalized (`mobile/`, `backend/`, `docs/`)
- Flutter app scaffolding + navigation
- Backend API scaffolding (auth, db, validation, logging)
- Basic CI checks (lint/test) if feasible
- Define core data models:
  - User, Listing, Booking, Message

## Phase 1 — Listings MVP (Week 3–5)
**Goal:** hosts can create listings; guests can browse.

- Host listing create/edit
- Photo upload (simple storage approach)
- Listings feed + listing details
- Search by location (basic)
- Filters (price, type, guests)
- Basic availability fields

## Phase 2 — Booking Requests MVP (Week 6–8)
**Goal:** guest can request; host can accept/reject.

- Date selection (1–30 days)
- Booking request creation
- Host booking inbox
- Accept/reject actions
- Booking status screens

## Phase 3 — Messaging + Notifications (Week 9–10)
**Goal:** reduce friction and improve conversion.

- In-app messaging (basic)
- In-app notifications (and/or email)
- Basic safety/admin ability to disable listings/users

## Phase 4 — Pilot Launch (Week 11–12)
**Goal:** test in one city/region, learn fast.

- Limited beta testers
- Measure funnel:
  - browse → listing view → request → accept → completed stay
- Collect feedback and prioritize fixes
- Prepare simple support process (manual is OK)

## Post-MVP (Next)
- Payments (in-app)
- Reviews
- Map search
- Verification
- Disputes/refunds
- Performance + reliability improvements
