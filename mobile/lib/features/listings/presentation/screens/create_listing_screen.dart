import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/errors/app_exception.dart';
import '../../application/create_listing_controller.dart';
import '../../domain/models/create_listing_input.dart';
import '../../domain/models/listing.dart';

class CreateListingScreen extends ConsumerStatefulWidget {
  const CreateListingScreen({super.key});

  @override
  ConsumerState<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
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

    ref.listen<AsyncValue<void>>(createListingControllerProvider, (prev, next) {
      if (!mounted) {
        return;
      }
      if (next.hasError) {
        final error = next.error;
        final message = error is AppException ? error.message : 'Unable to create listing.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.canPop() ? context.pop() : context.go(RouteNames.home),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Create listing'),
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
                  child: Text(isLast ? 'Publish' : 'Continue'),
                ),
              ),
              if (_currentStep > 0) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back'),
                  ),
                ),
              ],
            ],
          );
        },
        steps: [
          Step(
            title: const Text('Type'),
            isActive: _currentStep >= 0,
            content: _TypeStep(
              selected: _listingType,
              onChanged: (value) {
                setState(() {
                  _listingType = value;
                  if (_isFreeStay) {
                    _priceController.clear();
                  }
                });
              },
            ),
          ),
          Step(
            title: const Text('Details'),
            isActive: _currentStep >= 1,
            content: _DetailsStep(
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
              onGuestsChanged: (value) => setState(() => _maxGuests = value),
              onMinDaysChanged: (value) => setState(() => _minDays = value),
              onMaxDaysChanged: (value) => setState(() => _maxDays = value),
              onShowPhoneChanged: (value) => setState(() => _showPhone = value),
            ),
          ),
          Step(
            title: const Text('Pricing & publish'),
            isActive: _currentStep >= 2,
            content: _PricingStep(
              isFreeStay: _isFreeStay,
              priceController: _priceController,
              hostLivesTogether: _hostLivesTogether,
              languagesCommunicationController: _languagesCommunicationController,
              languagesPracticeController: _languagesPracticeController,
              freeStayTermsController: _freeStayTermsController,
              onHostLivesTogetherChanged: (value) =>
                  setState(() => _hostLivesTogether = value),
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
    if (step == 0) {
      return true;
    }
    if (step == 1) {
      if (_titleController.text.trim().isEmpty ||
          _descriptionController.text.trim().isEmpty ||
          _cityController.text.trim().isEmpty ||
          _districtController.text.trim().isEmpty) {
        _show('Please fill all required listing details.');
        return false;
      }
      if (_minDays < 1 || _maxDays < _minDays || _maxDays > 30) {
        _show('Stay limits must be valid and not exceed 30 days.');
        return false;
      }
      return true;
    }
    if (_isFreeStay) {
      if (_languagesCommunicationController.text.trim().isEmpty ||
          _languagesPracticeController.text.trim().isEmpty ||
          _freeStayTermsController.text.trim().isEmpty) {
        _show('Fill free stay profile fields before publishing.');
        return false;
      }
      return true;
    }
    final price = int.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      _show('Enter valid nightly price for paid listing.');
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

    await ref.read(createListingControllerProvider.notifier).create(input);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Listing created successfully.')),
    );
    context.go(RouteNames.home);
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

class _TypeStep extends StatelessWidget {
  const _TypeStep({
    required this.selected,
    required this.onChanged,
  });

  final ListingType selected;
  final ValueChanged<ListingType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _typeChip(ListingType.apartment, 'Apartment'),
        _typeChip(ListingType.room, 'Room'),
        _typeChip(ListingType.homePart, 'Part of home'),
        _typeChip(ListingType.freeStay, 'Free Stay / Language Exchange'),
      ],
    );
  }

  Widget _typeChip(ListingType type, String label) {
    return ChoiceChip(
      selected: selected == type,
      label: Text(label),
      onSelected: (_) => onChanged(type),
    );
  }
}

class _DetailsStep extends StatelessWidget {
  const _DetailsStep({
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
    required this.onGuestsChanged,
    required this.onMinDaysChanged,
    required this.onMaxDaysChanged,
    required this.onShowPhoneChanged,
  });

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
  final ValueChanged<int> onGuestsChanged;
  final ValueChanged<int> onMinDaysChanged;
  final ValueChanged<int> onMaxDaysChanged;
  final ValueChanged<bool> onShowPhoneChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: titleController,
          decoration: const InputDecoration(labelText: 'Title *'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: descriptionController,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Description *'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: cityController,
          decoration: const InputDecoration(labelText: 'City *'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: districtController,
          decoration: const InputDecoration(labelText: 'District *'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: landmarkController,
          decoration: const InputDecoration(labelText: 'Landmark'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: metroController,
          decoration: const InputDecoration(labelText: 'Metro'),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: maxGuests,
                decoration: const InputDecoration(labelText: 'Max guests'),
                items: List.generate(
                  10,
                  (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
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
                decoration: const InputDecoration(labelText: 'Min days'),
                items: List.generate(
                  30,
                  (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
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
                decoration: const InputDecoration(labelText: 'Max days'),
                items: List.generate(
                  30,
                  (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
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
          title: const Text('Show host phone in listing'),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

class _PricingStep extends StatelessWidget {
  const _PricingStep({
    required this.isFreeStay,
    required this.priceController,
    required this.hostLivesTogether,
    required this.languagesCommunicationController,
    required this.languagesPracticeController,
    required this.freeStayTermsController,
    required this.onHostLivesTogetherChanged,
    required this.isSubmitting,
  });

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
            decoration: const InputDecoration(
              labelText: 'Nightly price (UZS) *',
              hintText: '350000',
            ),
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Paid rental listing will require valid nightly price.'),
          ),
        ],
      );
    }

    return Column(
      children: [
        TextField(
          controller: languagesCommunicationController,
          decoration: const InputDecoration(
            labelText: 'Languages for communication *',
            hintText: 'uz, en, ru',
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: languagesPracticeController,
          decoration: const InputDecoration(
            labelText: 'Languages for practice *',
            hintText: 'en',
          ),
        ),
        const SizedBox(height: 10),
        SwitchListTile(
          value: hostLivesTogether,
          onChanged: isSubmitting ? null : onHostLivesTogetherChanged,
          contentPadding: EdgeInsets.zero,
          title: const Text('Host lives together'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: freeStayTermsController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Free stay terms *',
            hintText: 'Cultural exchange expectations and house notes',
          ),
        ),
      ],
    );
  }
}
