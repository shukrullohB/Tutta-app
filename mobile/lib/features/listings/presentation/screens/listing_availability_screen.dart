import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../application/search_controller.dart';
import '../../domain/models/availability_day.dart';

class ListingAvailabilityScreen extends ConsumerStatefulWidget {
  const ListingAvailabilityScreen({super.key, required this.listingId});

  final String listingId;

  @override
  ConsumerState<ListingAvailabilityScreen> createState() =>
      _ListingAvailabilityScreenState();
}

class _ListingAvailabilityScreenState
    extends ConsumerState<ListingAvailabilityScreen> {
  bool _loading = true;
  bool _saving = false;
  final Map<DateTime, AvailabilityDay> _days = <DateTime, AvailabilityDay>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await ref
          .read(listingsRepositoryProvider)
          .getAvailability(widget.listingId);

      final today = DateTime.now();
      for (var i = 0; i < 30; i++) {
        final d = DateTime(today.year, today.month, today.day + i);
        _days[d] = AvailabilityDay(date: d, isAvailable: true);
      }
      for (final item in items) {
        final key = DateTime(item.date.year, item.date.month, item.date.day);
        _days[key] = AvailabilityDay(
          date: key,
          isAvailable: item.isAvailable,
          note: item.note,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = _days.entries.toList(growable: false)
      ..sort((a, b) => a.key.compareTo(b.key));
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(RouteNames.home),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Availability calendar'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final day = entries[index].value;
                return SwitchListTile(
                  value: day.isAvailable,
                  onChanged: (value) {
                    setState(() {
                      _days[entries[index].key] = AvailabilityDay(
                        date: day.date,
                        isAvailable: value,
                        note: day.note,
                      );
                    });
                  },
                  title: Text(_fmt(day.date)),
                  subtitle: Text(valueLabel(day.isAvailable)),
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving...' : 'Save calendar'),
        ),
      ),
    );
  }

  String _fmt(DateTime date) => '${date.day}.${date.month}.${date.year}';

  String valueLabel(bool isAvailable) => isAvailable ? 'Available' : 'Blocked';

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final values = _days.values.toList(growable: false);
      await ref.read(listingsRepositoryProvider).upsertAvailability(
            listingId: widget.listingId,
            days: values,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Availability updated.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save calendar.')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}
