import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../home/application/app_session_controller.dart';
import '../../application/create_listing_controller.dart';
import '../../application/search_controller.dart';
import '../../domain/models/create_listing_input.dart';
import '../../domain/models/listing.dart';
import '../widgets/location_picker_sheet.dart';

class CreateListingScreen extends ConsumerStatefulWidget {
  const CreateListingScreen({super.key});

  @override
  ConsumerState<CreateListingScreen> createState() =>
      _CreateListingScreenState();
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
  static const _maxImages = 10;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController(text: 'Tashkent');
  final _districtController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _metroController = TextEditingController();
  final _priceController = TextEditingController();
  final _languagesCommunicationController = TextEditingController();
  final _languagesPracticeController = TextEditingController();
  final _freeStayTermsController = TextEditingController();

  int _currentStep = 0;
  ListingType _listingType = ListingType.apartment;
  int _maxGuests = 1;
  int _minDays = 1;
  int _maxDays = 7;
  bool _showPhone = false;
  bool _hostLivesTogether = true;
  String? _mapCoordinates;
  final Set<ListingAmenity> _selectedAmenities = <ListingAmenity>{};
  final List<XFile> _selectedImageFiles = <XFile>[];
  final ImagePicker _imagePicker = ImagePicker();
  late final ProviderSubscription<AsyncValue<void>> _submitSubscription;

  bool get _isFreeStay => _listingType == ListingType.freeStay;

  @override
  void initState() {
    super.initState();
    _submitSubscription = ref.listenManual<AsyncValue<void>>(
      createListingControllerProvider,
      (prev, next) {
        if (!mounted || !next.hasError) {
          return;
        }
        final error = next.error;
        final message = error is AppException
            ? error.message
            : _CreateListingCopy.of(context).createFailed;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      },
    );
  }

