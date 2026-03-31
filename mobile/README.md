# Tutta Mobile

## Run with backend API

`dio` base URL is controlled by `API_BASE_URL` (`--dart-define`).

Examples:

- Android emulator:
  - `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api`
- iOS simulator:
  - `flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api`
- Real device (same Wi-Fi as backend PC):
  - `flutter run --dart-define=API_BASE_URL=http://<YOUR_PC_IP>:8000/api`

## Run with real backend modules

By default fake data is enabled. Disable required modules via `--dart-define`:

- `USE_FAKE_AUTH=false`
- `USE_FAKE_BOOKINGS=false`
- `USE_FAKE_PAYMENTS=false`
- `USE_FAKE_REVIEWS=false`
- `USE_FAKE_CHAT=false`

Example:

- `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api --dart-define=USE_FAKE_AUTH=false --dart-define=USE_FAKE_BOOKINGS=false --dart-define=USE_FAKE_PAYMENTS=false --dart-define=USE_FAKE_REVIEWS=false --dart-define=USE_FAKE_CHAT=false`
