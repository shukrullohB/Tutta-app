from rest_framework import status
from rest_framework.test import APITestCase

from apps.users.models import User


class ListingApiTests(APITestCase):
    def setUp(self):
        self.host = User.objects.create_user(
            email='host@example.com',
            password='StrongPass123!',
            first_name='Host',
            last_name='User',
            role='host',
        )

    def test_host_can_create_listing(self):
        self.client.force_authenticate(user=self.host)
        payload = {
            'title': 'Cozy Apartment',
            'description': 'Central location and fast wifi',
            'location': 'Tashkent',
            'listing_type': 'home',
            'price_per_night': '75.00',
            'max_guests': 3,
        }
        response = self.client.post('/api/listings/', payload, format='multipart')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['title'], payload['title'])
