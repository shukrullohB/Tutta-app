from datetime import timedelta

from rest_framework import status
from rest_framework.test import APITestCase
from django.utils import timezone

from apps.listings.models import AvailabilityDay
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
            moderation_status='approved',
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

    def test_rejects_booking_longer_than_30_days(self):
        self.client.force_authenticate(user=self.guest)
        create_payload = {
            'listing': self.listing.id,
            'start_date': '2030-05-01',
            'end_date': '2030-06-05',
        }
        create_response = self.client.post('/api/bookings/', create_payload, format='json')
        self.assertEqual(create_response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('Maximum stay is 30 days.', str(create_response.data))

    def test_rejects_booking_when_guest_count_exceeds_listing_limit(self):
        self.client.force_authenticate(user=self.guest)
        create_payload = {
            'listing': self.listing.id,
            'start_date': '2030-05-10',
            'end_date': '2030-05-12',
            'guests_count': 3,
        }
        create_response = self.client.post('/api/bookings/', create_payload, format='json')
        self.assertEqual(create_response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('guests_count exceeds listing max_guests.', str(create_response.data))

    def test_rejects_overlapping_booking_for_same_listing(self):
        Booking.objects.create(
            listing=self.listing,
            guest=self.guest,
            start_date='2030-05-10',
            end_date='2030-05-12',
            total_price='100.00',
            status=Booking.Status.CONFIRMED,
        )

        second_guest = User.objects.create_user(
            email='guest2-booking@example.com',
            password='StrongPass123!',
            first_name='Guest2',
            last_name='Booking',
            role='guest',
        )
        self.client.force_authenticate(user=second_guest)
        create_payload = {
            'listing': self.listing.id,
            'start_date': '2030-05-11',
            'end_date': '2030-05-13',
        }
        create_response = self.client.post('/api/bookings/', create_payload, format='json')
        self.assertEqual(create_response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('Selected dates are not available for this listing.', str(create_response.data))

    def test_host_can_complete_confirmed_booking_after_end_date(self):
        booking = Booking.objects.create(
            listing=self.listing,
            guest=self.guest,
            start_date=timezone.localdate() - timedelta(days=3),
            end_date=timezone.localdate() - timedelta(days=1),
            total_price='100.00',
            status=Booking.Status.CONFIRMED,
        )

        self.client.force_authenticate(user=self.host)
        complete_response = self.client.post(f'/api/bookings/{booking.id}/complete', {}, format='json')
        self.assertEqual(complete_response.status_code, status.HTTP_200_OK)

        booking.refresh_from_db()
        self.assertEqual(booking.status, Booking.Status.COMPLETED)

    def test_rejects_booking_for_unavailable_calendar_day(self):
        AvailabilityDay.objects.create(
            listing=self.listing,
            date='2030-05-11',
            is_available=False,
        )

        self.client.force_authenticate(user=self.guest)
        create_payload = {
            'listing': self.listing.id,
            'start_date': '2030-05-10',
            'end_date': '2030-05-12',
        }
        create_response = self.client.post('/api/bookings/', create_payload, format='json')
        self.assertEqual(create_response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('Selected dates include unavailable days.', str(create_response.data))