  @override
  void dispose() {
    _submitSubscription.close();
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
    final copy = _CreateListingCopy.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(RouteNames.home),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(copy.createListingTitle),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: isSubmitting ? null : _onContinue,
        onStepCancel: isSubmitting ? null : _onCancel,
        controlsBuilder: (context, details) {
          final isLast = _currentStep == 2;
          return Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: details.onStepContinue,
                  child: Text(isLast ? copy.publish : copy.continueLabel),
                ),
              ),
              if (_currentStep > 0) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: details.onStepCancel,
                    child: Text(copy.back),
                  ),
                ),
              ],
            ],
          );
        },
        steps: [
          Step(
            title: Text(copy.type),
            isActive: _currentStep >= 0,
            content: _TypeStep(
              copy: copy,
              selected: _listingType,
              onChanged: (value) {
                setState(() {
                  _listingType = value;
                  if (_isFreeStay) {
                    _priceController.clear();
                    _selectedAmenities.add(ListingAmenity.hostLivesTogether);
                  }
                });
              },
            ),
          ),
          Step(
            title: Text(copy.details),
            isActive: _currentStep >= 1,
            content: _DetailsStep(
              copy: copy,
              titleController: _titleController,
              descriptionController: _descriptionController,
              cityController: _cityController,
              districtController: _districtController,
              landmarkController: _landmarkController,
              metroController: _metroController,
              maxGuests: _maxGuests,
              minDays: _minDays,
              maxDays: _maxDays,
              showPhone: _showPhone,
              selectedAmenities: _selectedAmenities,
              selectedImageFiles: _selectedImageFiles,
              mapCoordinates: _mapCoordinates,
              onGuestsChanged: (value) => setState(() => _maxGuests = value),
              onMinDaysChanged: (value) => setState(() => _minDays = value),
              onMaxDaysChanged: (value) => setState(() => _maxDays = value),
              onShowPhoneChanged: (value) => setState(() => _showPhone = value),
              onAmenityToggled: _toggleAmenity,
              onPickMapCoordinates: _pickMapCoordinates,
              onPickImages: _pickImages,
              onRemoveImageAt: _removeImageAt,
            ),
          ),
          Step(
            title: Text(copy.pricingAndPublish),
            isActive: _currentStep >= 2,
            content: _PricingStep(
              copy: copy,
              isFreeStay: _isFreeStay,
              priceController: _priceController,
              hostLivesTogether: _hostLivesTogether,
              languagesCommunicationController:
                  _languagesCommunicationController,
              languagesPracticeController: _languagesPracticeController,
              freeStayTermsController: _freeStayTermsController,
              onHostLivesTogetherChanged: (value) {
                setState(() {
                  _hostLivesTogether = value;
                  if (value) {
                    _selectedAmenities.add(ListingAmenity.hostLivesTogether);
                  } else {
                    _selectedAmenities.remove(ListingAmenity.hostLivesTogether);
                  }
                });
              },
              isSubmitting: isSubmitting,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onContinue() async {
    if (_currentStep < 2) {
      final isStepValid = _validateStep(_currentStep);
      if (!isStepValid) {
        return;
      }
      setState(() => _currentStep += 1);
      return;
    }
    if (!_validateStep(2)) {
      return;
    }
    await _submit();
  }

  void _onCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

  bool _validateStep(int step) {
    final copy = _CreateListingCopy.of(context);
    if (step == 0) {
      return true;
    }
    if (step == 1) {
      if (_titleController.text.trim().isEmpty ||
          _descriptionController.text.trim().isEmpty ||
          _cityController.text.trim().isEmpty ||
          _districtController.text.trim().isEmpty) {
        _show(copy.fillRequiredDetails);
        return false;
      }
      if (_minDays < 1 || _maxDays < _minDays || _maxDays > 30) {
        _show(copy.stayLimitsError);
        return false;
      }
      return true;
    }
    if (_isFreeStay) {
      if (_languagesCommunicationController.text.trim().isEmpty ||
          _languagesPracticeController.text.trim().isEmpty ||
          _freeStayTermsController.text.trim().isEmpty) {
        _show(copy.fillFreeStayFields);
        return false;
      }
      return true;
    }
    final price = int.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      _show(copy.validNightlyPrice);
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
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

    await ref.read(createListingControllerProvider.notifier).create(input);
    final syncInfo = ref.read(hostListingsSyncInfoProvider);
    ref.read(appSessionControllerProvider.notifier).requestHomeTab('listings');
    if (!mounted) {
      return;
    }
    final successMessage =
        syncInfo.state == HostListingsSyncState.warning &&
            (syncInfo.message?.isNotEmpty ?? false)
        ? '${_CreateListingCopy.of(context).listingCreated} ${syncInfo.message}'
        : _CreateListingCopy.of(context).listingCreated;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(successMessage)));
    context.go(RouteNames.homeListings);
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

  void _toggleAmenity(ListingAmenity amenity, bool selected) {
    setState(() {
      if (selected) {
        _selectedAmenities.add(amenity);
      } else {
        _selectedAmenities.remove(amenity);
      }
      if (amenity == ListingAmenity.hostLivesTogether) {
        _hostLivesTogether = selected;
      }
    });
  }

  Future<void> _pickImages() async {
    final remaining = _maxImages - _selectedImageFiles.length;
    if (remaining <= 0) {
      _show(_CreateListingCopy.of(context).photosLimitReached);
      return;
    }

    final picked = await _imagePicker.pickMultiImage();
    if (picked.isEmpty) {
      return;
    }

    final next = <XFile>[..._selectedImageFiles, ...picked.take(remaining)];

    if (picked.length > remaining && mounted) {
      _show(_CreateListingCopy.of(context).photosLimitMessage(_maxImages));
    }

    setState(() {
      _selectedImageFiles
        ..clear()
        ..addAll(next);
    });
  }

  void _removeImageAt(int index) {
    if (index < 0 || index >= _selectedImageFiles.length) {
      return;
    }
    setState(() => _selectedImageFiles.removeAt(index));
  }

  Future<void> _pickMapCoordinates() async {
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
}

class _TypeStep extends StatelessWidget {
  const _TypeStep({
    required this.copy,
    required this.selected,
    required this.onChanged,
  });

  final _CreateListingCopy copy;
  final ListingType selected;
  final ValueChanged<ListingType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _typeChip(ListingType.apartment, copy.apartment),
        _typeChip(ListingType.room, copy.room),
        _typeChip(ListingType.homePart, copy.partOfHome),
        _typeChip(ListingType.freeStay, copy.freeStay),
      ],
    );
  }

  Widget _typeChip(ListingType type, String label) {
    final isSelected = selected == type;
    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      selectedColor: AppColors.primarySoft,
      backgroundColor: AppColors.surfaceTint,
      checkmarkColor: AppColors.primaryDeep,
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border,
        width: isSelected ? 1.4 : 1,
      ),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryDeep : AppColors.textSoft,
        fontWeight: FontWeight.w700,
      ),
      onSelected: (_) => onChanged(type),
    );
  }
}

