from rest_framework import serializers

from .models import Listing, ListingImage


class ListingImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = ListingImage
        fields = ('id', 'image', 'created_at')
        read_only_fields = ('id', 'created_at')


class ListingSerializer(serializers.ModelSerializer):
    images = ListingImageSerializer(many=True, read_only=True)
    host_id = serializers.IntegerField(source='host.id', read_only=True)

    class Meta:
        model = Listing
        fields = (
            'id',
            'host_id',
            'title',
            'description',
            'location',
            'listing_type',
            'price_per_night',
            'max_guests',
            'is_active',
            'images',
            'created_at',
            'updated_at',
        )
        read_only_fields = ('id', 'host_id', 'is_active', 'created_at', 'updated_at')

    def create(self, validated_data):
        return Listing.objects.create(host=self.context['request'].user, **validated_data)


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

    class Meta:
        model = Listing
        fields = (
            'id',
            'title',
            'description',
            'location',
            'listing_type',
            'price_per_night',
            'max_guests',
            'image_files',
            'remove_image_ids',
            'created_at',
            'updated_at',
        )
        read_only_fields = ('id', 'created_at', 'updated_at')

    def validate_price_per_night(self, value):
        if value <= 0:
            raise serializers.ValidationError('price_per_night must be greater than 0.')
        return value

    def validate_max_guests(self, value):
        if value < 1:
            raise serializers.ValidationError('max_guests must be at least 1.')
        return value

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
        listing = Listing.objects.create(host=self.context['request'].user, **validated_data)
        for image in image_files:
            ListingImage.objects.create(listing=listing, image=image)
        return listing

    def update(self, instance, validated_data):
        image_files = validated_data.pop('image_files', [])
        remove_image_ids = validated_data.pop('remove_image_ids', [])

        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()

        if remove_image_ids:
            ListingImage.objects.filter(listing=instance, id__in=remove_image_ids).delete()

        for image in image_files:
            ListingImage.objects.create(listing=instance, image=image)

        return instance

    def to_representation(self, instance):
        return ListingSerializer(instance, context=self.context).data
