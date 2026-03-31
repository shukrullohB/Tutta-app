# Tutta Backend (Django + DRF)

## 1) Birinchi ishga tushirish

### 1.1 Virtual environment (tavsiya)

```bash
python -m venv .venv
.venv\Scripts\activate
```

### 1.2 Dependency o'rnatish

```bash
pip install -r requirements.txt
```

### 1.3 `.env` tayyorlash

```bash
copy .env.example .env
```

`.env` ichida Postgres credentiallarni o'zingizdagi real qiymatga almashtiring:

- `POSTGRES_DB`
- `POSTGRES_USER`
- `POSTGRES_PASSWORD`
- `POSTGRES_HOST`
- `POSTGRES_PORT`
- `CORS_ALLOWED_ORIGINS`
- `CSRF_TRUSTED_ORIGINS`

### 1.4 Migratsiya va server

```bash
python manage.py migrate
python manage.py runserver
```

Agar `password authentication failed` chiqsa, `.env`dagi `POSTGRES_USER/POSTGRES_PASSWORD` noto'g'ri.

## 2) Hozir backendda bor APIlar

- `POST /api/auth/register`
- `POST /api/auth/login`
- `POST /api/auth/google`
- `POST /api/auth/refresh`
- `POST /api/auth/logout`
- `GET /api/users/me`
- `GET /api/health`
- `GET /api/schema/`
- `GET /api/docs/`
- `POST /api/listings`
- `GET /api/listings`
- `GET /api/listings/{id}`
- `GET/PUT/PATCH/DELETE /api/listings/{id}/manage` (owner host only)
- `POST /api/listings/{id}/publish` (owner host only)
- `POST /api/listings/{id}/unpublish` (owner host only)
- `POST /api/bookings`
- `GET /api/bookings`
- `POST /api/bookings/{id}/confirm` (listing host only)
- `POST /api/bookings/{id}/cancel` (guest or host)
- `POST /api/reviews`
- `GET /api/reviews`
- `GET /api/chat/threads`
- `POST /api/chat/threads`
- `GET /api/chat/threads/{thread_id}/messages`
- `POST /api/chat/threads/{thread_id}/messages`
- `GET /api/payments/intents`
- `POST /api/payments/intents`
- `GET /api/payments/intents/{id}`
- `POST /api/payments/webhooks/{provider}`

## 2.1 Test

```bash
python manage.py test apps.users apps.listings apps.bookings apps.reviews apps.chat apps.payments
```

## 2.3 CI check (local)

```bash
set USE_SQLITE=True
python manage.py check
python manage.py makemigrations --check --dry-run
python manage.py test apps.users apps.listings apps.bookings apps.reviews apps.chat apps.payments
python manage.py spectacular --file openapi-schema.yml
```

## 2.2 API xato formati

API xatolari bir xil formatda qaytadi:

```json
{
  "success": false,
  "message": "Validation error.",
  "errors": {
    "field_name": ["..."]
  }
}
```

## 3) Git workflow (clean)

Asosiy branch: `feature/backend`

Har modul alohida branch:

- `feature/auth-api`
- `feature/listing-api`
- `feature/booking-system`
- `feature/chat-system`
- `feature/payment-integration`

Ish tartibi:

```bash
git checkout feature/backend
git pull origin feature/backend
git checkout -b feature/auth-api
# kod yozish
git add .
git commit -m "feat(auth): ..."
git push -u origin feature/auth-api
```

Keyin PR: `feature/auth-api` -> `feature/backend`.

## 4) Eslatma

- Local frontend/mobile integratsiya uchun `.env`da `CORS_ALLOWED_ORIGINS` va `CSRF_TRUSTED_ORIGINS` ni moslang.
- Flutter web (default 6060) ishlatsa, `.env`da `http://localhost:6060` va `http://127.0.0.1:6060` bo‘lishi kerak.
- Mobile API base URL: `http://<backend-host>:<port>/api`
- Productionda `DEBUG=False` va `SECURE_SSL_REDIRECT=True` bo'lishi kerak.
- Productionda security header envlari ham to'g'ri bo'lishi kerak:
  - `SECURE_HSTS_SECONDS`
  - `SECURE_HSTS_INCLUDE_SUBDOMAINS`
  - `SECURE_HSTS_PRELOAD`
  - `X_FRAME_OPTIONS`
  - `REFERRER_POLICY`

## 5) Docker bilan ishga tushirish

Repo root'da:

```bash
docker compose -f docker-compose.backend.yml up --build
```

Backend: `http://127.0.0.1:8000`
