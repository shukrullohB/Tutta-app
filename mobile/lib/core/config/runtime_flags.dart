class RuntimeFlags {
  const RuntimeFlags._();

  static const bool useFakeAuth = bool.fromEnvironment(
    'USE_FAKE_AUTH',
    defaultValue: true,
  );

  static const bool useFakeBookings = bool.fromEnvironment(
    'USE_FAKE_BOOKINGS',
    defaultValue: true,
  );

  static const bool useFakePayments = bool.fromEnvironment(
    'USE_FAKE_PAYMENTS',
    defaultValue: true,
  );

  static const bool useFakeReviews = bool.fromEnvironment(
    'USE_FAKE_REVIEWS',
    defaultValue: true,
  );

  static const bool useFakeChat = bool.fromEnvironment(
    'USE_FAKE_CHAT',
    defaultValue: true,
  );
}
