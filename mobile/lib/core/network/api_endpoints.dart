class ApiEndpoints {
  const ApiEndpoints._();

  static const health = '/health';

  // Backend auth contract
  static const authRegister = '/auth/register';
  static const authLogin = '/auth/login';
  static const authRefresh = '/auth/refresh';
  static const authLogout = '/auth/logout';
  static const authGoogle = '/auth/google';
  static const usersMe = '/users/me';
  static String userPublicProfile(String userId) =>
      '/users/$userId/public-profile';

  // Legacy auth endpoints (to be removed after full auth migration)
  static const authOtpRequest = '/auth/otp/request';
  static const authOtpVerify = '/auth/otp/verify';
  static const authSignOut = '/auth/sign-out';

  // Listings contract
  static const listings = '/listings/';
  static String listingsByHost(String hostId) => '$listings?host=$hostId';

  static String listingById(String id) => '$listings$id';

  static String listingManage(String id) => '${listingById(id)}/manage';

  static String listingPublish(String id) => '${listingById(id)}/publish';

  static String listingUnpublish(String id) => '${listingById(id)}/unpublish';

  static String listingAvailability(String id) =>
      '${listingById(id)}/availability';

  // Bookings contract
  static const bookings = '/bookings/';

  static String bookingById(String bookingId) => '$bookings$bookingId';

  static String bookingsByRole(String role) => '$bookings?role=$role';

  static String bookingConfirm(String bookingId) =>
      '${bookingById(bookingId)}/confirm';

  static String bookingCancel(String bookingId) =>
      '${bookingById(bookingId)}/cancel';

  // Legacy booking endpoints (to be removed after full booking migration)
  static String guestBookings(String guestUserId) =>
      '$bookings/guest/$guestUserId';

  static String hostBookings(String hostUserId) => '$bookings/host/$hostUserId';

  static String bookingReject(String bookingId) =>
      '${bookingById(bookingId)}/reject';

  static String bookingCancelByGuest(String bookingId) =>
      '${bookingById(bookingId)}/cancel-by-guest';

  static String bookingComplete(String bookingId) =>
      '${bookingById(bookingId)}/complete';

  static String bookingPaymentStatus(String bookingId) =>
      '${bookingById(bookingId)}/payment-status';

  static const paymentsIntents = '/payments/intents';

  static String paymentIntentById(String paymentIntentId) =>
      '$paymentsIntents/$paymentIntentId';

  static String paymentWebhook(String methodName) =>
      '/payments/webhooks/$methodName';

  // Notifications
  static const notifications = '/notifications';

  static String notificationById(String id) => '$notifications/$id';

  static String notificationMarkRead(String id) =>
      '${notificationById(id)}/read';

  static String notificationsMarkAllRead() => '$notifications/read-all';

  static String notificationsDeviceRegister() =>
      '$notifications/devices/register';

  static String notificationsDeviceUnregister() =>
      '$notifications/devices/unregister';

  static const reviews = '/reviews/';

  static String reviewsByListing(String listingId) =>
      '$reviews?listing_id=$listingId';

  static String reviewById(String reviewId) => '$reviews$reviewId';

  // Chat contract
  static const chatThreads = '/chat/threads';

  static String chatThreadById(String threadId) => '$chatThreads/$threadId';

  static String chatThreadMessages(String threadId) =>
      '$chatThreads/$threadId/messages';

  static String chatThreadMessageById(String threadId, String messageId) =>
      '${chatThreadMessages(threadId)}/$messageId';
}
