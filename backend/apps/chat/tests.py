from rest_framework import status
from rest_framework.test import APITestCase

from apps.listings.models import Listing
from apps.users.models import User


class ChatApiTests(APITestCase):
    def setUp(self):
        self.host = User.objects.create_user(
            email='host-chat@example.com',
            password='StrongPass123!',
            first_name='Host',
            last_name='Chat',
            role='host',
        )
        self.guest = User.objects.create_user(
            email='guest-chat@example.com',
            password='StrongPass123!',
            first_name='Guest',
            last_name='Chat',
            role='guest',
        )
        self.listing = Listing.objects.create(
            host=self.host,
            title='Chat Ready Listing',
            description='For messaging tests',
            location='Bukhara',
            listing_type='home',
            price_per_night='100.00',
            max_guests=4,
            is_active=True,
        )

    def test_create_thread_and_send_message(self):
        self.client.force_authenticate(user=self.guest)
        thread_payload = {'listing': self.listing.id, 'guest_id': self.guest.id, 'host_id': self.host.id}
        thread_response = self.client.post('/api/chat/threads', thread_payload, format='json')
        self.assertEqual(thread_response.status_code, status.HTTP_201_CREATED)
        thread_id = thread_response.data['id']

        message_response = self.client.post(
            f'/api/chat/threads/{thread_id}/messages',
            {'content': 'Hello host'},
            format='json',
        )
        self.assertEqual(message_response.status_code, status.HTTP_201_CREATED)

        list_response = self.client.get(f'/api/chat/threads/{thread_id}/messages')
        self.assertEqual(list_response.status_code, status.HTTP_200_OK)
        self.assertGreaterEqual(len(list_response.data), 1)
