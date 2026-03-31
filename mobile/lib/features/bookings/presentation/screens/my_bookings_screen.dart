import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/enums/app_role.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../home/application/app_session_controller.dart';
import '../../application/booking_lifecycle_controller.dart';
import '../../application/booking_request_controller.dart';
import '../../domain/models/booking.dart';

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen> {
  int _reloadToken = 0;
  BookingStatus? _statusFilter;

  Future<void> _runAction(Future<void> Function() action) async {
    try {
      await action();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Updated successfully.')));
      setState(() => _reloadToken++);
    } on AppException catch (error) {
      _show(error.message);
    } catch (_) {
      _show('Could not update booking status.');
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authControllerProvider).valueOrNull?.user?.id;
    final role = ref.watch(appSessionControllerProvider).activeRole;
    final loading = ref.watch(bookingLifecycleControllerProvider).isLoading;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bookings')),
        body: const Center(child: Text('Please sign in to view bookings.')),
      );
    }

    if (role == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bookings')),
        body: const Center(child: Text('Select renter or host mode first.')),
      );
    }

    final future = role == AppRole.host
        ? ref.read(bookingRepositoryProvider).getHostBookings(userId)
        : ref.read(bookingRepositoryProvider).getGuestBookings(userId);

    return FutureBuilder<List<Booking>>(
      key: ValueKey('bookings_$role$_reloadToken'),
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                role == AppRole.host ? 'Host requests' : 'My bookings',
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final rawItems = snapshot.data ?? const <Booking>[];
        final items = _statusFilter == null
            ? rawItems
            : rawItems
                  .where((booking) => booking.status == _statusFilter)
                  .toList(growable: false);

        return Scaffold(
          appBar: AppBar(
            title: Text(role == AppRole.host ? 'Host requests' : 'My bookings'),
          ),
          body: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _statusFilter == null,
                      onSelected: (_) => setState(() => _statusFilter = null),
                    ),
                    const SizedBox(width: 8),
                    ...BookingStatus.values.map(
                      (status) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(_filterLabel(status)),
                          selected: _statusFilter == status,
                          onSelected: (_) =>
                              setState(() => _statusFilter = status),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Text(
                          role == AppRole.host
                              ? 'No incoming booking requests for this filter.'
                              : 'No bookings for this filter.',
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (role == AppRole.host)
                            _HostSummary(rawItems: rawItems)
                          else
                            _GuestSummary(rawItems: rawItems),
                          const SizedBox(height: 12),
                          ...items.indexed.map((entry) {
                            final index = entry.$1;
                            final booking = entry.$2;
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index == items.length - 1 ? 0 : 10,
                              ),
                              child: _BookingTile(
                                booking: booking,
                                role: role,
                                loading: loading,
                                onConfirm: () => _runAction(
                                  () => ref
                                      .read(
                                        bookingLifecycleControllerProvider
                                            .notifier,
                                      )
                                      .confirm(booking.id),
                                ),
                                onReject: () => _runAction(
                                  () => ref
                                      .read(
                                        bookingLifecycleControllerProvider
                                            .notifier,
                                      )
                                      .reject(booking.id),
                                ),
                                onCancelByGuest: () => _runAction(
                                  () => ref
                                      .read(
                                        bookingLifecycleControllerProvider
                                            .notifier,
                                      )
                                      .cancelByGuest(booking.id),
                                ),
                                onComplete: () => _runAction(
                                  () async {},
                                ),
                                onProceedToPayment: () => context.push(
                                  '${RouteNames.bookingPayment}/${booking.id}',
                                ),
                                onLeaveReview: () => context.push(
                                  '${RouteNames.reviewSubmit}/${booking.id}',
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _filterLabel(BookingStatus status) {
    switch (status) {
      case BookingStatus.pendingHostApproval:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.cancelledByGuest:
        return 'Guest cancelled';
      case BookingStatus.cancelledByHost:
        return 'Host cancelled';
      case BookingStatus.completed:
        return 'Completed';
    }
  }
}

class _BookingTile extends StatelessWidget {
  const _BookingTile({
    required this.booking,
    required this.role,
    required this.loading,
    required this.onConfirm,
    required this.onReject,
    required this.onCancelByGuest,
    required this.onComplete,
    required this.onProceedToPayment,
    required this.onLeaveReview,
  });

  final Booking booking;
  final AppRole role;
  final bool loading;
  final VoidCallback onConfirm;
  final VoidCallback onReject;
  final VoidCallback onCancelByGuest;
  final VoidCallback onComplete;
  final VoidCallback onProceedToPayment;
  final VoidCallback onLeaveReview;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Listing ${booking.listingId}'),
          const SizedBox(height: 6),
          Text(
            '${booking.checkInDate.toIso8601String().split('T').first} - '
            '${booking.checkOutDate.toIso8601String().split('T').first}',
          ),
          const SizedBox(height: 4),
          Text('Status: ${_statusLabel(booking.status)}'),
          const SizedBox(height: 4),
          Text('Payment: ${_paymentLabel(booking)}'),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: _actions()),
        ],
      ),
    );
  }

  List<Widget> _actions() {
    if (role == AppRole.host) {
      if (booking.status == BookingStatus.pendingHostApproval) {
        return [
          FilledButton(
            onPressed: loading ? null : onConfirm,
            child: const Text('Confirm'),
          ),
          OutlinedButton(
            onPressed: loading ? null : onReject,
            child: const Text('Reject'),
          ),
        ];
      }

      return const [];
    }

    if (booking.status == BookingStatus.pendingHostApproval) {
      return [
        OutlinedButton(
          onPressed: loading ? null : onCancelByGuest,
          child: const Text('Cancel request'),
        ),
      ];
    }

    if (booking.status == BookingStatus.confirmed) {
      final actions = <Widget>[];
      if (booking.paymentRequired && !booking.isPaid) {
        actions.add(
          FilledButton(
            onPressed: loading ? null : onProceedToPayment,
            child: const Text('Proceed to payment'),
          ),
        );
      }
      actions.add(
        OutlinedButton(
          onPressed: loading ? null : onCancelByGuest,
          child: const Text('Cancel (24h rule)'),
        ),
      );
      return actions;
    }

    if (booking.status == BookingStatus.confirmed && booking.isReviewAllowed) {
      return [
        OutlinedButton(
          onPressed: loading ? null : onLeaveReview,
          child: const Text('Leave review'),
        ),
      ];
    }

    return const [];
  }

  String _statusLabel(BookingStatus status) {
    switch (status) {
      case BookingStatus.pendingHostApproval:
        return 'Pending host approval';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.cancelledByGuest:
        return 'Cancelled by guest';
      case BookingStatus.cancelledByHost:
        return 'Cancelled by host';
      case BookingStatus.completed:
        return 'Completed';
    }
  }

  String _paymentLabel(Booking booking) {
    if (!booking.paymentRequired) {
      return 'Not required';
    }

    if (booking.paymentStatus == null) {
      return 'Not paid';
    }
    return booking.paymentStatus.toString().split('.').last;
  }
}

