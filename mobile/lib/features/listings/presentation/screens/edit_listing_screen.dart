import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/errors/app_exception.dart';
import '../../application/create_listing_controller.dart';
import '../../application/search_controller.dart';
import '../../domain/models/create_listing_input.dart';
import '../../domain/models/listing.dart';

class EditListingScreen extends ConsumerStatefulWidget {
  const EditListingScreen({super.key, required this.listingId});

  final String listingId;

  @override
  ConsumerState<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends ConsumerState<EditListingScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _metroController = TextEditingController();
  final _priceController = TextEditingController();
  final _languagesCommunicationController = TextEditingController();
  final _languagesPracticeController = TextEditingController();
  final _freeStayTermsController = TextEditingController();

  bool _initialized = false;
  ListingType _listingType = ListingType.apartment;
  int _maxGuests = 1;
  int _minDays = 1;
  int _maxDays = 7;
  bool _showPhone = false;
  bool _hostLivesTogether = true;

  bool get _isFreeStay => _listingType == ListingType.freeStay;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _landmarkController.dispose();
    _metroController.dispose();
    _priceController.dispose();
    _languagesCommunicationController.dispose();
    _languagesPracticeController.dispose();
    _freeStayTermsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final submitState = ref.watch(createListingControllerProvider);
    final isSubmitting = submitState.isLoading;

