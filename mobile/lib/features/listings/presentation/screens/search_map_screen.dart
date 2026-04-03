import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import '../../../../app/router/route_names.dart';
import '../../application/search_controller.dart';
import '../../domain/models/listing.dart';

class SearchMapScreen extends ConsumerWidget {
  const SearchMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(searchControllerProvider).items;
    final mapObjects = items.indexed
        .map((entry) => _toPlacemark(context, entry.$1, entry.$2))
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(RouteNames.search),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Map View'),
      ),
      body: Column(
        children: [
          Container(
            height: 260,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFDDE6F5)),
              borderRadius: BorderRadius.circular(14),
            ),
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: YandexMap(
              mapObjects: mapObjects,
              mode2DEnabled: true,
              zoomGesturesEnabled: true,
              rotateGesturesEnabled: true,
              tiltGesturesEnabled: false,
              onMapCreated: (controller) => _onMapCreated(controller, items),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 2),
            child: Text(
              'Map uses Yandex MapKit. For full tiles/production use, set API key in native Android/iOS configs.',
              style: TextStyle(fontSize: 12, color: Color(0xFF6C7892)),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text(
                      'No listings to show on map for current filters.',
                    ),
                  )
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        leading: const Icon(Icons.place_outlined),
                        title: Text(item.title),
                        subtitle: Text('${item.city}, ${item.district}'),
                        onTap: () =>
                            context.push(RouteNames.listingDetailsById(item.id)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

PlacemarkMapObject _toPlacemark(BuildContext context, int index, Listing item) {
  final point = _listingPoint(item, index);
  return PlacemarkMapObject(
    mapId: MapObjectId('listing_${item.id}'),
    point: point,
    opacity: 0.95,
    consumeTapEvents: true,
    onTap: (_, _) {
      context.push(RouteNames.listingDetailsById(item.id));
    },
  );
}

Future<void> _onMapCreated(
  YandexMapController controller,
  List<Listing> items,
) async {
  final point = items.isEmpty
      ? const Point(latitude: 41.3111, longitude: 69.2797)
      : _listingPoint(items.first, 0);

  await controller.moveCamera(
    CameraUpdate.newCameraPosition(CameraPosition(target: point, zoom: 11.0)),
  );
}

Point _listingPoint(Listing item, int index) {
  final city = item.city.trim().toLowerCase();
  final district = item.district.trim().toLowerCase();
  final landmark = (item.landmark ?? '').trim().toLowerCase();
  final metro = (item.metro ?? '').trim().toLowerCase();

  if (city == 'tashkent') {
    if (district.contains('yunusabad') || landmark.contains('minor')) {
      return const Point(latitude: 41.3667, longitude: 69.2898);
    }
    if (district.contains('mirzo ulugbek')) {
      return const Point(latitude: 41.3402, longitude: 69.3345);
    }
    if (district.contains('mirobod') || landmark.contains('tashkent city')) {
      return const Point(latitude: 41.2995, longitude: 69.2705);
    }
    if (district.contains('chilonzor')) {
      return const Point(latitude: 41.2752, longitude: 69.2014);
    }
    if (district.contains('shaykhontohur') || metro.contains('paxtakor')) {
      return const Point(latitude: 41.3147, longitude: 69.2417);
    }
    if (district.contains('yakkasaray')) {
      return const Point(latitude: 41.2858, longitude: 69.2546);
    }
    if (district.contains('olmazor')) {
      return const Point(latitude: 41.3525, longitude: 69.2280);
    }
    if (district.contains('bektemir')) {
      return const Point(latitude: 41.2164, longitude: 69.3344);
    }
  }

  final base = _cityCenter(item.city);
  final offset = (index % 5) * 0.0035;
  return Point(
    latitude: base.latitude + offset,
    longitude: base.longitude - offset,
  );
}

Point _cityCenter(String city) {
  switch (city.trim().toLowerCase()) {
    case 'samarkand':
      return const Point(latitude: 39.6542, longitude: 66.9597);
    case 'bukhara':
      return const Point(latitude: 39.7670, longitude: 64.4550);
    case 'namangan':
      return const Point(latitude: 41.0011, longitude: 71.6726);
    case 'andijan':
      return const Point(latitude: 40.7821, longitude: 72.3442);
    case 'fergana':
      return const Point(latitude: 40.3894, longitude: 71.7874);
    case 'nukus':
      return const Point(latitude: 42.4531, longitude: 59.6103);
    case 'karshi':
      return const Point(latitude: 38.8606, longitude: 65.7891);
    case 'urgench':
      return const Point(latitude: 41.5500, longitude: 60.6333);
    case 'tashkent':
    default:
      return const Point(latitude: 41.3111, longitude: 69.2797);
  }
}