class _DetailsStep extends StatelessWidget {
  const _DetailsStep({
    required this.copy,
    required this.titleController,
    required this.descriptionController,
    required this.cityController,
    required this.districtController,
    required this.landmarkController,
    required this.metroController,
    required this.maxGuests,
    required this.minDays,
    required this.maxDays,
    required this.showPhone,
    required this.selectedAmenities,
    required this.selectedImageFiles,
    required this.mapCoordinates,
    required this.onGuestsChanged,
    required this.onMinDaysChanged,
    required this.onMaxDaysChanged,
    required this.onShowPhoneChanged,
    required this.onAmenityToggled,
    required this.onPickMapCoordinates,
    required this.onPickImages,
    required this.onRemoveImageAt,
  });

  final _CreateListingCopy copy;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController cityController;
  final TextEditingController districtController;
  final TextEditingController landmarkController;
  final TextEditingController metroController;
  final int maxGuests;
  final int minDays;
  final int maxDays;
  final bool showPhone;
  final Set<ListingAmenity> selectedAmenities;
  final List<XFile> selectedImageFiles;
  final String? mapCoordinates;
  final ValueChanged<int> onGuestsChanged;
  final ValueChanged<int> onMinDaysChanged;
  final ValueChanged<int> onMaxDaysChanged;
  final ValueChanged<bool> onShowPhoneChanged;
  final void Function(ListingAmenity amenity, bool selected) onAmenityToggled;
  final Future<void> Function() onPickMapCoordinates;
  final VoidCallback onPickImages;
  final ValueChanged<int> onRemoveImageAt;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: titleController,
          decoration: InputDecoration(labelText: '${copy.title} *'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: descriptionController,
          maxLines: 3,
          decoration: InputDecoration(labelText: '${copy.description} *'),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            copy.photos,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            copy.photosHint,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280)),
          ),
        ),
        const SizedBox(height: 12),
        if (selectedImageFiles.isNotEmpty)
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: selectedImageFiles.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) => _PickedImagePreview(
                key: ValueKey<String>(selectedImageFiles[index].path),
                file: selectedImageFiles[index],
                onRemove: () => onRemoveImageAt(index),
              ),
            ),
          ),
        if (selectedImageFiles.isNotEmpty) const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onPickImages,
          icon: const Icon(Icons.add_a_photo_outlined),
          label: Text(
            selectedImageFiles.isEmpty ? copy.addPhotos : copy.changePhotos,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: cityController,
          decoration: InputDecoration(labelText: '${copy.city} *'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: districtController,
          decoration: InputDecoration(labelText: '${copy.district} *'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: landmarkController,
          decoration: InputDecoration(labelText: copy.landmark),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: metroController,
          decoration: InputDecoration(labelText: copy.metro),
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
                  copy.exactMapLocation,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  (mapCoordinates ?? '').trim().isEmpty
                      ? copy.exactMapLocationHint
                      : mapCoordinates!,
                  style: TextStyle(
                    color: (mapCoordinates ?? '').trim().isEmpty
                        ? AppColors.textMuted
                        : AppColors.textSoft,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: onPickMapCoordinates,
                  icon: const Icon(Icons.location_searching_rounded),
                  label: Text(copy.pickOnMap),
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
                initialValue: maxGuests,
                decoration: InputDecoration(labelText: copy.maxGuests),
                items: List.generate(
                  10,
                  (i) =>
                      DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
                ),
                onChanged: (value) {
                  if (value != null) {
                    onGuestsChanged(value);
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: minDays,
                decoration: InputDecoration(labelText: copy.minDays),
                items: List.generate(
                  30,
                  (i) =>
                      DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
                ),
                onChanged: (value) {
                  if (value != null) {
                    onMinDaysChanged(value);
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: maxDays,
                decoration: InputDecoration(labelText: copy.maxDays),
                items: List.generate(
                  30,
                  (i) =>
                      DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
                ),
                onChanged: (value) {
                  if (value != null) {
                    onMaxDaysChanged(value);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SwitchListTile(
          value: showPhone,
          onChanged: onShowPhoneChanged,
          activeThumbColor: AppColors.primary,
          activeTrackColor: AppColors.primarySoftStrong,
          title: Text(copy.showHostPhone),
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            copy.amenities,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            copy.amenitiesHint,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280)),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _listingAmenityOptions
              .map(
                (amenity) => FilterChip(
                  key: ValueKey<String>('create_amenity_${amenity.name}'),
                  showCheckmark: true,
                  avatar: Icon(
                    _amenityIcon(amenity),
                    size: 16,
                    color: selectedAmenities.contains(amenity)
                        ? AppColors.primaryDeep
                        : const Color(0xFF6B7280),
                  ),
                  selectedColor: AppColors.primarySoft,
                  checkmarkColor: AppColors.primaryDeep,
                  backgroundColor: AppColors.surfaceTint,
                  side: BorderSide(
                    color: selectedAmenities.contains(amenity)
                        ? AppColors.primary
                        : AppColors.border,
                    width: selectedAmenities.contains(amenity) ? 1.4 : 1,
                  ),
                  selected: selectedAmenities.contains(amenity),
                  label: Text(
                    _amenityLabel(context, amenity),
                    style: TextStyle(
                      color: selectedAmenities.contains(amenity)
                          ? AppColors.primaryDeep
                          : AppColors.textSoft,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onSelected: (value) => onAmenityToggled(amenity, value),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _PricingStep extends StatelessWidget {
  const _PricingStep({
    required this.copy,
    required this.isFreeStay,
    required this.priceController,
    required this.hostLivesTogether,
    required this.languagesCommunicationController,
    required this.languagesPracticeController,
    required this.freeStayTermsController,
    required this.onHostLivesTogetherChanged,
    required this.isSubmitting,
  });

  final _CreateListingCopy copy;
  final bool isFreeStay;
  final TextEditingController priceController;
  final bool hostLivesTogether;
  final TextEditingController languagesCommunicationController;
  final TextEditingController languagesPracticeController;
  final TextEditingController freeStayTermsController;
  final ValueChanged<bool> onHostLivesTogetherChanged;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    if (!isFreeStay) {
      return Column(
        children: [
          TextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '${copy.nightlyPrice} *',
              hintText: '350000',
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(copy.paidListingHint),
          ),
        ],
      );
    }

    return Column(
      children: [
        TextField(
          controller: languagesCommunicationController,
          decoration: InputDecoration(
            labelText: '${copy.languagesCommunication} *',
            hintText: 'uz, en, ru',
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: languagesPracticeController,
          decoration: InputDecoration(
            labelText: '${copy.languagesPractice} *',
            hintText: 'en',
          ),
        ),
        const SizedBox(height: 10),
        SwitchListTile(
          value: hostLivesTogether,
          onChanged: isSubmitting ? null : onHostLivesTogetherChanged,
          activeThumbColor: AppColors.primary,
          activeTrackColor: AppColors.primarySoftStrong,
          contentPadding: EdgeInsets.zero,
          title: Text(copy.hostLivesTogether),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: freeStayTermsController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: '${copy.freeStayTerms} *',
            hintText: copy.freeStayTermsHint,
          ),
        ),
      ],
    );
  }
}

class _PickedImagePreview extends StatelessWidget {
  const _PickedImagePreview({
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
                return Image.memory(
                  snapshot.data!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: const Color(0xFFF3E5D7),
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_not_supported_outlined),
                  ),
                );
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

class _CreateListingCopy {
  const _CreateListingCopy._({
    required this.createListingTitle,
    required this.publish,
    required this.continueLabel,
    required this.back,
    required this.type,
    required this.details,
    required this.pricingAndPublish,
    required this.fillRequiredDetails,
    required this.stayLimitsError,
    required this.fillFreeStayFields,
    required this.validNightlyPrice,
    required this.listingCreated,
    required this.createFailed,
    required this.apartment,
    required this.room,
    required this.partOfHome,
    required this.freeStay,
    required this.title,
    required this.description,
    required this.city,
    required this.district,
    required this.landmark,
    required this.metro,
    this.photos = 'Photos',
    this.photosHint = 'Upload your own property photos.',
    this.addPhotos = 'Upload photos',
    this.changePhotos = 'Add more photos',
    this.photosLimitReached = 'You already reached the photo limit.',
    this.photosLimitTemplate = 'You can upload up to {max} photos.',
    required this.maxGuests,
    required this.minDays,
    required this.maxDays,
    required this.showHostPhone,
    required this.nightlyPrice,
    required this.paidListingHint,
    required this.languagesCommunication,
    required this.languagesPractice,
    required this.hostLivesTogether,
    required this.freeStayTerms,
    required this.freeStayTermsHint,
    required this.amenities,
    required this.amenitiesHint,
    required this.exactMapLocation,
    required this.exactMapLocationHint,
    required this.pickOnMap,
  });

  final String createListingTitle;
  final String publish;
  final String continueLabel;
  final String back;
  final String type;
  final String details;
  final String pricingAndPublish;
  final String fillRequiredDetails;
  final String stayLimitsError;
  final String fillFreeStayFields;
  final String validNightlyPrice;
  final String listingCreated;
  final String createFailed;
  final String apartment;
  final String room;
  final String partOfHome;
  final String freeStay;
  final String title;
  final String description;
  final String city;
  final String district;
  final String landmark;
  final String metro;
  final String photos;
  final String photosHint;
  final String addPhotos;
  final String changePhotos;
  final String photosLimitReached;
  final String photosLimitTemplate;
  final String maxGuests;
  final String minDays;
  final String maxDays;
  final String showHostPhone;
  final String nightlyPrice;
  final String paidListingHint;
  final String languagesCommunication;
  final String languagesPractice;
  final String hostLivesTogether;
  final String freeStayTerms;
  final String freeStayTermsHint;
  final String amenities;
  final String amenitiesHint;
  final String exactMapLocation;
  final String exactMapLocationHint;
  final String pickOnMap;

  String photosLimitMessage(int max) =>
      photosLimitTemplate.replaceFirst('{max}', '$max');

  static _CreateListingCopy of(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'ru':
        return const _CreateListingCopy._(
          createListingTitle: 'Создать объявление',
          publish: 'Опубликовать',
          continueLabel: 'Продолжить',
          back: 'Назад',
          type: 'Тип жилья',
          details: 'Детали',
          pricingAndPublish: 'Цена и публикация',
          fillRequiredDetails: 'Заполните все обязательные поля объявления.',
          stayLimitsError:
              'Проверьте минимальный и максимальный срок: не более 30 дней.',
          fillFreeStayFields:
              'Для Free Stay заполните языки общения и условия проживания.',
          validNightlyPrice:
              'Введите корректную цену за ночь для платного объявления.',
          listingCreated: 'Объявление успешно создано.',
          createFailed: 'Не удалось создать объявление.',
          apartment: 'Квартира',
          room: 'Комната',
          partOfHome: 'Часть дома',
          freeStay: 'Free Stay / Языковой обмен',
          title: 'Название',
          description: 'Описание',
          city: 'Город',
          district: 'Район',
          landmark: 'Ориентир',
          metro: 'Метро',
          photos: 'Фотографии',
          photosHint:
              'Загрузите свои фотографии жилья. Именно их увидят гости в объявлении.',
          addPhotos: 'Загрузить фото',
          changePhotos: 'Добавить еще фото',
          photosLimitReached: 'Лимит фотографий уже достигнут.',
          photosLimitTemplate: 'Можно загрузить до {max} фотографий.',
          maxGuests: 'Макс. гостей',
          minDays: 'Мин. дней',
          maxDays: 'Макс. дней',
          showHostPhone: 'Показывать телефон хозяина в объявлении',
          nightlyPrice: 'Цена за ночь (UZS)',
          paidListingHint:
              'Для платного объявления укажите корректную цену за ночь.',
          languagesCommunication: 'Языки общения',
          languagesPractice: 'Языки для практики',
          hostLivesTogether: 'Хозяин живёт вместе',
          freeStayTerms: 'Условия бесплатного проживания',
          freeStayTermsHint:
              'Опишите ожидания, культурный обмен и правила дома',
          amenities: 'Удобства',
          amenitiesHint: 'Выберите то, что есть в жилье.',
          exactMapLocation: 'Точная локация',
          exactMapLocationHint: 'Выберите точку на карте для Google Maps.',
          pickOnMap: 'Выбрать на карте',
        );
      case 'uz':
        return const _CreateListingCopy._(
          createListingTitle: 'E\'lon yaratish',
          publish: 'Chop etish',
          continueLabel: 'Davom etish',
          back: 'Orqaga',
          type: 'Turar joy turi',
          details: 'Tafsilotlar',
          pricingAndPublish: 'Narx va chop etish',
          fillRequiredDetails:
              'E\'lonning barcha majburiy maydonlarini to\'ldiring.',
          stayLimitsError:
              'Minimal va maksimal muddatni tekshiring: 30 kundan oshmasin.',
          fillFreeStayFields:
              'Free Stay uchun tillar va yashash shartlarini to\'ldiring.',
          validNightlyPrice:
              'Pullik e\'lon uchun to\'g\'ri tunlik narxni kiriting.',
          listingCreated: 'E\'lon muvaffaqiyatli yaratildi.',
          createFailed: 'E\'lon yaratilmadi.',
          apartment: 'Kvartira',
          room: 'Xona',
          partOfHome: 'Uyning bir qismi',
          freeStay: 'Free Stay / Til almashinuvi',
          title: 'Sarlavha',
          description: 'Tavsif',
          city: 'Shahar',
          district: 'Tuman',
          landmark: 'Mo\'ljal',
          metro: 'Metro',
          photos: 'Rasmlar',
          photosHint:
              'Turar joyingizning haqiqiy rasmlarini yuklang. Mehmonlar aynan shu rasmlarni ko\'radi.',
          addPhotos: 'Rasm yuklash',
          changePhotos: 'Yana rasm qo\'shish',
          photosLimitReached: 'Rasmlar limiti tugadi.',
          photosLimitTemplate: '{max} tagacha rasm yuklash mumkin.',
          maxGuests: 'Maks. mehmon',
          minDays: 'Min. kun',
          maxDays: 'Maks. kun',
          showHostPhone: 'Host telefonini e\'londa ko\'rsatish',
          nightlyPrice: 'Bir kecha narxi (UZS)',
          paidListingHint:
              'Pullik e\'lon uchun to\'g\'ri tunlik narx ko\'rsatilishi kerak.',
          languagesCommunication: 'Muloqot tillari',
          languagesPractice: 'Mashq qilinadigan tillar',
          hostLivesTogether: 'Host birga yashaydi',
          freeStayTerms: 'Bepul yashash shartlari',
          freeStayTermsHint:
              'Kutuvlar, madaniy almashinuv va uy qoidalarini yozing',
          amenities: 'Qulayliklar',
          amenitiesHint: 'Turar joyda mavjud bo\'lgan qulayliklarni tanlang.',
          exactMapLocation: 'Aniq joylashuv',
          exactMapLocationHint:
              'Google Maps uchun aniq nuqtani xaritada tanlang.',
          pickOnMap: 'Xaritada tanlash',
        );
      default:
        return const _CreateListingCopy._(
          createListingTitle: 'Create listing',
          publish: 'Publish',
          continueLabel: 'Continue',
          back: 'Back',
          type: 'Type',
          details: 'Details',
          pricingAndPublish: 'Pricing & publish',
          fillRequiredDetails: 'Please fill all required listing details.',
          stayLimitsError: 'Stay limits must be valid and not exceed 30 days.',
          fillFreeStayFields:
              'Fill free stay profile fields before publishing.',
          validNightlyPrice: 'Enter valid nightly price for paid listing.',
          listingCreated: 'Listing created successfully.',
          createFailed: 'Unable to create listing.',
          apartment: 'Apartment',
          room: 'Room',
          partOfHome: 'Part of home',
          freeStay: 'Free Stay / Language Exchange',
          title: 'Title',
          description: 'Description',
          city: 'City',
          district: 'District',
          landmark: 'Landmark',
          metro: 'Metro',
          photos: 'Photos',
          photosHint:
              'Upload real photos of your place. Guests will see these photos in the listing.',
          addPhotos: 'Upload photos',
          changePhotos: 'Add more photos',
          photosLimitReached: 'You have reached the photo limit.',
          photosLimitTemplate: 'You can upload up to {max} photos.',
          maxGuests: 'Max guests',
          minDays: 'Min days',
          maxDays: 'Max days',
          showHostPhone: 'Show host phone in listing',
          nightlyPrice: 'Nightly price (UZS)',
          paidListingHint:
              'Paid rental listing will require valid nightly price.',
          languagesCommunication: 'Languages for communication',
          languagesPractice: 'Languages for practice',
          hostLivesTogether: 'Host lives together',
          freeStayTerms: 'Free stay terms',
          freeStayTermsHint: 'Cultural exchange expectations and house notes',
          amenities: 'Amenities',
          amenitiesHint: 'Choose the amenities available in this stay.',
          exactMapLocation: 'Exact map location',
          exactMapLocationHint:
              'Pick an exact point that guests can open in Google Maps.',
          pickOnMap: 'Pick on map',
        );
    }
  }
}

const List<ListingAmenity> _listingAmenityOptions = <ListingAmenity>[
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

String _amenityLabel(BuildContext context, ListingAmenity amenity) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'ru':
      switch (amenity) {
        case ListingAmenity.wifi:
          return 'Wi‑Fi';
        case ListingAmenity.airConditioner:
          return 'Кондиционер';
        case ListingAmenity.kitchen:
          return 'Кухня';
        case ListingAmenity.washingMachine:
          return 'Стиральная машина';
        case ListingAmenity.parking:
          return 'Парковка';
        case ListingAmenity.privateBathroom:
          return 'Отдельная ванная';
        case ListingAmenity.kidsAllowed:
          return 'Можно с детьми';
        case ListingAmenity.petsAllowed:
          return 'Можно с животными';
        case ListingAmenity.womenOnly:
          return 'Только для женщин';
        case ListingAmenity.menOnly:
          return 'Только для мужчин';
        case ListingAmenity.hostLivesTogether:
          return 'Хозяин живёт вместе';
        case ListingAmenity.instantConfirm:
          return 'Мгновенное подтверждение';
      }
    case 'uz':
      switch (amenity) {
        case ListingAmenity.wifi:
          return 'Wi‑Fi';
        case ListingAmenity.airConditioner:
          return 'Konditsioner';
        case ListingAmenity.kitchen:
          return 'Oshxona';
        case ListingAmenity.washingMachine:
          return 'Kir yuvish mashinasi';
        case ListingAmenity.parking:
          return 'Avtoturargoh';
        case ListingAmenity.privateBathroom:
          return 'Shaxsiy hammom';
        case ListingAmenity.kidsAllowed:
          return 'Bolalar mumkin';
        case ListingAmenity.petsAllowed:
          return 'Uy hayvonlari mumkin';
        case ListingAmenity.womenOnly:
          return 'Faqat ayollar uchun';
        case ListingAmenity.menOnly:
          return 'Faqat erkaklar uchun';
        case ListingAmenity.hostLivesTogether:
          return 'Host birga yashaydi';
        case ListingAmenity.instantConfirm:
          return 'Darhol tasdiq';
      }
    default:
      switch (amenity) {
        case ListingAmenity.wifi:
          return 'Wi‑Fi';
        case ListingAmenity.airConditioner:
          return 'Air conditioner';
        case ListingAmenity.kitchen:
          return 'Kitchen';
        case ListingAmenity.washingMachine:
          return 'Washing machine';
        case ListingAmenity.parking:
          return 'Parking';
        case ListingAmenity.privateBathroom:
          return 'Private bathroom';
        case ListingAmenity.kidsAllowed:
          return 'Children allowed';
        case ListingAmenity.petsAllowed:
          return 'Pets allowed';
        case ListingAmenity.womenOnly:
          return 'Women only';
        case ListingAmenity.menOnly:
          return 'Men only';
        case ListingAmenity.hostLivesTogether:
          return 'Host lives together';
        case ListingAmenity.instantConfirm:
          return 'Instant confirm';
      }
  }
}

IconData _amenityIcon(ListingAmenity amenity) {
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
