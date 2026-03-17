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

### 1.4 Migratsiya va server
```bash
python manage.py migrate
python manage.py runserver
```

Agar `password authentication failed` chiqsa, `.env`dagi `POSTGRES_USER/POSTGRES_PASSWORD` noto'g'ri.

## 2) Hozir backendda bor APIlar

- `POST /api/auth/register`
- `POST /api/auth/login`
- `POST /api/auth/refresh`
- `POST /api/auth/logout`
- `GET /api/users/me`
- `POST /api/listings`
- `GET /api/listings`
- `GET /api/listings/{id}`
- `POST /api/bookings`
- `GET /api/bookings`
- `POST /api/reviews`
- `GET /api/reviews`

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

## 4) Ertangi aniq plan

1. DB ulanishini 100% yashil holatga keltirish (`migrate` o'tishi kerak).
2. `feature/auth-api` branchda auth'ni kuchaytirish:
- refresh endpoint
- logout (token blacklisting)
- basic throttling
3. Auth testlar yozish.
