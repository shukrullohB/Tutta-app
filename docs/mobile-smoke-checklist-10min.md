# Tutta Mobile 10-Minute Smoke Checklist

## 1. Auth + role
- Open app, sign in via OTP.
- Confirm redirect to role selector.
- Select renter role and open home.

## 2. Search + filters
- Open search screen.
- Type city (`Tashkent`) and confirm results refresh automatically.
- Open filters:
- Set district/landmark text.
- Enable `Wi-Fi`, `Women only` (or `Men only`), and one property type.
- Apply and verify list changes.

## 3. Listing details
- Open any listing card.
- Verify gallery thumbnails, description, tags, and rating/reviews block are visible.
- Toggle favorite icon in app bar.

## 4. Favorites
- Open favorites tab/screen.
- Confirm previously favorited listing is shown.
- Remove from favorites and verify list updates immediately.

## 5. Chat
- From listing details tap `Chat`.
- Verify chat opens for this listing (not only generic chat list).
- Send one message and check it appears in thread.

## 6. Booking + calendar
- From listing details tap `Request booking`.
- Pick dates within 30 days and submit.
- Try invalid span (>30 days) and confirm validation blocks it.
- As host open availability calendar, block 1-2 days, save, and verify success snackbar.

## 7. Reviews
- Open completed booking and tap `Leave review`.
- Submit rating + comment.
- Return to listing details and verify new review appears in reviews section.

## 8. Map (Yandex)
- Set valid API key:
- Android: `mobile/android/app/src/main/res/values/strings.xml` -> `yandex_mapkit_api_key`
- iOS: `mobile/ios/Runner/Info.plist` -> `YANDEX_MAPKIT_API_KEY`
- Open map view and verify tiles render (not blank).
