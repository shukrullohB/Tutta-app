from datetime import date, timedelta

from rest_framework import status
from rest_framework.test import APITestCase

from apps.bookings.models import Booking
from apps.listings.models import Listing
from apps.users.models import User
from .models import Review


class ReviewApiTests(APITestCase):
    def setUp(self):
        self.host = User.objects.create_user(
            email='host-review@example.com',
            password='StrongPass123!',
            first_name='Host',
            last_name='Review',
            role='host',
        )
        self.guest = User.objects.create_user(
            email='guest-review@example.com',
            password='StrongPass123!',
            first_name='Guest',
            last_name='Review',
            role='guest',
        )
        self.listing = Listing.objects.create(
            host=self.host,
            title='Review Listing',
            description='For review tests',
            location='Tashkent',
            listing_type='home',
            price_per_night='120.00',
            max_guests=3,
            is_active=True,
        )

    def _create_booking(self, *, start_delta_days=-3, end_delta_days=-1, status=Booking.Status.CONFIRMED):
        today = date.today()
        return Booking.objects.create(
            listing=self.listing,
            guest=self.guest,
            start_date=today + timedelta(days=start_delta_days),
            end_date=today + timedelta(days=end_delta_days),
            total_price='240.00',
            status=status,
        )

    def test_guest_can_create_review_for_completed_confirmed_booking(self):
        booking = self._create_booking()
        self.client.force_authenticate(user=self.guest)

        response = self.client.post(
            '/api/reviews/',
            {'listing': self.listing.id, 'booking': booking.id, 'rating': 5, 'comment': 'Excellent stay'},
            format='json',
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Review.objects.count(), 1)
        self.assertEqual(Review.objects.first().guest_id, self.guest.id)

    def test_review_fails_for_future_checkout(self):
        booking = self._create_booking(start_delta_days=1, end_delta_days=3)
        self.client.force_authenticate(user=self.guest)

        response = self.client.post(
            '/api/reviews/',
            {'listing': self.listing.id, 'booking': booking.id, 'rating': 4, 'comment': 'Good'},
            format='json',
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('booking', response.data.get('errors', {}))

    def test_review_fails_if_review_already_exists(self):
        booking = self._create_booking()
        Review.objects.create(listing=self.listing, guest=self.guest, booking=booking, rating=5, comment='First')

        self.client.force_authenticate(user=self.guest)
        response = self.client.post(
            '/api/reviews/',
            {'listing': self.listing.id, 'booking': booking.id, 'rating': 4, 'comment': 'Second'},
            format='json',
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('booking', response.data.get('errors', {}))
