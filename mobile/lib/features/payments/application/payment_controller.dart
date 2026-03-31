import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/runtime_flags.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/api_client.dart';
import '../data/repositories/api_payments_repository.dart';
import '../data/repositories/fake_payments_repository.dart';
import '../domain/models/payment_intent.dart';
import '../domain/models/payment_method.dart';
import '../domain/models/payment_status.dart';
import '../domain/repositories/payments_repository.dart';

class PaymentState {
  const PaymentState({
    required this.intent,
    required this.status,
    required this.loading,
    required this.errorMessage,
  });

  const PaymentState.initial()
    : intent = null,
      status = null,
      loading = false,
      errorMessage = null;

  final PaymentIntent? intent;
  final PaymentStatus? status;
  final bool loading;
  final String? errorMessage;

  PaymentState copyWith({
    PaymentIntent? intent,
    PaymentStatus? status,
    bool? loading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PaymentState(
      intent: intent ?? this.intent,
      status: status ?? this.status,
      loading: loading ?? this.loading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) {
  if (!RuntimeFlags.useFakePayments) {
    return ApiPaymentsRepository(ref.watch(apiClientProvider));
  }

  return FakePaymentsRepository();
});

class PaymentController extends StateNotifier<PaymentState> {
  PaymentController(this._read) : super(const PaymentState.initial());

  final Ref _read;

  Future<void> startPayment({
    required String bookingId,
    required int amountUzs,
    required PaymentMethod method,
  }) async {
    state = state.copyWith(loading: true, clearError: true);

    try {
      final intent = await _read
          .read(paymentsRepositoryProvider)
          .createBookingPaymentIntent(
            bookingId: bookingId,
            amountUzs: amountUzs,
            method: method,
          );

      state = state.copyWith(
        intent: intent,
        status: PaymentStatus.pending,
        loading: false,
        clearError: true,
      );
    } on AppException catch (error) {
      state = state.copyWith(loading: false, errorMessage: error.message);
      rethrow;
    } catch (_) {
      state = state.copyWith(
        loading: false,
        errorMessage: 'Could not start payment.',
      );
      throw const AppException('Could not start payment.');
    }
  }

  Future<PaymentStatus?> refreshStatus() async {
    final intent = state.intent;
    if (intent == null) {
      return null;
    }

    state = state.copyWith(loading: true, clearError: true);

    try {
      final status = await _read
          .read(paymentsRepositoryProvider)
          .getPaymentStatus(intent.id);

      state = state.copyWith(status: status, loading: false, clearError: true);
      return status;
    } on AppException catch (error) {
      state = state.copyWith(loading: false, errorMessage: error.message);
      return null;
    } catch (_) {
      state = state.copyWith(
        loading: false,
        errorMessage: 'Could not refresh payment status.',
      );
      return null;
    }
  }

  void clear() {
    state = const PaymentState.initial();
  }
}

final paymentControllerProvider =
    StateNotifierProvider<PaymentController, PaymentState>((ref) {
      return PaymentController(ref);
    });
