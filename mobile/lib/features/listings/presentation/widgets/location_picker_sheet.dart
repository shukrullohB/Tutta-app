import 'package:flutter/material.dart';

import '../../../../core/utils/google_maps_launcher.dart';

Future<String?> pickListingCoordinates(
  BuildContext context, {
  String? initialCoordinates,
  String? cityHint,
}) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute<String>(
      fullscreenDialog: true,
      builder: (_) => _LocationPickerScreen(
        initialCoordinates: initialCoordinates,
        cityHint: cityHint,
      ),
    ),
  );
}

class _LocationPickerScreen extends StatefulWidget {
  const _LocationPickerScreen({this.initialCoordinates, this.cityHint});

  final String? initialCoordinates;
  final String? cityHint;

  @override
  State<_LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<_LocationPickerScreen> {
  static const _default = (41.311100, 69.279700);

  late double _lat;
  late double _lng;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;

  @override
  void initState() {
    super.initState();
    final resolved = _resolveInitialPoint();
    _lat = resolved.$1;
    _lng = resolved.$2;
    _latController = TextEditingController(text: _format(_lat));
    _lngController = TextEditingController(text: _format(_lng));
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coordinateLabel = '${_format(_lat)}, ${_format(_lng)}';

    return Scaffold(
      appBar: AppBar(title: const Text('Pick location on map')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F4EC),
                  border: Border.all(color: const Color(0xFFE8DCCB)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.location_searching_rounded,
                          color: Color(0xFF4B5563),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Google Maps location picker',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Select a city preset or type exact coordinates, then open Google Maps to verify the pin.',
                      style: TextStyle(color: Color(0xFF6B7280), height: 1.4),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _CityPresetChip(
                          label: 'Tashkent',
                          onTap: () => _setPoint(41.311100, 69.279700),
                        ),
                        _CityPresetChip(
                          label: 'Samarkand',
                          onTap: () => _setPoint(39.654200, 66.959700),
                        ),
                        _CityPresetChip(
                          label: 'Bukhara',
                          onTap: () => _setPoint(39.768100, 64.455600),
                        ),
                        _CityPresetChip(
                          label: 'Andijan',
                          onTap: () => _setPoint(40.782100, 72.344200),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _latController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Latitude'),
                      onChanged: (_) => _syncPointFromInputs(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _lngController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Longitude'),
                      onChanged: (_) => _syncPointFromInputs(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      coordinateLabel,
                      style: const TextStyle(
                        color: Color(0xFF475467),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _openInGoogleMaps,
                icon: const Icon(Icons.map_outlined),
                label: const Text('Open in Google Maps'),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () =>
                          Navigator.of(context).pop(coordinateLabel),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE8572A),
                      ),
                      child: const Text('Confirm location'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openInGoogleMaps() async {
    final opened = await openGoogleMaps(
      latitude: _lat,
      longitude: _lng,
      query: '',
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps.')),
      );
    }
  }

  void _setPoint(double lat, double lng) {
    setState(() {
      _lat = lat;
      _lng = lng;
      _latController.text = _format(lat);
      _lngController.text = _format(lng);
    });
  }

  void _syncPointFromInputs() {
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    if (lat == null || lng == null) {
      return;
    }
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      return;
    }
    setState(() {
      _lat = lat;
      _lng = lng;
    });
  }

  (double, double) _resolveInitialPoint() {
    final fromCoordinates = _tryParsePoint(widget.initialCoordinates);
    if (fromCoordinates != null) {
      return fromCoordinates;
    }
    return _cityCenter(widget.cityHint) ?? _default;
  }

  (double, double)? _tryParsePoint(String? value) {
    final normalized = (value ?? '').trim();
    final match = RegExp(
      r'^\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*$',
    ).firstMatch(normalized);
    if (match == null) {
      return null;
    }
    final lat = double.tryParse(match.group(1) ?? '');
    final lng = double.tryParse(match.group(2) ?? '');
    if (lat == null || lng == null) {
      return null;
    }
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      return null;
    }
    return (lat, lng);
  }

  (double, double)? _cityCenter(String? city) {
    final normalized = (city ?? '').trim().toLowerCase();
    switch (normalized) {
      case 'tashkent':
      case 'ташкент':
        return (41.311100, 69.279700);
      case 'samarkand':
      case 'самарканд':
        return (39.654200, 66.959700);
      case 'bukhara':
      case 'бухара':
        return (39.768100, 64.455600);
      case 'andijan':
      case 'андижан':
        return (40.782100, 72.344200);
      default:
        return null;
    }
  }

  String _format(double value) => value.toStringAsFixed(6);
}

class _CityPresetChip extends StatelessWidget {
  const _CityPresetChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(label: Text(label), onPressed: onTap);
  }
}
