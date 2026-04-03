import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/errors/app_exception.dart';
import '../../application/create_listing_controller.dart';
import '../../application/search_controller.dart';
import '../../domain/models/create_listing_input.dart';
import '../../domain/models/listing.dart';
import '../widgets/location_picker_sheet.dart';

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
  final ImagePicker _imagePicker = ImagePicker();
  late final Future<Listing?> _listingFuture;

  bool _initialized = false;
  ListingType _listingType = ListingType.apartment;
  int _maxGuests = 1;
  int _minDays = 1;
  int _maxDays = 7;
  bool _showPhone = false;
  bool _hostLivesTogether = true;
  String? _mapCoordinates;
  final Set<ListingAmenity> _selectedAmenities = <ListingAmenity>{};
  final List<XFile> _selectedImageFiles = <XFile>[];
  final List<String> _existingImageUrls = <String>[];
  final Set<String> _removedExistingImageUrls = <String>{};
  ProviderSubscription<AsyncValue<void>>? _submitListener;

  bool get _isFreeStay => _listingType == ListingType.freeStay;

  @override
  void initState() {
    super.initState();
    _listingFuture = ref
        .read(listingsRepositoryProvider)
        .getById(widget.listingId);
    _submitListener = ref.listenManual<AsyncValue<void>>(
      createListingControllerProvider,
      (prev, next) {
        if (!mounted || !next.hasError) {
          return;
        }
        final error = next.error;
        final message = error is AppException
            ? error.message
            : 'Failed to update listing.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      },
    );
  }

  @override
  void dispose() {
    _submitListener?.close();
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
      future: _listingFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
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
          _selectedAmenities
            ..clear()
            ..addAll(listing.amenities);
          _hostLivesTogether = listing.amenities.contains(
            ListingAmenity.hostLivesTogether,
          );
          _existingImageUrls
            ..clear()
            ..addAll(listing.imageUrls);
          _removedExistingImageUrls.clear();
          _mapCoordinates = _extractCoordinates(listing.landmark ?? '');
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Edit listing'),
            leading: IconButton(
              onPressed: () => context.canPop()
                  ? context.pop()
                  : context.go(RouteNames.home),
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
                  DropdownMenuItem(
                    value: ListingType.apartment,
                    child: Text('Apartment'),
                  ),
                  DropdownMenuItem(
                    value: ListingType.room,
                    child: Text('Room'),
                  ),
                  DropdownMenuItem(
                    value: ListingType.homePart,
                    child: Text('Part of home'),
                  ),
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
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title *'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description *'),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Photos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Add your own property photos. New photos will be uploaded with the update.',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              ),
              const SizedBox(height: 12),
              if (_existingImageUrls.isNotEmpty)
                SizedBox(
                  height: 88,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _existingImageUrls.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) => SizedBox(
                      key: ValueKey<String>(_existingImageUrls[index]),
                      width: 88,
                      height: 88,
                      child: _ExistingEditImagePreview(
                        imageUrl: _existingImageUrls[index],
                        onRemove: () => setState(() {
                          final removed = _existingImageUrls.removeAt(index);
                          _removedExistingImageUrls.add(removed);
                        }),
                      ),
                    ),
                  ),
                ),
              if (_existingImageUrls.isNotEmpty) const SizedBox(height: 10),
              if (_selectedImageFiles.isNotEmpty)
                SizedBox(
                  height: 96,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImageFiles.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) => _PickedEditImagePreview(
                      key: ValueKey<String>(_selectedImageFiles[index].path),
                      file: _selectedImageFiles[index],
                      onRemove: () => setState(() {
                        _selectedImageFiles.removeAt(index);
                      }),
                    ),
                  ),
                ),
              if (_selectedImageFiles.isNotEmpty) const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: isSubmitting ? null : _pickImages,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text(
                  _selectedImageFiles.isEmpty
                      ? 'Upload photos'
                      : 'Add more photos',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City *'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _districtController,
                decoration: const InputDecoration(labelText: 'District *'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _landmarkController,
                decoration: const InputDecoration(labelText: 'Landmark'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _metroController,
                decoration: const InputDecoration(labelText: 'Metro'),
              ),
              const SizedBox(height: 10),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surfaceTint,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _editorText(
                          context,
                          en: 'Exact map location',
                          ru: 'Точная локация',
                          uz: 'Aniq joylashuv',
                        ),
                        style: const TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        (_mapCoordinates ?? '').trim().isEmpty
                            ? _editorText(
                                context,
                                en:
                                    'Pick an exact point that guests can open in Google Maps.',
                                ru:
                                    'Выберите точку на карте для Google Maps.',
                                uz:
                                    'Google Maps uchun aniq nuqtani xaritada tanlang.',
                              )
                            : _mapCoordinates!,
                        style: TextStyle(
                          color: (_mapCoordinates ?? '').trim().isEmpty
                              ? AppColors.textMuted
                              : AppColors.textSoft,
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: isSubmitting
                            ? null
                            : () => _pickMapCoordinates(context),
                        icon: const Icon(Icons.location_searching_rounded),
                        label: Text(
                          _editorText(
                            context,
                            en: 'Pick on map',
                            ru: 'Выбрать на карте',
                            uz: 'Xaritada tanlash',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _maxGuests,
                      decoration: const InputDecoration(
                        labelText: 'Max guests',
                      ),
                      items: List.generate(
                        10,
                        (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text('${i + 1}'),
                        ),
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
                        (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text('${i + 1}'),
                        ),
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
                        (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text('${i + 1}'),
                        ),
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
                onChanged: isSubmitting
                    ? null
                    : (value) => setState(() => _showPhone = value),
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primarySoftStrong,
                title: const Text('Show host phone in listing'),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _editorText(
                    context,
                    en: 'Amenities',
                    ru: 'Удобства',
                    uz: 'Qulayliklar',
                  ),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _editorAmenityOptions
                    .map(
                      (amenity) => FilterChip(
                        key: ValueKey<String>('edit_amenity_${amenity.name}'),
                        showCheckmark: true,
                        avatar: Icon(
                          _editorAmenityIcon(amenity),
                          size: 16,
                          color: _selectedAmenities.contains(amenity)
                              ? AppColors.primaryDeep
                              : const Color(0xFF6B7280),
                        ),
                        selectedColor: AppColors.primarySoft,
                        checkmarkColor: AppColors.primaryDeep,
                        backgroundColor: AppColors.surfaceTint,
                        side: BorderSide(
                          color: _selectedAmenities.contains(amenity)
                              ? AppColors.primary
                              : AppColors.border,
                          width: _selectedAmenities.contains(amenity) ? 1.4 : 1,
                        ),
                        label: Text(
                          _editorAmenityLabel(context, amenity),
                          style: TextStyle(
                            color: _selectedAmenities.contains(amenity)
                                ? AppColors.primaryDeep
                                : AppColors.textSoft,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        selected: _selectedAmenities.contains(amenity),
                        onSelected: isSubmitting
                            ? null
                            : (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedAmenities.add(amenity);
                                  } else {
                                    _selectedAmenities.remove(amenity);
                                  }
                                  if (amenity ==
                                      ListingAmenity.hostLivesTogether) {
                                    _hostLivesTogether = selected;
                                  }
                                });
                              },
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: 10),
              if (!_isFreeStay) ...[
                TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Nightly price (UZS) *',
                  ),
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
                  onChanged: isSubmitting
                      ? null
                      : (v) => setState(() {
                          _hostLivesTogether = v;
                          if (v) {
                            _selectedAmenities.add(
                              ListingAmenity.hostLivesTogether,
                            );
                          } else {
                            _selectedAmenities.remove(
                              ListingAmenity.hostLivesTogether,
                            );
                          }
                        }),
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primarySoftStrong,
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
      landmark: _landmarkController.text.trim().isEmpty
          ? null
          : _landmarkController.text.trim(),
      metro: _metroController.text.trim().isEmpty
          ? null
          : _metroController.text.trim(),
      type: _listingType,
      amenities: _selectedAmenities.toList(growable: false),
      nightlyPriceUzs: _isFreeStay
          ? null
          : int.tryParse(_priceController.text.trim()),
      maxGuests: _maxGuests,
      minDays: _minDays,
      maxDays: _maxDays,
      showPhone: _showPhone,
      imageFiles: _selectedImageFiles.toList(growable: false),
      removeImageUrls: _removedExistingImageUrls.toList(growable: false),
      mapCoordinates: _mapCoordinates,
      freeStayProfile: _isFreeStay
          ? <String, dynamic>{
              'languages_communication': _splitCsv(
                _languagesCommunicationController.text,
              ),
              'languages_practice': _splitCsv(
                _languagesPracticeController.text,
              ),
              'host_lives_together': _hostLivesTogether,
              'terms': _freeStayTermsController.text.trim(),
            }
          : const <String, dynamic>{},
    );

    final updatedListing = await ref
        .read(createListingControllerProvider.notifier)
        .update(listingId: widget.listingId, input: input);
    final syncInfo = ref.read(hostListingsSyncInfoProvider);

    if (!mounted) {
      return;
    }
    final savedMessage =
        syncInfo.state == HostListingsSyncState.warning &&
            (syncInfo.message?.isNotEmpty ?? false)
        ? 'Listing updated. ${syncInfo.message}'
        : 'Listing updated and sent for moderation.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(savedMessage)));
    context.go(RouteNames.listingDetailsById(updatedListing.id));
  }

  List<String> _splitCsv(String value) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  void _show(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickImages() async {
    final picked = await _imagePicker.pickMultiImage(imageQuality: 88);
    if (picked.isEmpty) {
      return;
    }
    setState(() {
      _selectedImageFiles.addAll(picked.take(10 - _selectedImageFiles.length));
    });
  }

  Future<void> _pickMapCoordinates(BuildContext context) async {
    final selected = await pickListingCoordinates(
      context,
      initialCoordinates: _mapCoordinates,
      cityHint: _cityController.text,
    );
    if (!mounted || selected == null || selected.trim().isEmpty) {
      return;
    }
    setState(() => _mapCoordinates = selected.trim());
  }

  String? _extractCoordinates(String value) {
    final match = RegExp(
      r'(-?\d+\.\d+)\s*,\s*(-?\d+\.\d+)',
    ).firstMatch(value);
    if (match == null) {
      return null;
    }
    final lat = double.tryParse(match.group(1) ?? '');
    final lng = double.tryParse(match.group(2) ?? '');
    if (lat == null || lng == null) {
      return null;
    }
    return '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
  }
}

class _ExistingEditImagePreview extends StatelessWidget {
  const _ExistingEditImagePreview({
    required this.imageUrl,
    required this.onRemove,
  });

  final String imageUrl;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox.expand(
            child: imageUrl.startsWith('assets/')
                ? Image.asset(imageUrl, fit: BoxFit.cover)
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: const Color(0xFFF3E5D7),
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(160),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PickedEditImagePreview extends StatelessWidget {
  const _PickedEditImagePreview({
    super.key,
    required this.file,
    required this.onRemove,
  });

  final XFile file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            width: 96,
            height: 96,
            child: FutureBuilder<Uint8List>(
              future: file.readAsBytes(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Container(
                    color: const Color(0xFFF3E5D7),
                    alignment: Alignment.center,
                    child: const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                return Image.memory(snapshot.data!, fit: BoxFit.cover);
              },
            ),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(160),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

const List<ListingAmenity> _editorAmenityOptions = <ListingAmenity>[
  ListingAmenity.wifi,
  ListingAmenity.airConditioner,
  ListingAmenity.kitchen,
  ListingAmenity.washingMachine,
  ListingAmenity.parking,
  ListingAmenity.privateBathroom,
  ListingAmenity.kidsAllowed,
  ListingAmenity.petsAllowed,
  ListingAmenity.womenOnly,
  ListingAmenity.menOnly,
  ListingAmenity.hostLivesTogether,
  ListingAmenity.instantConfirm,
];

String _editorText(
  BuildContext context, {
  required String en,
  required String ru,
  required String uz,
}) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'ru':
      return ru;
    case 'uz':
      return uz;
    default:
      return en;
  }
}

String _editorAmenityLabel(BuildContext context, ListingAmenity amenity) {
  switch (amenity) {
    case ListingAmenity.wifi:
      return 'Wi‑Fi';
    case ListingAmenity.airConditioner:
      return _editorText(
        context,
        en: 'Air conditioner',
        ru: 'Кондиционер',
        uz: 'Konditsioner',
      );
    case ListingAmenity.kitchen:
      return _editorText(context, en: 'Kitchen', ru: 'Кухня', uz: 'Oshxona');
    case ListingAmenity.washingMachine:
      return _editorText(
        context,
        en: 'Washing machine',
        ru: 'Стиральная машина',
        uz: 'Kir yuvish mashinasi',
      );
    case ListingAmenity.parking:
      return _editorText(
        context,
        en: 'Parking',
        ru: 'Парковка',
        uz: 'Avtoturargoh',
      );
    case ListingAmenity.privateBathroom:
      return _editorText(
        context,
        en: 'Private bathroom',
        ru: 'Отдельная ванная',
        uz: 'Shaxsiy hammom',
      );
    case ListingAmenity.kidsAllowed:
      return _editorText(
        context,
        en: 'Children allowed',
        ru: 'Можно с детьми',
        uz: 'Bolalar mumkin',
      );
    case ListingAmenity.petsAllowed:
      return _editorText(
        context,
        en: 'Pets allowed',
        ru: 'Можно с животными',
        uz: 'Uy hayvonlari mumkin',
      );
    case ListingAmenity.womenOnly:
      return _editorText(
        context,
        en: 'Women only',
        ru: 'Только для женщин',
        uz: 'Faqat ayollar uchun',
      );
    case ListingAmenity.menOnly:
      return _editorText(
        context,
        en: 'Men only',
        ru: 'Только для мужчин',
        uz: 'Faqat erkaklar uchun',
      );
    case ListingAmenity.hostLivesTogether:
      return _editorText(
        context,
        en: 'Host lives together',
        ru: 'Хозяин живёт вместе',
        uz: 'Host birga yashaydi',
      );
    case ListingAmenity.instantConfirm:
      return _editorText(
        context,
        en: 'Instant confirm',
        ru: 'Мгновенное подтверждение',
        uz: 'Darhol tasdiq',
      );
  }
}

IconData _editorAmenityIcon(ListingAmenity amenity) {
  switch (amenity) {
    case ListingAmenity.wifi:
      return Icons.wifi_rounded;
    case ListingAmenity.airConditioner:
      return Icons.ac_unit_rounded;
    case ListingAmenity.kitchen:
      return Icons.kitchen_outlined;
    case ListingAmenity.washingMachine:
      return Icons.local_laundry_service_outlined;
    case ListingAmenity.parking:
      return Icons.local_parking_rounded;
    case ListingAmenity.privateBathroom:
      return Icons.bathtub_outlined;
    case ListingAmenity.kidsAllowed:
      return Icons.child_friendly_rounded;
    case ListingAmenity.petsAllowed:
      return Icons.pets_rounded;
    case ListingAmenity.womenOnly:
      return Icons.female_rounded;
    case ListingAmenity.menOnly:
      return Icons.male_rounded;
    case ListingAmenity.hostLivesTogether:
      return Icons.people_outline_rounded;
    case ListingAmenity.instantConfirm:
      return Icons.flash_on_rounded;
  }
}
