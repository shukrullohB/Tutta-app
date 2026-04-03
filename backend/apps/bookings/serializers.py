from datetime import date

from django.db import transaction
from django.db.models import Q
from rest_framework import serializers

from apps.listings.models import AvailabilityDay, Listing
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
    guests_count = serializers.IntegerField(
        required=False,
        min_value=1,
        write_only=True,
    )

    class Meta:
        model = Booking
        fields = (
            'id',
            'listing',
            'start_date',
            'end_date',
            'guests_count',
            'total_price',
            'status',
            'created_at',
        )
        read_only_fields = ('id', 'total_price', 'status', 'created_at')

    def validate(self, attrs):
        start_date = attrs['start_date']
        end_date = attrs['end_date']
        listing = attrs['listing']
        requested_guests = attrs.get('guests_count')

        if start_date >= end_date:
            raise serializers.ValidationError('end_date must be after start_date.')

        if start_date < date.today():
            raise serializers.ValidationError('start_date cannot be in the past.')

        stay_days = (end_date - start_date).days
        if stay_days > 30:
            raise serializers.ValidationError('Maximum stay is 30 days.')

        if listing.host_id == self.context['request'].user.id:
            raise serializers.ValidationError('You cannot book your own listing.')

        if requested_guests is not None:
            if requested_guests > listing.max_guests:
                raise serializers.ValidationError('guests_count exceeds listing max_guests.')

        overlapping = Booking.objects.filter(
            listing=listing,
            status__in=[Booking.Status.PENDING, Booking.Status.CONFIRMED],
        ).filter(
            Q(start_date__lt=end_date) & Q(end_date__gt=start_date)
        )

        if overlapping.exists():
            raise serializers.ValidationError('Selected dates are not available for this listing.')

        unavailable_days = AvailabilityDay.objects.filter(
            listing=listing,
            is_available=False,
            date__gte=start_date,
            date__lt=end_date,
        )
        if unavailable_days.exists():
            raise serializers.ValidationError('Selected dates include unavailable days.')

        return attrs

    def create(self, validated_data):
        validated_data.pop('guests_count', None)
        requested_start = validated_data['start_date']
        requested_end = validated_data['end_date']
        listing = validated_data['listing']

        with transaction.atomic():
            locked_listing = Listing.objects.select_for_update().get(pk=listing.pk)

            overlapping = Booking.objects.select_for_update().filter(
                listing=locked_listing,
                status__in=[Booking.Status.PENDING, Booking.Status.CONFIRMED],
            ).filter(
                Q(start_date__lt=requested_end) & Q(end_date__gt=requested_start)
            )
            if overlapping.exists():
                raise serializers.ValidationError('Selected dates are not available for this listing.')

            unavailable_days = AvailabilityDay.objects.select_for_update().filter(
                listing=locked_listing,
                is_available=False,
                date__gte=requested_start,
                date__lt=requested_end,
            )
            if unavailable_days.exists():
                raise serializers.ValidationError('Selected dates include unavailable days.')

            days = (requested_end - requested_start).days
            total_price = locked_listing.price_per_night * days

            return Booking.objects.create(
                guest=self.context['request'].user,
                listing=locked_listing,
                start_date=requested_start,
                end_date=requested_end,
                total_price=total_price,
            )

    def validate_listing(self, value: Listing):
        if not value.is_active:
            raise serializers.ValidationError('Listing is not active.')
        if value.moderation_status != Listing.ModerationStatus.APPROVED:
            raise serializers.ValidationError('Listing is not available for booking yet.')
        return value


class BookingStatusActionSerializer(serializers.Serializer):
    booking_id = serializers.IntegerField(read_only=True)
    status = serializers.CharField(read_only=True)
    detail = serializers.CharField(read_only=True)
