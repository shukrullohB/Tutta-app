import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../listings/application/search_controller.dart';
import '../../../listings/domain/models/listing.dart';
import '../../application/booking_request_controller.dart';

class BookingRequestScreen extends ConsumerStatefulWidget {
  const BookingRequestScreen({super.key, required this.listingId});

  final String listingId;

  @override
  ConsumerState<BookingRequestScreen> createState() =>
      _BookingRequestScreenState();
}

class _BookingRequestScreenState extends ConsumerState<BookingRequestScreen> {
  DateTime? _checkIn;
  DateTime? _checkOut;
  int _guests = 1;
  _CheckoutPaymentMethod _paymentMethod = _CheckoutPaymentMethod.click;

  static const _monthsLong = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  Future<void> _pickCheckIn() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      initialDate: _checkIn ?? now,
    );

    if (picked != null) {
      setState(() {
        _checkIn = DateTime(picked.year, picked.month, picked.day);
        if (_checkOut != null && !_checkOut!.isAfter(_checkIn!)) {
          _checkOut = null;
        }
      });
    }
  }

  Future<void> _pickCheckOut() async {
    final start = _checkIn;
    if (start == null) {
      _show('Please choose check-in date first.');
      return;
    }

    final picked = await showDatePicker(
      context: context,
      firstDate: start.add(const Duration(days: 1)),
      lastDate: start.add(const Duration(days: 30)),
      initialDate: _checkOut ?? start.add(const Duration(days: 1)),
    );

    if (picked != null) {
      setState(() {
        _checkOut = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _submit(Listing listing) async {
    final checkIn = _checkIn;
    final checkOut = _checkOut;

    if (checkIn == null || checkOut == null) {
      _show('Please select check-in and check-out dates.');
      return;
    }

    final nights = checkOut.difference(checkIn).inDays;
    if (nights < 1 || nights > 30) {
      _show('Booking length must be between 1 and 30 days.');
      return;
    }

    if (_guests > listing.maxGuests) {
      _show('This listing supports maximum ${listing.maxGuests} guests.');
      return;
    }

    final nightly = listing.nightlyPriceUzs ?? 0;
    final total = nightly * nights;

    try {
      await ref
          .read(bookingRequestControllerProvider.notifier)
          .createRequest(
            listingId: listing.id,
            hostUserId: listing.hostId,
            checkIn: checkIn,
            checkOut: checkOut,
            guests: _guests,
            totalPriceUzs: total,
          );

      if (!mounted) {
        return;
      }

      _show('Booking request sent to host.');
      context.pop();
      context.pop();
    } on AppException catch (error) {
      _show(error.message);
    } catch (_) {
      _show('Could not create booking request. Try again.');
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatMoney(int amount) {
    final raw = amount.toString();
    final out = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      final fromEnd = raw.length - i;
      out.write(raw[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) {
        out.write(' ');
      }
    }
    return '${out.toString()} UZS';
  }

  String _monthLabel(DateTime date) {
    return '${_monthsLong[date.month - 1]} ${date.year}';
  }

  String _dayLabel(DateTime value) {
    return '${value.day}'.padLeft(2, '0');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Listing?>(
      future: ref.read(listingsRepositoryProvider).getById(widget.listingId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final listing = snapshot.data;
        if (listing == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Checkout')),
            body: const Center(child: Text('Listing not found.')),
          );
        }

        final loading = ref.watch(bookingRequestControllerProvider).isLoading;

        final nights = (_checkIn != null && _checkOut != null)
            ? _checkOut!.difference(_checkIn!).inDays
            : null;

        final isFreeStay = listing.nightlyPriceUzs == null;
        final nightly = listing.nightlyPriceUzs ?? 0;
        final subtotal = nights == null ? 0 : nightly * nights;
        final serviceFee = isFreeStay
            ? 0
            : (subtotal == 0 ? 0 : (subtotal * 0.07).round());
        final occupancyTax = isFreeStay
            ? 0
            : (subtotal == 0 ? 0 : (subtotal * 0.025).round());
        final total = subtotal + serviceFee + occupancyTax;

        return Scaffold(
          backgroundColor: const Color(0xFFF4F5F7),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 132),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF0B1B55),
                      ),
                    ),
                    const Text(
                      'Tutta',
                      style: TextStyle(
                        fontSize: 36 / 2,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0B1B55),
                      ),
                    ),
                    const Spacer(),
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFFEDEFF2),
                      child: ClipOval(
                        child: listing.imageUrls.isNotEmpty
                            ? Image.network(
                                listing.imageUrls.first,
                                width: 32,
                                height: 32,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.person,
                                  size: 16,
                                  color: Color(0xFF6D7280),
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                size: 16,
                                color: Color(0xFF6D7280),
                              ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 200.ms),
                const SizedBox(height: 14),
                const _StepProgressHeader().animate().fadeIn(duration: 220.ms),
                const SizedBox(height: 22),
                Row(
                  children: [
                    const Text(
                      'Select Dates',
                      style: TextStyle(
                        fontSize: 33 / 2,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0D1E57),
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF0D2D82),
                      ),
                      icon: const Icon(Icons.info, size: 14),
                      label: const Text('Flexible pricing'),
                    ),
                  ],
                ).animate().fadeIn(delay: 40.ms, duration: 220.ms),
                const SizedBox(height: 10),
                _CalendarPanel(
                  monthLabel: _monthLabel(_checkIn ?? DateTime.now()),
                  checkIn: _checkIn,
                  checkOut: _checkOut,
                  onPickCheckIn: loading ? null : _pickCheckIn,
                  onPickCheckOut: loading ? null : _pickCheckOut,
                ).animate().fadeIn(delay: 70.ms, duration: 240.ms),
                const SizedBox(height: 16),
                const Text(
                  'Payment Method',
                  style: TextStyle(
                    color: Color(0xFF0D1E57),
                    fontSize: 30 / 2,
                    fontWeight: FontWeight.w600,
                  ),
                ).animate().fadeIn(delay: 90.ms, duration: 220.ms),
                const SizedBox(height: 10),
                _PaymentMethodTile(
                  title: 'Click',
                  subtitle: 'Fast & Secure Payment',
                  icon: Icons.flash_on,
                  selected: _paymentMethod == _CheckoutPaymentMethod.click,
                  onTap: loading
                      ? null
                      : () => setState(
                          () => _paymentMethod = _CheckoutPaymentMethod.click,
                        ),
                ).animate().fadeIn(delay: 120.ms, duration: 220.ms),
                const SizedBox(height: 10),
                _PaymentMethodTile(
                  title: 'Payme',
                  subtitle: 'Modern Mobile Pay',
                  icon: Icons.account_balance_wallet_outlined,
                  selected: _paymentMethod == _CheckoutPaymentMethod.payme,
                  onTap: loading
                      ? null
                      : () => setState(
                          () => _paymentMethod = _CheckoutPaymentMethod.payme,
                        ),
                ).animate().fadeIn(delay: 150.ms, duration: 220.ms),
                const SizedBox(height: 16),
                _ReceiptCard(
                  listing: listing,
                  nights: nights,
                  subtotal: subtotal,
                  serviceFee: serviceFee,
                  occupancyTax: occupancyTax,
                  total: total,
                  formatMoney: _formatMoney,
                  isFreeStay: isFreeStay,
                ).animate().fadeIn(delay: 180.ms, duration: 240.ms),
                const SizedBox(height: 14),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 14,
                      color: Color(0xFF6A6F7E),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'SECURE CHECKOUT',
                      style: TextStyle(
                        color: Color(0xFF6A6F7E),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                    SizedBox(width: 20),
                    Icon(
                      Icons.headset_mic_outlined,
                      size: 14,
                      color: Color(0xFF6A6F7E),
                    ),
                    SizedBox(width: 6),
                    Text(
                      '24/7 CONCIERGE',
                      style: TextStyle(
                        color: Color(0xFF6A6F7E),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 200.ms, duration: 220.ms),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F5F7),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 12,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton(
                    onPressed: loading ? null : () => _submit(listing),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(60),
                      backgroundColor: const Color(0xFF082A7B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(loading ? 'Submitting...' : 'Confirm Booking'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'By clicking "Confirm Booking", you agree to\nTutta\'s Terms of Service and Cancellation Policy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF6B7183),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 240.ms).slideY(begin: 0.15, end: 0),
          ),
        );
      },
    );
  }
}

