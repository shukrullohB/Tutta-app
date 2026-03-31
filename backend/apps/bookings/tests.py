from rest_framework import status
from rest_framework.test import APITestCase

from apps.listings.models import Listing
from apps.users.models import User
from .models import Booking


class BookingApiTests(APITestCase):
    def setUp(self):
        self.host = User.objects.create_user(
            email='host-booking@example.com',
            password='StrongPass123!',
            first_name='Host',
            last_name='Booking',
            role='host',
        )
        self.guest = User.objects.create_user(
            email='guest-booking@example.com',
            password='StrongPass123!',
            first_name='Guest',
            last_name='Booking',
            role='guest',
        )
        self.listing = Listing.objects.create(
            host=self.host,
            title='Modern Studio',
            description='Clean and minimal',
            location='Samarkand',
            listing_type='room',
            price_per_night='50.00',
            max_guests=2,
            is_active=True,
        )

    def test_guest_creates_and_host_confirms_booking(self):
        self.client.force_authenticate(user=self.guest)
        create_payload = {
            'listing': self.listing.id,
            'start_date': '2030-05-10',
            'end_date': '2030-05-12',
        }
        create_response = self.client.post('/api/bookings/', create_payload, format='json')
        self.assertEqual(create_response.status_code, status.HTTP_201_CREATED)
        booking_id = create_response.data['id']

        self.client.force_authenticate(user=self.host)
        confirm_response = self.client.post(f'/api/bookings/{booking_id}/confirm', {}, format='json')
        self.assertEqual(confirm_response.status_code, status.HTTP_200_OK)

        booking = Booking.objects.get(id=booking_id)
        self.assertEqual(booking.status, Booking.Status.CONFIRMED)
