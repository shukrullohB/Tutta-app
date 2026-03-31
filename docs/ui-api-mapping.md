# Tutta UI -> API Mapping (v1)

Bu hujjat Flutter va Backend jamoasi uchun bitta `source of truth`.
Har bir screen qaysi endpointga bog'lanishi, qaysi field qayerdan kelishi shu yerda aniqlanadi.

## 1. Qoidalar

- UI backend contractdan tashqariga chiqmaydi.
- Backend response field nomlarini sabab bo'lmasa o'zgartirmaydi.
- Har bir endpointda `loading`, `empty`, `error` state UI tomonda bo'lishi shart.
- Barcha vaqt qiymatlari ISO formatda (`YYYY-MM-DD` yoki datetime ISO8601).

## 2. Global Response Contract

### 2.1 Xato formati (tavsiya)

```json
{
  "detail": "Human-readable error message"
}
```

Yoki field-level validation:

```json
{
  "email": ["A user with this email already exists."]
}
```

### 2.2 Auth

- Protected endpointlar uchun header:
  - `Authorization: Bearer <access_token>`

## 3. Screen Mapping

## 3.1 Login Screen

- UI action: `Sign in`
- Endpoint: `POST /api/auth/login`
- Request:

```json
{
  "email": "user@example.com",
  "password": "StrongPass123!"
}
```

- Success response (asosiy):
  - `access`
  - `refresh`
  - `user.id`
  - `user.email`
  - `user.role`

- Error state:
  - invalid credentials -> toast/snackbar

## 3.2 Register Screen

- UI action: `Create account`
- Endpoint: `POST /api/auth/register`
- Request:

```json
{
  "email": "user@example.com",
  "password": "StrongPass123!",
  "password_confirm": "StrongPass123!",
  "first_name": "Ali",
  "last_name": "Valiyev",
  "role": "guest",
  "phone_number": "+998901234567"
}
```

- Success:
  - created user object

- Error:
  - email exists
  - weak password
  - password mismatch

## 3.3 Home / Listings Feed

- UI action: listing card list
- Endpoint: `GET /api/listings`
- Query (optional):
  - `listing_type=home|room`
  - `location=<text>`
  - `min_price=<number>`
  - `max_price=<number>`
  - `search=<text>`

- Card fields mapping:
  - UI `title` <- API `title`
  - UI `location` <- API `location`
  - UI `price` <- API `price_per_night`
  - UI `cover image` <- API `images[0].image`
  - UI `id` <- API `id`

## 3.4 Listing Detail

- Endpoint: `GET /api/listings/{id}`
- Detail fields:
  - `title`, `description`, `location`
  - `price_per_night`, `max_guests`
  - `images[]`
  - `host_id`

## 3.5 Create Listing (Host)

- Endpoint: `POST /api/listings`
- Auth: required, `role=host`
- Request (`multipart/form-data`):
  - `title`
  - `description`
  - `location`
  - `listing_type`
  - `price_per_night`
  - `max_guests`
  - `image_files[]`

- Error:
  - non-host user
  - invalid image size/count

## 3.6 Manage Listing (Host)

- Endpoints:
  - `GET /api/listings/{id}/manage`
  - `PATCH /api/listings/{id}/manage`
  - `DELETE /api/listings/{id}/manage` (soft delete)
  - `POST /api/listings/{id}/publish`
  - `POST /api/listings/{id}/unpublish`

- Notes:
  - faqat listing owner host ishlata oladi.

## 3.7 Create Booking (Guest)

- Endpoint: `POST /api/bookings`
- Auth: required, `role=guest`
- Request:

```json
{
  "listing": 12,
  "start_date": "2026-04-10",
  "end_date": "2026-04-14"
}
```

- Backend calculates:
  - `total_price`
  - `status=pending`

- Error:
  - date overlap
  - booking own listing
  - past date

## 3.8 Booking List

- Endpoint: `GET /api/bookings`
- Query:
  - `role=guest` yoki `role=host`

- UI sections:
  - `My trips` (guest)
  - `Reservations` (host)

## 3.9 Booking Actions

- Host confirm:
  - `POST /api/bookings/{id}/confirm`
- Guest/Host cancel:
  - `POST /api/bookings/{id}/cancel`

## 3.10 Reviews

- Create:
  - `POST /api/reviews`
- List:
  - `GET /api/reviews?listing_id={id}`

## 4. Flutter Integration Checklist

- Auth token storage (secure storage).
- HTTP interceptor:
  - `401` bo'lsa `refresh` oqimi.
- API client layer (`dio`/`http` repository pattern).
- Har screen uchun 4 state:
  - loading
  - success
  - empty
  - error

## 5. Backend Checklist

- Contractga mos response qaytarish.
- Permissionlar aniq ishlashi.
- Validation message aniq bo'lishi.
- Swagger/OpenAPI keyingi bosqichda qo'shiladi.

## 6. Change Management

Contract o'zgarishi kerak bo'lsa:

1. `docs/ui-api-mapping.md` yangilanadi.
2. Flutter + Backend ikkisi ham tasdiqlaydi.
3. Keyin kodga o'zgarish kiritiladi.