enum _CheckoutPaymentMethod { click, payme }

class _StepProgressHeader extends StatelessWidget {
  const _StepProgressHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'STEP 2 OF 3: CHECKOUT',
              style: TextStyle(
                color: Color(0xFF0D1E57),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'PAYMENT',
              style: TextStyle(
                color: Color(0xFF6A6F7E),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 5,
            value: 2 / 3,
            backgroundColor: const Color(0xFFE1E3E8),
            color: const Color(0xFF062978),
          ),
        ),
      ],
    );
  }
}

class _CalendarPanel extends StatelessWidget {
  const _CalendarPanel({
    required this.monthLabel,
    required this.checkIn,
    required this.checkOut,
    required this.onPickCheckIn,
    required this.onPickCheckOut,
  });

  final String monthLabel;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final VoidCallback? onPickCheckIn;
  final VoidCallback? onPickCheckOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                monthLabel,
                style: const TextStyle(
                  color: Color(0xFF141B2D),
                  fontWeight: FontWeight.w600,
                  fontSize: 31 / 2,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onPickCheckIn,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                onPressed: onPickCheckOut,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _WeekText('MO'),
              _WeekText('TU'),
              _WeekText('WE'),
              _WeekText('TH'),
              _WeekText('FR'),
              _WeekText('SA'),
              _WeekText('SU'),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _CalendarNumberCell(label: '28', muted: true),
              _CalendarNumberCell(label: '29', muted: true),
              _CalendarNumberCell(label: '30', muted: true),
              _CalendarNumberCell(label: '1'),
              _CalendarNumberCell(label: '2'),
              _CalendarNumberCell(label: '3'),
              _CalendarNumberCell(label: '4'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _CalendarNumberCell(
                label: '5',
                selected: checkIn != null,
                onTap: onPickCheckIn,
              ),
              _CalendarNumberCell(
                label: '6',
                inRange: checkIn != null && checkOut != null,
              ),
              _CalendarNumberCell(
                label: '7',
                inRange: checkIn != null && checkOut != null,
              ),
              _CalendarNumberCell(
                label: '8',
                inRange: checkIn != null && checkOut != null,
              ),
              _CalendarNumberCell(
                label: '9',
                selected: checkOut != null,
                onTap: onPickCheckOut,
              ),
              const _CalendarNumberCell(label: '10'),
              const _CalendarNumberCell(label: '11'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DatePickChip(
                  label: 'Check-in',
                  value: checkIn == null
                      ? 'Select'
                      : '${checkIn!.day}/${checkIn!.month}',
                  selected: checkIn != null,
                  onTap: onPickCheckIn,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DatePickChip(
                  label: 'Check-out',
                  value: checkOut == null
                      ? 'Select'
                      : '${checkOut!.day}/${checkOut!.month}',
                  selected: checkOut != null,
                  onTap: onPickCheckOut,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekText extends StatelessWidget {
  const _WeekText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF737989),
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
    );
  }
}

class _CalendarNumberCell extends StatelessWidget {
  const _CalendarNumberCell({
    required this.label,
    this.selected = false,
    this.inRange = false,
    this.muted = false,
    this.onTap,
  });

  final String label;
  final bool selected;
  final bool inRange;
  final bool muted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? const Color(0xFF062977)
        : inRange
        ? const Color(0xFFDCE7FB)
        : Colors.transparent;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: muted
                ? const Color(0xFFBDC1CB)
                : selected
                ? Colors.white
                : const Color(0xFF141B2D),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _DatePickChip extends StatelessWidget {
  const _DatePickChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0A2B7A) : const Color(0xFFF1F3F8),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? const Color(0xFFD1D9F0)
                    : const Color(0xFF697187),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF151B30),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? const Color(0xFF0A2B7A) : const Color(0xFFE2E5ED),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x140A2B7A),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF121829),
                      fontSize: 30 / 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF6B7183),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFCBD8F6)
                    : const Color(0xFFF0F1F4),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(icon, size: 20, color: const Color(0xFF0A2B7A)),
            ),
            const SizedBox(width: 10),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
              color: selected
                  ? const Color(0xFF0A2B7A)
                  : const Color(0xFFB0B5C2),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({
    required this.listing,
    required this.nights,
    required this.subtotal,
    required this.serviceFee,
    required this.occupancyTax,
    required this.total,
    required this.formatMoney,
    required this.isFreeStay,
  });

  final Listing listing;
  final int? nights;
  final int subtotal;
  final int serviceFee;
  final int occupancyTax;
  final int total;
  final String Function(int amount) formatMoney;
  final bool isFreeStay;

  @override
  Widget build(BuildContext context) {
    final nightsText = nights == null ? 'Select dates' : '$nights nights';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (listing.imageUrls.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 8.5,
                child: Image.network(
                  listing.imageUrls.first,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFE9ECF2),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.house,
                      color: Color(0xFF9AA0AE),
                      size: 30,
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.title,
                  style: const TextStyle(
                    color: Color(0xFF0F1C52),
                    fontSize: 34 / 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  nightsText,
                  style: const TextStyle(
                    color: Color(0xFF6B7183),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                _ReceiptRow(
                  label: isFreeStay ? 'Rate' : 'Nightly subtotal',
                  value: isFreeStay ? 'Free Stay' : formatMoney(subtotal),
                ),
                const SizedBox(height: 8),
                _ReceiptRow(
                  label: 'Service fee (Tutta Concierge)',
                  value: formatMoney(serviceFee),
                ),
                const SizedBox(height: 8),
                _ReceiptRow(
                  label: 'Occupancy taxes',
                  value: formatMoney(occupancyTax),
                ),
                const SizedBox(height: 10),
                const Divider(color: Color(0xFFE8EAF0), height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(
                            color: Color(0xFF172146),
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 1),
                        Text(
                          'UZS (INCL. ALL TAXES)',
                          style: TextStyle(
                            color: Color(0xFF7A8194),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      formatMoney(total),
                      style: const TextStyle(
                        color: Color(0xFF0A2B7A),
                        fontSize: 39 / 2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF2E3448), fontSize: 16),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          textAlign: TextAlign.end,
          style: const TextStyle(
            color: Color(0xFF11182E),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
