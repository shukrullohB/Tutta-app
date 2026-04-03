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
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go(RouteNames.home),
            icon: const Icon(Icons.arrow_back),
          ),
          title: const Text('Bookings'),
        ),
        body: const Center(child: Text('Please sign in to view bookings.')),
      );
    }

    if (role == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go(RouteNames.home),
            icon: const Icon(Icons.arrow_back),
          ),
          title: const Text('Bookings'),
        ),
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
              leading: IconButton(
                onPressed: () => context.go(RouteNames.home),
                icon: const Icon(Icons.arrow_back),
              ),
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
            leading: IconButton(
              onPressed: () => context.go(RouteNames.home),
              icon: const Icon(Icons.arrow_back),
            ),
            title: Text(role == AppRole.host ? 'Host requests' : 'My bookings'),
          ),
          body: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: _BookingScopeBanner(),
              ),
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
                    ? _BookingsEmptyState(role: role)
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
                                  () => ref
                                      .read(
                                        bookingLifecycleControllerProvider
                                            .notifier,
                                      )
                                      .complete(booking.id),
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
    final nights = booking.checkOutDate.difference(booking.checkInDate).inDays;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1E6F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Listing ${booking.listingId}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF172146),
                  ),
                ),
              ),
              _StatusBadge(status: booking.status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_month_outlined, size: 16, color: Color(0xFF5E6880)),
              const SizedBox(width: 6),
              Text(
                '${_date(booking.checkInDate)} - ${_date(booking.checkOutDate)}',
                style: const TextStyle(color: Color(0xFF3C465E)),
              ),
              const Spacer(),
              Text(
                '$nights night${nights == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: Color(0xFF6C7590),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.payments_outlined, size: 16, color: Color(0xFF5E6880)),
              const SizedBox(width: 6),
              Text(
                'Payment: ${_paymentLabel(booking)}',
                style: const TextStyle(color: Color(0xFF3C465E)),
              ),
              const Spacer(),
              Text(
                _formatUzs(booking.totalPriceUzs),
                style: const TextStyle(
                  color: Color(0xFF0F2F7B),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
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

      if (booking.status == BookingStatus.confirmed) {
        return [
          FilledButton(
            onPressed: loading ? null : onComplete,
            child: const Text('Mark as completed'),
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

    if (booking.status == BookingStatus.completed && booking.isReviewAllowed) {
      return [
        OutlinedButton(
          onPressed: loading ? null : onLeaveReview,
          child: const Text('Leave review'),
        ),
      ];
    }

    return const [];
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

  String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

  String _formatUzs(int value) {
    final raw = value.toString();
    final out = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      out.write(raw[i]);
      final remain = raw.length - i - 1;
      if (remain > 0 && remain % 3 == 0) {
        out.write(' ');
      }
    }
    return '${out.toString()} UZS';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: _statusColor(status).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _statusColor(status).withValues(alpha: 0.4)),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: _statusColor(status),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _statusLabel(BookingStatus status) {
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

Color _statusColor(BookingStatus status) {
  switch (status) {
    case BookingStatus.pendingHostApproval:
      return const Color(0xFFAF7A12);
    case BookingStatus.confirmed:
      return const Color(0xFF1A5EFF);
    case BookingStatus.cancelledByGuest:
    case BookingStatus.cancelledByHost:
      return const Color(0xFFD64545);
    case BookingStatus.completed:
      return const Color(0xFF23895B);
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

class _BookingScopeBanner extends StatelessWidget {
  const _BookingScopeBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tutta Booking Rules',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text(
            'Uzbekistan only. Short-term rental only. Max stay is 30 days.',
          ),
        ],
      ),
    );
  }
}

class _BookingsEmptyState extends StatelessWidget {
  const _BookingsEmptyState({required this.role});

  final AppRole role;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_busy_outlined, size: 34),
            const SizedBox(height: 10),
            Text(
              role == AppRole.host
                  ? 'No incoming booking requests yet.'
                  : 'No bookings found for this filter.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              role == AppRole.host
                  ? 'Once guests request short stays in Uzbekistan, requests will appear here.'
                  : 'Try changing the filter or discover listings in Uzbekistan to create your first booking.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
