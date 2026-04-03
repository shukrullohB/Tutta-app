# Tutta Mobile Run Modes

## 1) Demo mode (default, fastest)
Uses fake repositories for auth/listings/bookings/chat/reviews/payments/notifications.

Command:

```bash
flutter run
```

## 2) Backend mode (real API)
Set all fake flags to `false` and provide backend URL.

```bash
flutter run \
  --dart-define=API_BASE_URL=https://your-backend-domain/api \
  --dart-define=USE_FAKE_AUTH=false \
  --dart-define=USE_FAKE_LISTINGS=false \
  --dart-define=USE_FAKE_BOOKINGS=false \
  --dart-define=USE_FAKE_CHAT=false \
  --dart-define=USE_FAKE_REVIEWS=false \
  --dart-define=USE_FAKE_PAYMENTS=false \
  --dart-define=USE_FAKE_NOTIFICATIONS=false
```

## 3) Hybrid mode
Useful while backend modules are developed in parallel.
Example: real auth/listings + fake chat/reviews.

```bash
flutter run \
  --dart-define=API_BASE_URL=https://your-backend-domain/api \
  --dart-define=USE_FAKE_AUTH=false \
  --dart-define=USE_FAKE_LISTINGS=false \
  --dart-define=USE_FAKE_BOOKINGS=false \
  --dart-define=USE_FAKE_CHAT=true \
  --dart-define=USE_FAKE_REVIEWS=true
```

## Yandex MapKit key
- Android: `mobile/android/app/src/main/res/values/strings.xml` -> `yandex_mapkit_api_key`
- iOS: `mobile/ios/Runner/Info.plist` -> `YANDEX_MAPKIT_API_KEY`
