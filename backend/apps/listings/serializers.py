from rest_framework import serializers

from .models import AvailabilityDay, Listing, ListingImage


class ListingImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = ListingImage
        fields = ('id', 'image', 'created_at')
        read_only_fields = ('id', 'created_at')


class AvailabilityDaySerializer(serializers.ModelSerializer):
    class Meta:
        model = AvailabilityDay
        fields = (
            'id',
            'date',
            'is_available',
            'price_override',
            'min_nights_override',
            'note',
            'created_at',
            'updated_at',
        )
        read_only_fields = ('id', 'created_at', 'updated_at')


class ListingSerializer(serializers.ModelSerializer):
    images = ListingImageSerializer(many=True, read_only=True)
    host_id = serializers.IntegerField(source='host.id', read_only=True)
    is_free_stay = serializers.SerializerMethodField()

    class Meta:
        model = Listing
        fields = (
            'id',
            'host_id',
            'title',
            'description',
            'location',
            'city',
            'district',
            'landmark',
            'metro',
            'listing_type',
            'price_per_night',
            'max_guests',
            'min_days',
            'max_days',
            'show_phone',
            'free_stay_profile',
            'is_free_stay',
            'moderation_status',
            'moderation_note',
            'is_active',
            'images',
            'created_at',
            'updated_at',
        )
        read_only_fields = (
            'id',
            'host_id',
            'is_active',
            'moderation_status',
            'moderation_note',
            'created_at',
            'updated_at',
        )

    def create(self, validated_data):
        return Listing.objects.create(host=self.context['request'].user, **validated_data)

    def get_is_free_stay(self, obj):
        return obj.listing_type == Listing.Type.FREE_STAY


class ListingCreateSerializer(serializers.ModelSerializer):
    image_files = serializers.ListField(
        child=serializers.ImageField(),
        required=False,
        allow_empty=True,
        write_only=True,
    )
    remove_image_ids = serializers.ListField(
        child=serializers.IntegerField(min_value=1),
        required=False,
        allow_empty=True,
        write_only=True,
    )
    free_stay_profile = serializers.JSONField(required=False)

    class Meta:
        model = Listing
        fields = (
            'id',
            'title',
            'description',
            'location',
            'city',
            'district',
            'landmark',
            'metro',
            'listing_type',
            'price_per_night',
            'max_guests',
            'min_days',
            'max_days',
            'show_phone',
            'free_stay_profile',
            'image_files',
            'remove_image_ids',
            'created_at',
            'updated_at',
        )
        read_only_fields = ('id', 'created_at', 'updated_at')

    def validate_price_per_night(self, value):
        if value is not None and value <= 0:
            raise serializers.ValidationError('price_per_night must be greater than 0.')
        return value

    def validate_max_guests(self, value):
        if value < 1:
            raise serializers.ValidationError('max_guests must be at least 1.')
        return value

    def validate(self, attrs):
        listing_type = attrs.get('listing_type', getattr(self.instance, 'listing_type', None))
        min_days = attrs.get('min_days', getattr(self.instance, 'min_days', 1))
        max_days = attrs.get('max_days', getattr(self.instance, 'max_days', 30))
        price = attrs.get('price_per_night', getattr(self.instance, 'price_per_night', None))
        city = attrs.get('city', getattr(self.instance, 'city', ''))
        district = attrs.get('district', getattr(self.instance, 'district', ''))
        location = attrs.get('location', getattr(self.instance, 'location', ''))

        if min_days < 1:
            raise serializers.ValidationError('min_days must be at least 1.')
        if max_days < min_days:
            raise serializers.ValidationError('max_days must be greater than or equal to min_days.')
        if max_days > 30:
            raise serializers.ValidationError('max_days must not exceed 30.')

        if listing_type == Listing.Type.FREE_STAY:
            if price not in (None, 0, 0.0, '0', '0.00'):
                raise serializers.ValidationError('Free Stay listing must not have paid nightly price.')
            attrs['price_per_night'] = None
            profile = attrs.get('free_stay_profile') or {}
            if not isinstance(profile, dict):
                raise serializers.ValidationError('free_stay_profile must be a JSON object.')
            attrs['free_stay_profile'] = profile
        else:
            if price is None or price <= 0:
                raise serializers.ValidationError('price_per_night must be greater than 0.')
            if attrs.get('free_stay_profile') is None:
                attrs['free_stay_profile'] = {}

        if not city and location:
            attrs['city'] = location.split(',')[0].strip()
        if not district and location and ',' in location:
            attrs['district'] = location.split(',', 1)[1].strip()
        if not attrs.get('location'):
            normalized_city = attrs.get('city', city).strip()
            normalized_district = attrs.get('district', district).strip()
            attrs['location'] = (
                f'{normalized_city}, {normalized_district}'.strip(', ').strip()
                if normalized_district
                else normalized_city
            )

        return attrs

    def validate_image_files(self, value):
        max_images = 10
        max_size = 5 * 1024 * 1024

        if len(value) > max_images:
            raise serializers.ValidationError(f'You can upload up to {max_images} images at once.')

        for image in value:
            if image.size > max_size:
                raise serializers.ValidationError('Each image must be smaller than 5 MB.')
        return value

    def create(self, validated_data):
        image_files = validated_data.pop('image_files', [])
        validated_data.pop('remove_image_ids', None)
        validated_data['is_active'] = False
        validated_data['moderation_status'] = Listing.ModerationStatus.DRAFT
        validated_data['moderation_note'] = ''
        listing = Listing.objects.create(host=self.context['request'].user, **validated_data)
        for image in image_files:
            ListingImage.objects.create(listing=listing, image=image)
        return listing

    def update(self, instance, validated_data):
        image_files = validated_data.pop('image_files', [])
        remove_image_ids = validated_data.pop('remove_image_ids', [])

        review_fields = {
            'title',
            'description',
            'location',
            'city',
            'district',
            'landmark',
            'metro',
            'listing_type',
            'price_per_night',
            'max_guests',
            'min_days',
            'max_days',
            'free_stay_profile',
            'show_phone',
        }
        should_recheck = any(field in validated_data for field in review_fields)

        for attr, value in validated_data.items():
            setattr(instance, attr, value)

        if should_recheck:
            instance.moderation_status = Listing.ModerationStatus.PENDING
            instance.moderation_note = ''

        instance.save()

        if remove_image_ids:
            ListingImage.objects.filter(listing=instance, id__in=remove_image_ids).delete()

        for image in image_files:
            ListingImage.objects.create(listing=instance, image=image)

        return instance

    def to_representation(self, instance):
        return ListingSerializer(instance, context=self.context).data
