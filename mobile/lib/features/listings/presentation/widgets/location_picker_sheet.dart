import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

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
  static const Point _defaultPoint = Point(latitude: 41.3111, longitude: 69.2797);
  late Point _selectedPoint;

  @override
  void initState() {
    super.initState();
    _selectedPoint = _resolveInitialPoint();
  }

  @override
  Widget build(BuildContext context) {
    final coordinateLabel = _formatPoint(_selectedPoint);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick location on map'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: YandexMap(
                    mapObjects: <MapObject>[
                      PlacemarkMapObject(
                        mapId: const MapObjectId('picked-location'),
                        point: _selectedPoint,
                        opacity: 0.95,
                        isDraggable: true,
                        onDrag: (placemark, point) {
                          setState(() => _selectedPoint = point);
                        },
                        onDragEnd: (placemark, point) {
                          setState(() => _selectedPoint = point);
                        },
                      ),
                    ],
                    onMapTap: (point) {
                      setState(() => _selectedPoint = point);
                    },
                    onMapCreated: (controller) async {
                      await controller.moveCamera(
                        CameraUpdate.newCameraPosition(
                          CameraPosition(target: _selectedPoint, zoom: 12),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, color: Color(0xFF6B7280)),
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
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
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
                      onPressed: () => Navigator.of(context).pop(coordinateLabel),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE8572A),
                      ),
                      child: const Text('Confirm location'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPoint(Point point) {
    final lat = point.latitude.toStringAsFixed(6);
    final lng = point.longitude.toStringAsFixed(6);
    return '$lat, $lng';
  }

  Point _resolveInitialPoint() {
    final fromCoordinates = _tryParsePoint(widget.initialCoordinates);
    if (fromCoordinates != null) {
      return fromCoordinates;
    }
    return _cityCenter(widget.cityHint) ?? _defaultPoint;
  }

  Point? _tryParsePoint(String? value) {
    final normalized = (value ?? '').trim();
    final match = RegExp(r'^\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*$')
        .firstMatch(normalized);
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
    return Point(latitude: lat, longitude: lng);
  }

  Point? _cityCenter(String? city) {
    final normalized = (city ?? '').trim().toLowerCase();
    switch (normalized) {
      case 'tashkent':
      case 'ташкент':
        return const Point(latitude: 41.3111, longitude: 69.2797);
      case 'samarkand':
      case 'самарканд':
        return const Point(latitude: 39.6542, longitude: 66.9597);
      case 'bukhara':
      case 'бухара':
        return const Point(latitude: 39.7681, longitude: 64.4556);
      case 'andijan':
      case 'андижан':
        return const Point(latitude: 40.7821, longitude: 72.3442);
      default:
        return null;
    }
  }
}
