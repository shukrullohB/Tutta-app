import 'package:flutter_test/flutter_test.dart';
import 'package:tutta/core/errors/app_exception.dart';
import 'package:tutta/features/listings/data/repositories/fake_listings_repository.dart';
import 'package:tutta/features/listings/domain/models/listing.dart';
import 'package:tutta/features/listings/domain/models/listing_search_params.dart';

void main() {
  group('FakeListingsRepository search', () {
    final repository = FakeListingsRepository();

    test('returns tashkent listings by city token search', () async {
      final items = await repository.search(
        params: const ListingSearchParams(
          city: 'Tashkent, Uzbekistan',
          district: '',
          guests: 1,
          includeFreeStay: false,
        ),
        hasPremium: false,
      );

      expect(items, isNotEmpty);
      expect(items.every((item) => item.city == 'Tashkent'), isTrue);
    });

    test('applies type and amenity filters together', () async {
      final items = await repository.search(
        params: const ListingSearchParams(
          city: 'Tashkent',
          district: '',
          guests: 1,
          includeFreeStay: false,
          types: <ListingType>[ListingType.apartment],
          amenities: <ListingAmenity>[ListingAmenity.instantConfirm],
        ),
        hasPremium: false,
      );

      expect(items, hasLength(1));
      expect(items.first.type, ListingType.apartment);
      expect(items.first.amenities.contains(ListingAmenity.instantConfirm), isTrue);
    });

    test('blocks free stay search for non-premium users', () async {
      expect(
        () => repository.search(
          params: const ListingSearchParams(
            city: '',
            district: '',
            guests: 1,
            includeFreeStay: true,
          ),
          hasPremium: false,
        ),
        throwsA(isA<AppException>()),
      );
    });
  });
}
