from rest_framework import status
from rest_framework.test import APITestCase

from apps.bookings.models import Booking
from apps.listings.models import Listing
from apps.users.models import User
from .models import Payment


class PaymentApiTests(APITestCase):
    def setUp(self):
        self.host = User.objects.create_user(
            email='host-payment@example.com',
            password='StrongPass123!',
            first_name='Host',
            last_name='Payment',
            role='host',
        )
        self.guest = User.objects.create_user(
            email='guest-payment@example.com',
            password='StrongPass123!',
            first_name='Guest',
            last_name='Payment',
            role='guest',
        )
        self.listing = Listing.objects.create(
            host=self.host,
            title='Payment Listing',
            description='For payment tests',
            location='Khiva',
            listing_type='room',
            price_per_night='80.00',
            max_guests=2,
            is_active=True,
        )
        self.booking = Booking.objects.create(
            listing=self.listing,
            guest=self.guest,
            start_date='2030-06-01',
            end_date='2030-06-03',
            total_price='160.00',
            status=Booking.Status.CONFIRMED,
        )

    def test_create_intent_and_webhook_success(self):
        self.client.force_authenticate(user=self.guest)
        intent_response = self.client.post(
            '/api/payments/intents',
            {'booking': self.booking.id, 'provider': 'click', 'currency': 'UZS'},
            format='json',
        )
        self.assertEqual(intent_response.status_code, status.HTTP_201_CREATED)
        provider_payment_id = intent_response.data['provider_payment_id']

        self.client.force_authenticate(user=None)
        webhook_response = self.client.post(
            '/api/payments/webhooks/click',
            {'provider_payment_id': provider_payment_id, 'status': 'succeeded', 'payload': {}},
            format='json',
        )
        self.assertEqual(webhook_response.status_code, status.HTTP_200_OK)
        payment = Payment.objects.get(provider_payment_id=provider_payment_id)
        self.assertEqual(payment.status, Payment.Status.SUCCEEDED)