class _HostSummary extends StatelessWidget {
  const _HostSummary({required this.rawItems});

  final List<Booking> rawItems;

  @override
  Widget build(BuildContext context) {
    final pending = rawItems
        .where((booking) => booking.status == BookingStatus.pendingHostApproval)
        .length;
    final confirmed = rawItems
        .where((booking) => booking.status == BookingStatus.confirmed)
        .length;
    final completed = rawItems
        .where((booking) => booking.status == BookingStatus.completed)
        .length;
    final rejected = rawItems
        .where((booking) => booking.status == BookingStatus.cancelledByHost)
        .length;
    final handled = confirmed + completed + rejected;
    final acceptanceRate = handled == 0
        ? 0
        : ((confirmed + completed) * 100 / handled).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricChip(label: 'Pending', value: '$pending'),
            _MetricChip(label: 'Confirmed', value: '$confirmed'),
            _MetricChip(label: 'Completed', value: '$completed'),
            _MetricChip(label: 'Acceptance', value: '$acceptanceRate%'),
          ],
        ),
      ),
    );
  }
}

class _GuestSummary extends StatelessWidget {
  const _GuestSummary({required this.rawItems});

  final List<Booking> rawItems;

  @override
  Widget build(BuildContext context) {
    final active = rawItems
        .where(
          (booking) =>
              booking.status == BookingStatus.pendingHostApproval ||
              booking.status == BookingStatus.confirmed,
        )
        .length;
    final completed = rawItems
        .where((booking) => booking.status == BookingStatus.completed)
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricChip(label: 'Active', value: '$active'),
            _MetricChip(label: 'Completed', value: '$completed'),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
