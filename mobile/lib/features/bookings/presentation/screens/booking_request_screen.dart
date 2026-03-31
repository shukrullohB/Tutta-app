import 'package:flutter/material.dart';
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
            appBar: AppBar(title: const Text('Booking request')),
            body: const Center(child: Text('Listing not found.')),
          );
        }

        final loading = ref.watch(bookingRequestControllerProvider).isLoading;

        return Scaffold(
          appBar: AppBar(title: const Text('Booking request')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                listing.title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text('${listing.city}, ${listing.district}'),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  title: const Text('Check-in'),
                  subtitle: Text(
                    _checkIn?.toIso8601String().split('T').first ?? '-',
                  ),
                  trailing: TextButton(
                    onPressed: loading ? null : _pickCheckIn,
                    child: const Text('Choose'),
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Check-out'),
                  subtitle: Text(
                    _checkOut?.toIso8601String().split('T').first ?? '-',
                  ),
                  trailing: TextButton(
                    onPressed: loading ? null : _pickCheckOut,
                    child: const Text('Choose'),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Guests:'),
                  const SizedBox(width: 12),
                  DropdownButton<int>(
                    value: _guests,
                    items: List.generate(
                      listing.maxGuests,
                      (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1}'),
                      ),
                    ),
                    onChanged: loading
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() => _guests = value);
                            }
                          },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Business rule: maximum booking length is 30 days.'),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: loading ? null : () => _submit(listing),
                child: Text(loading ? 'Submitting...' : 'Send request'),
              ),
            ],
          ),
        );
      },
    );
  }
}
