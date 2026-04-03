import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/errors/app_exception.dart';
import '../../application/booking_request_controller.dart';
import '../../domain/models/booking.dart';
import '../../../payments/application/payment_controller.dart';
import '../../../payments/domain/models/payment_method.dart';
import '../../../payments/domain/models/payment_status.dart';

class BookingPaymentScreen extends ConsumerStatefulWidget {
  const BookingPaymentScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<BookingPaymentScreen> createState() =>
      _BookingPaymentScreenState();
}

class _BookingPaymentScreenState extends ConsumerState<BookingPaymentScreen> {
  Future<void> _pay({
    required Booking booking,
    required PaymentMethod method,
  }) async {
    if (!booking.paymentRequired) {
      _show('Payment is not required for this booking (Free Stay).');
      return;
    }

    if (booking.isPaid) {
      _show('This booking is already paid.');
      return;
    }

    try {
      await ref
          .read(paymentControllerProvider.notifier)
          .startPayment(
            bookingId: widget.bookingId,
            amountUzs: booking.totalPriceUzs,
            method: method,
          );

      if (!mounted) {
        return;
      }

      final state = ref.read(paymentControllerProvider);
      final url = state.intent?.checkoutUrl;
      if (url != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Checkout created: $url')));
      }

      await _pollUntilResolved();
    } on AppException catch (error) {
      _show(error.message);
    } catch (_) {
      _show('Could not start payment.');
    }
  }

  Future<void> _pollUntilResolved() async {
    for (var i = 0; i < 4; i++) {
      final status = await ref
          .read(paymentControllerProvider.notifier)
          .refreshStatus();
      if (!mounted) {
        return;
      }

      if (status == PaymentStatus.succeeded) {
        _show('Payment succeeded. Booking is now paid.');
        return;
      }
      if (status == PaymentStatus.failed || status == PaymentStatus.cancelled) {
        _show('Payment failed or cancelled. Please retry.');
        return;
      }
    }

    _show('Payment is still processing. Check status later.');
  }

  void _show(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Booking?>(
      future: ref.read(bookingRepositoryProvider).getById(widget.bookingId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final booking = snapshot.data;
        if (booking == null) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go(RouteNames.bookings),
                icon: const Icon(Icons.arrow_back),
              ),
              title: const Text('Booking payment'),
            ),
            body: const Center(child: Text('Booking not found.')),
          );
        }

        final payment = ref.watch(paymentControllerProvider);

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              onPressed: () => context.canPop()
                  ? context.pop()
                  : context.go(RouteNames.bookings),
              icon: const Icon(Icons.arrow_back),
            ),
            title: const Text('Booking payment'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Pay for booking ${widget.bookingId}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text('Amount: ${booking.totalPriceUzs} UZS'),
              const SizedBox(height: 4),
              Text(
                'Payment required: ${booking.paymentRequired ? 'Yes' : 'No'}',
              ),
              const SizedBox(height: 4),
              Text('Paid: ${booking.isPaid ? 'Yes' : 'No'}'),
              const SizedBox(height: 16),
              if (payment.errorMessage != null)
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(payment.errorMessage!),
                  ),
                ),
              if (payment.intent != null)
                Card(
                  child: ListTile(
                    title: Text('Intent ${payment.intent!.id}'),
                    subtitle: Text(
                      'Method: ${payment.intent!.method.name.toUpperCase()}\n'
                      'Status: ${_statusText(payment.status ?? PaymentStatus.pending)}',
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed:
                    payment.loading ||
                        booking.isPaid ||
                        !booking.paymentRequired
                    ? null
                    : () => _pay(booking: booking, method: PaymentMethod.click),
                icon: const Icon(Icons.account_balance_wallet_outlined),
                label: const Text('Pay with Click'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed:
                    payment.loading ||
                        booking.isPaid ||
                        !booking.paymentRequired
                    ? null
                    : () => _pay(booking: booking, method: PaymentMethod.payme),
                icon: const Icon(Icons.payment_outlined),
                label: const Text('Pay with Payme'),
              ),
              const SizedBox(height: 12),
              if (payment.intent != null)
                TextButton(
                  onPressed: payment.loading
                      ? null
                      : () => ref
                            .read(paymentControllerProvider.notifier)
                            .refreshStatus(),
                  child: const Text('Refresh status'),
                ),
            ],
          ),
        );
      },
    );
  }

  String _statusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.processing:
        return 'Processing';
      case PaymentStatus.succeeded:
        return 'Succeeded';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.cancelled:
        return 'Cancelled';
    }
  }
}