    return FutureBuilder<Listing?>(
      future: ref.read(listingsRepositoryProvider).getById(widget.listingId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final listing = snapshot.data;
        if (listing == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Edit listing')),
            body: const Center(child: Text('Listing not found.')),
          );
        }

        if (!_initialized) {
          _initialized = true;
          _titleController.text = listing.title;
          _descriptionController.text = listing.description ?? '';
          _cityController.text = listing.city;
          _districtController.text = listing.district;
          _landmarkController.text = listing.landmark ?? '';
          _metroController.text = listing.metro ?? '';
          _priceController.text = listing.nightlyPriceUzs?.toString() ?? '';
          _listingType = listing.type;
          _maxGuests = listing.maxGuests;
          _minDays = listing.minDays;
          _maxDays = listing.maxDays;
        }

        ref.listen<AsyncValue<void>>(createListingControllerProvider, (prev, next) {
          if (!mounted) {
            return;
          }
          if (next.hasError) {
            final error = next.error;
            final message = error is AppException ? error.message : 'Failed to update listing.';
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
          }
        });

        return Scaffold(
          appBar: AppBar(
            title: const Text('Edit listing'),
            leading: IconButton(
              onPressed: () => context.canPop() ? context.pop() : context.go(RouteNames.home),
              icon: const Icon(Icons.arrow_back),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            children: [
              DropdownButtonFormField<ListingType>(
                initialValue: _listingType,
                decoration: const InputDecoration(labelText: 'Listing type'),
                items: const [
                  DropdownMenuItem(value: ListingType.apartment, child: Text('Apartment')),
                  DropdownMenuItem(value: ListingType.room, child: Text('Room')),
                  DropdownMenuItem(value: ListingType.homePart, child: Text('Part of home')),
                  DropdownMenuItem(
                    value: ListingType.freeStay,
                    child: Text('Free Stay / Language Exchange'),
                  ),
                ],
                onChanged: isSubmitting
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _listingType = value;
                            if (_isFreeStay) {
                              _priceController.clear();
                            }
                          });
                        }
                      },
              ),
              const SizedBox(height: 10),
              TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title *')),
              const SizedBox(height: 10),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description *'),
              ),
              const SizedBox(height: 10),
              TextField(controller: _cityController, decoration: const InputDecoration(labelText: 'City *')),
              const SizedBox(height: 10),
              TextField(controller: _districtController, decoration: const InputDecoration(labelText: 'District *')),
              const SizedBox(height: 10),
              TextField(controller: _landmarkController, decoration: const InputDecoration(labelText: 'Landmark')),
              const SizedBox(height: 10),
              TextField(controller: _metroController, decoration: const InputDecoration(labelText: 'Metro')),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _maxGuests,
                      decoration: const InputDecoration(labelText: 'Max guests'),
                      items: List.generate(
                        10,
                        (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
                      ),
                      onChanged: isSubmitting
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() => _maxGuests = value);
                              }
                            },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _minDays,
                      decoration: const InputDecoration(labelText: 'Min days'),
                      items: List.generate(
                        30,
                        (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
                      ),
                      onChanged: isSubmitting
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() => _minDays = value);
                              }
                            },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _maxDays,
                      decoration: const InputDecoration(labelText: 'Max days'),
                      items: List.generate(
                        30,
                        (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
                      ),
                      onChanged: isSubmitting
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() => _maxDays = value);
                              }
                            },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                value: _showPhone,
                onChanged: isSubmitting ? null : (value) => setState(() => _showPhone = value),
                title: const Text('Show host phone in listing'),
                contentPadding: EdgeInsets.zero,
              ),
              if (!_isFreeStay) ...[
                TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Nightly price (UZS) *'),
                ),
              ] else ...[
                TextField(
                  controller: _languagesCommunicationController,
                  decoration: const InputDecoration(
                    labelText: 'Languages for communication *',
                    hintText: 'uz, en, ru',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _languagesPracticeController,
                  decoration: const InputDecoration(
                    labelText: 'Languages for practice *',
                    hintText: 'en',
                  ),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  value: _hostLivesTogether,
                  onChanged: isSubmitting ? null : (v) => setState(() => _hostLivesTogether = v),
                  title: const Text('Host lives together'),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _freeStayTermsController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Free stay terms *',
                  ),
                ),
              ],
            ],
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: FilledButton(
              onPressed: isSubmitting ? null : _save,
              child: Text(isSubmitting ? 'Saving...' : 'Save changes'),
            ),
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _cityController.text.trim().isEmpty ||
        _districtController.text.trim().isEmpty) {
      _show('Please fill required fields.');
      return;
    }
    if (_minDays < 1 || _maxDays < _minDays || _maxDays > 30) {
      _show('Stay limits must be valid and up to 30 days.');
      return;
    }
    if (!_isFreeStay) {
      final price = int.tryParse(_priceController.text.trim());
      if (price == null || price <= 0) {
        _show('Enter valid nightly price.');
        return;
      }
    } else {
      if (_languagesCommunicationController.text.trim().isEmpty ||
          _languagesPracticeController.text.trim().isEmpty ||
          _freeStayTermsController.text.trim().isEmpty) {
        _show('Fill free stay profile fields.');
        return;
      }
    }

    final input = CreateListingInput(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      city: _cityController.text.trim(),
      district: _districtController.text.trim(),
      landmark: _landmarkController.text.trim().isEmpty ? null : _landmarkController.text.trim(),
      metro: _metroController.text.trim().isEmpty ? null : _metroController.text.trim(),
      type: _listingType,
      nightlyPriceUzs: _isFreeStay ? null : int.tryParse(_priceController.text.trim()),
      maxGuests: _maxGuests,
      minDays: _minDays,
      maxDays: _maxDays,
      showPhone: _showPhone,
      freeStayProfile: _isFreeStay
          ? <String, dynamic>{
              'languages_communication': _splitCsv(_languagesCommunicationController.text),
              'languages_practice': _splitCsv(_languagesPracticeController.text),
              'host_lives_together': _hostLivesTogether,
              'terms': _freeStayTermsController.text.trim(),
            }
          : const <String, dynamic>{},
    );

    await ref.read(createListingControllerProvider.notifier).update(
          listingId: widget.listingId,
          input: input,
        );

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Listing updated and sent for moderation.')),
    );
    context.go('${RouteNames.listingDetails}/${widget.listingId}');
  }

  List<String> _splitCsv(String value) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
