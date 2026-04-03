from datetime import date

from rest_framework import serializers

from apps.bookings.models import Booking
from .models import Review


class ReviewSerializer(serializers.ModelSerializer):
    guest_id = serializers.IntegerField(source='guest.id', read_only=True)
    guest_name = serializers.SerializerMethodField()
    host_id = serializers.IntegerField(source='listing.host.id', read_only=True)

    class Meta:
        model = Review
        fields = (
            'id',
            'listing',
            'booking',
            'guest_id',
            'guest_name',
            'host_id',
            'rating',
            'comment',
            'created_at',
        )
        read_only_fields = ('id', 'guest_id', 'guest_name', 'host_id', 'created_at')

    def get_guest_name(self, obj):
        full_name = f'{obj.guest.first_name} {obj.guest.last_name}'.strip()
        return full_name or obj.guest.email

    def validate_booking(self, booking: Booking):
        user = self.context['request'].user

        if booking.guest_id != user.id:
            raise serializers.ValidationError('You can only review your own bookings.')

        if booking.status not in (Booking.Status.CONFIRMED, Booking.Status.COMPLETED):
            raise serializers.ValidationError('Only confirmed or completed bookings can be reviewed.')

        if booking.end_date > date.today():
            raise serializers.ValidationError('You can review only after checkout date.')

        if Review.objects.filter(booking=booking).exists():
            raise serializers.ValidationError('Review already exists for this booking.')

        return booking

    def validate(self, attrs):
        booking = attrs['booking']
        listing = attrs['listing']

        if booking.listing_id != listing.id:
            raise serializers.ValidationError('Booking does not belong to the selected listing.')

        return attrs

    def create(self, validated_data):
        return Review.objects.create(guest=self.context['request'].user, **validated_data)
