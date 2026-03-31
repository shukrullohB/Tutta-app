from rest_framework import serializers

from apps.bookings.models import Booking
from .models import Payment


class PaymentSerializer(serializers.ModelSerializer):
    booking_id = serializers.IntegerField(source='booking.id', read_only=True)

    class Meta:
        model = Payment
        fields = (
            'id',
            'booking_id',
            'provider',
            'amount',
            'currency',
            'status',
            'provider_payment_id',
            'checkout_url',
            'created_at',
            'updated_at',
        )
        read_only_fields = fields


class PaymentIntentCreateSerializer(serializers.ModelSerializer):
    booking = serializers.PrimaryKeyRelatedField(queryset=Booking.objects.select_related('guest'))

    class Meta:
        model = Payment
        fields = ('id', 'booking', 'provider', 'currency', 'status', 'amount', 'checkout_url', 'provider_payment_id', 'created_at')
        read_only_fields = ('id', 'status', 'amount', 'checkout_url', 'provider_payment_id', 'created_at')

    def validate_booking(self, booking: Booking):
        user = self.context['request'].user

        if booking.guest_id != user.id:
            raise serializers.ValidationError('You can only create payment intent for your own booking.')

        if booking.status != Booking.Status.CONFIRMED:
            raise serializers.ValidationError('Booking must be confirmed before creating payment intent.')

        has_paid = Payment.objects.filter(booking=booking, status=Payment.Status.SUCCEEDED).exists()
        if has_paid:
            raise serializers.ValidationError('This booking has already been paid.')

        return booking

    def create(self, validated_data):
        booking = validated_data['booking']
        provider = validated_data['provider']

        payment = Payment.objects.create(
            booking=booking,
            provider=provider,
            amount=booking.total_price,
            currency=validated_data.get('currency', 'UZS'),
            checkout_url=f'https://pay.tutta.uz/{provider}/{booking.id}',
        )
        return payment

    def to_representation(self, instance):
        return PaymentSerializer(instance, context=self.context).data


class PaymentWebhookSerializer(serializers.Serializer):
    provider_payment_id = serializers.CharField(max_length=64)
    status = serializers.ChoiceField(choices=[Payment.Status.SUCCEEDED, Payment.Status.FAILED, Payment.Status.CANCELLED])
    payload = serializers.JSONField(required=False)

    def save(self, **kwargs):
        provider = kwargs['provider']
        validated = self.validated_data
        payment = Payment.objects.filter(provider=provider, provider_payment_id=validated['provider_payment_id']).first()
        if not payment:
            raise serializers.ValidationError({'provider_payment_id': 'Payment not found.'})

        payment.status = validated['status']
        payment.raw_payload = validated.get('payload', {})
        payment.save(update_fields=['status', 'raw_payload', 'updated_at'])
        return payment
