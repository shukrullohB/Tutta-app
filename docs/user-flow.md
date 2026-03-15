# Tutta — User Flow (MVP)

## Roles
- Guest
- Host (same user can be both)

---

## Guest Flow: Discover → Request → Stay (MVP)

1. **Open app**
   - If not logged in → Sign up / Sign in

2. **Browse listings**
   - Feed of listings (default location)
   - Search by city/area
   - Apply filters (price, type, guests)

3. **View listing details**
   - Photos, description, rules
   - Price per night
   - Availability (basic)
   - Host profile snippet

4. **Select dates**
   - Must be between 1 and 30 days total

5. **Send booking request**
   - Optional message to host
   - Booking status becomes **Pending**

6. **Wait for host response**
   - If **Accepted** → show booking confirmation screen
   - If **Rejected** → suggest other listings
   - If no response → allow guest to cancel request

7. **Message host (if enabled)**
   - Clarify arrival time, rules, etc.

8. **(Post-stay later)**
   - Reviews (not MVP unless you want it)

---

## Host Flow: Create Listing → Manage Requests

1. **Become a host**
   - Complete minimal host profile info

2. **Create listing**
   - Add title, description, type (room/entire)
   - Upload photos
   - Set price/night and max guests
   - Add house rules
   - Set availability (available/unavailable dates)

3. **Publish listing**
   - Listing appears in guest discovery

4. **Receive booking request**
   - View request details: dates, guest count, guest profile, message

5. **Respond**
   - **Accept** → booking becomes Accepted
   - **Reject** → booking becomes Rejected

6. **Message guest**
   - Coordinate check-in details

---

## Key Screens (suggested)
Guest:
- Auth
- Home/Feed
- Search/Filters
- Listing Details
- Date Picker
- Booking Request Status
- Messages

Host:
- Host Dashboard
- Create/Edit Listing
- Requests/Bookings
- Messages

Shared:
- Profile
- Settings
