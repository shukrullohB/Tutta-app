import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/subscription_plan.dart';

final subscriptionPlanProvider = StateProvider<SubscriptionPlan>((ref) {
  return SubscriptionPlan.free;
});
