from datetime import date

from django.db.models import Q
from rest_framework import serializers

from apps.listings.models import Listing
from .models import Booking


class BookingSerializer(serializers.ModelSerializer):
    guest_id = serializers.IntegerField(source='guest.id', read_only=True)
    host_id = serializers.IntegerField(source='listing.host.id', read_only=True)
    listing_title = serializers.CharField(source='listing.title', read_only=True)

    class Meta:
        model = Booking
        fields = (
            'id',
            'listing',
            'listing_title',
            'guest_id',
            'host_id',
            'start_date',
            'end_date',
            'total_price',
            'status',
            'created_at',
        )
        read_only_fields = ('id', 'guest_id', 'host_id', 'listing_title', 'status', 'total_price', 'created_at')


class BookingCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Booking
        fields = ('id', 'listing', 'start_date', 'end_date', 'total_price', 'status', 'created_at')
        read_only_fields = ('id', 'total_price', 'status', 'created_at')

    def validate(self, attrs):
        start_date = attrs['start_date']
        end_date = attrs['end_date']
        listing = attrs['listing']

        if start_date >= end_date:
            raise serializers.ValidationError('end_date must be after start_date.')

        if start_date < date.today():
            raise serializers.ValidationError('start_date cannot be in the past.')

        if listing.host_id == self.context['request'].user.id:
            raise serializers.ValidationError('You cannot book your own listing.')

        overlapping = Booking.objects.filter(
            listing=listing,
            status__in=[Booking.Status.PENDING, Booking.Status.CONFIRMED],
        ).filter(
            Q(start_date__lt=end_date) & Q(end_date__gt=start_date)
        )

        if overlapping.exists():
            raise serializers.ValidationError('Selected dates are not available for this listing.')

        return attrs

    def create(self, validated_data):
        listing = validated_data['listing']
        days = (validated_data['end_date'] - validated_data['start_date']).days
        total_price = listing.price_per_night * days

        return Booking.objects.create(
            guest=self.context['request'].user,
            total_price=total_price,
            **validated_data,
        )

    def validate_listing(self, value: Listing):
        if not value.is_active:
            raise serializers.ValidationError('Listing is not active.')
        return value


class BookingStatusActionSerializer(serializers.Serializer):
    booking_id = serializers.IntegerField(read_only=True)
    status = serializers.CharField(read_only=True)
    detail = serializers.CharField(read_only=True)
