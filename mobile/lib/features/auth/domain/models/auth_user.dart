import '../../../premium/domain/models/subscription_plan.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.role,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.countryCode = 'UZ',
    this.subscriptionPlan = SubscriptionPlan.free,
    this.accessToken,
    this.refreshToken,
  });

  final String id;
  final String email;
  final String role;
  final String firstName;
  final String lastName;
  final String? phone;
  final String countryCode;
  final SubscriptionPlan subscriptionPlan;
  final String? accessToken;
  final String? refreshToken;

  String get displayName {
    final full = '$firstName $lastName'.trim();
    return full.isEmpty ? email : full;
  }

  bool get isPremium => subscriptionPlan == SubscriptionPlan.premium;
}
