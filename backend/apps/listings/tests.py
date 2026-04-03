from rest_framework import status
from rest_framework.test import APITestCase
from django.core.files.uploadedfile import SimpleUploadedFile
from urllib.parse import quote

from apps.listings.models import AvailabilityDay, ListingImage
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
        self.guest = User.objects.create_user(
            email='guest@example.com',
            password='StrongPass123!',
            first_name='Guest',
            last_name='User',
            role='guest',
        )
        self.admin = User.objects.create_superuser(
            email='admin@example.com',
            password='StrongPass123!',
            first_name='Admin',
            last_name='User',
            role='host',
        )

    def test_host_can_create_listing(self):
        self.client.force_authenticate(user=self.host)
        payload = {
            'title': 'Cozy Apartment',
            'description': 'Central location and fast wifi',
            'location': 'Tashkent, Yunusabad',
            'city': 'Tashkent',
            'district': 'Yunusabad',
            'listing_type': 'home',
            'price_per_night': '75.00',
            'max_guests': 3,
            'min_days': 1,
            'max_days': 10,
        }
        response = self.client.post('/api/listings/', payload, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['title'], payload['title'])
        self.assertEqual(response.data['city'], 'Tashkent')
        self.assertEqual(response.data['district'], 'Yunusabad')
        self.assertEqual(response.data['moderation_status'], 'approved')
        self.assertTrue(response.data['is_active'])
        self.assertEqual(response.data['host_id'], self.host.id)

    def test_guest_can_create_listing_and_becomes_host(self):
        self.client.force_authenticate(user=self.guest)
        payload = {
            'title': 'Guest created listing',
            'description': 'Created after switching to host role automatically',
            'location': 'Tashkent, Chilonzor',
            'city': 'Tashkent',
            'district': 'Chilonzor',
            'listing_type': 'home',
            'price_per_night': '55.00',
            'max_guests': 2,
            'min_days': 1,
            'max_days': 7,
            'amenities': ['wifi', 'kitchen'],
        }
        response = self.client.post('/api/listings/', payload, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.guest.refresh_from_db()
        self.assertEqual(self.guest.role, User.Role.HOST)
        self.assertEqual(response.data['host_id'], self.guest.id)
        self.assertEqual(response.data['amenities'], ['wifi', 'kitchen'])

    def test_host_can_create_free_stay_listing(self):
        self.client.force_authenticate(user=self.host)
        payload = {
            'title': 'Language exchange room',
            'description': 'Free stay for cultural exchange',
            'location': 'Samarkand, Registan',
            'city': 'Samarkand',
            'district': 'Registan',
            'listing_type': 'free_stay',
            'max_guests': 1,
            'min_days': 2,
            'max_days': 14,
            'free_stay_profile': {
                'languages_communication': ['uz', 'en'],
                'languages_practice': ['en'],
                'host_lives_together': True,
                'terms': 'Respect local customs',
            },
        }
        response = self.client.post('/api/listings/', payload, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['listing_type'], 'free_stay')
        self.assertTrue(response.data['is_free_stay'])
        self.assertIsNone(response.data['price_per_night'])

    def test_created_listing_is_visible_in_mine_and_public_feed(self):
        self.client.force_authenticate(user=self.host)
        create_response = self.client.post(
            '/api/listings/',
            {
                'title': 'Visible listing',
                'description': 'Ready for guests right away',
                'location': 'Tashkent, Mirzo Ulugbek',
                'city': 'Tashkent',
                'district': 'Mirzo Ulugbek',
                'listing_type': 'room',
                'price_per_night': '50.00',
                'max_guests': 2,
                'min_days': 1,
                'max_days': 7,
            },
            format='json',
        )
        self.assertEqual(create_response.status_code, status.HTTP_201_CREATED)
        listing_id = create_response.data['id']

        mine_response = self.client.get('/api/listings/?mine=true')
        self.assertEqual(mine_response.status_code, status.HTTP_200_OK)
        self.assertEqual(mine_response.data['count'], 1)
        self.assertEqual(mine_response.data['results'][0]['id'], listing_id)

        self.client.force_authenticate(user=None)
        public_response = self.client.get('/api/listings/')
        self.assertEqual(public_response.status_code, status.HTTP_200_OK)
        self.assertEqual(public_response.data['count'], 1)
        self.assertEqual(public_response.data['results'][0]['id'], listing_id)

        detail_response = self.client.get(f'/api/listings/{listing_id}')
        self.assertEqual(detail_response.status_code, status.HTTP_200_OK)
        self.assertEqual(detail_response.data['id'], listing_id)
        self.assertEqual(detail_response.data['title'], 'Visible listing')
        self.assertEqual(detail_response.data['city'], 'Tashkent')
        self.assertEqual(detail_response.data['district'], 'Mirzo Ulugbek')

    def test_updating_listing_keeps_it_active_and_approved(self):
        self.client.force_authenticate(user=self.host)
        create_response = self.client.post(
            '/api/listings/',
            {
                'title': 'Editable listing',
                'description': 'Before edit',
                'location': 'Tashkent, Yakkasaray',
                'city': 'Tashkent',
                'district': 'Yakkasaray',
                'listing_type': 'home',
                'price_per_night': '80.00',
                'max_guests': 2,
                'min_days': 1,
                'max_days': 10,
            },
            format='json',
        )
        self.assertEqual(create_response.status_code, status.HTTP_201_CREATED)
        listing_id = create_response.data['id']

        self.client.force_authenticate(user=self.host)
        update_response = self.client.put(
            f'/api/listings/{listing_id}/manage',
            {
                'title': 'Editable listing (updated)',
                'description': 'After edit',
                'city': 'Tashkent',
                'district': 'Yakkasaray',
                'location': 'Tashkent, Yakkasaray',
                'listing_type': 'home',
                'price_per_night': '85.00',
                'max_guests': 2,
                'min_days': 1,
                'max_days': 10,
                'amenities': ['wifi', 'parking'],
                'show_phone': False,
                'free_stay_profile': {},
            },
            format='json',
        )
        self.assertEqual(update_response.status_code, status.HTTP_200_OK)
        self.assertEqual(update_response.data['moderation_status'], 'approved')
        self.assertTrue(update_response.data['is_active'])
        self.assertEqual(update_response.data['amenities'], ['wifi', 'parking'])

    def test_host_can_create_listing_with_image_and_detail_returns_it(self):
        self.client.force_authenticate(user=self.host)
        image = SimpleUploadedFile(
            'room.gif',
            (
                b'GIF89a\x01\x00\x01\x00\x80\x00\x00\x00\x00\x00'
                b'\xff\xff\xff!\xf9\x04\x00\x00\x00\x00\x00,'
                b'\x00\x00\x00\x00\x01\x00\x01\x00\x00\x02\x02D\x01\x00;'
            ),
            content_type='image/gif',
        )
        response = self.client.post(
            '/api/listings/',
            {
                'title': 'Image listing',
                'description': 'Listing with uploaded image',
                'location': 'Tashkent, Yunusabad',
                'city': 'Tashkent',
                'district': 'Yunusabad',
                'listing_type': 'home',
                'price_per_night': '120.00',
                'max_guests': 2,
                'min_days': 1,
                'max_days': 7,
                'amenities': ['wifi', 'kitchen'],
                'image_files': [image],
            },
            format='multipart',
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['title'], 'Image listing')
        self.assertTrue(response.data['images'])

        listing_id = response.data['id']
        detail_response = self.client.get(f'/api/listings/{listing_id}')
        self.assertEqual(detail_response.status_code, status.HTTP_200_OK)
        self.assertTrue(detail_response.data['images'])

    def test_host_can_set_availability_days(self):
        self.client.force_authenticate(user=self.host)
        create_response = self.client.post(
            '/api/listings/',
            {
                'title': 'Availability listing',
                'description': 'Calendar test',
                'location': 'Tashkent, Yunusabad',
                'city': 'Tashkent',
                'district': 'Yunusabad',
                'listing_type': 'room',
                'price_per_night': '40.00',
                'max_guests': 2,
                'min_days': 1,
                'max_days': 7,
            },
            format='json',
        )
        self.assertEqual(create_response.status_code, status.HTTP_201_CREATED)
        listing_id = create_response.data['id']

        put_response = self.client.put(
            f'/api/listings/{listing_id}/availability',
            {
                'days': [
                    {'date': '2030-07-10', 'is_available': False, 'note': 'maintenance'},
                    {'date': '2030-07-11', 'is_available': True},
                ]
            },
            format='json',
        )
        self.assertEqual(put_response.status_code, status.HTTP_200_OK)
        self.assertEqual(AvailabilityDay.objects.filter(listing_id=listing_id).count(), 2)

        self.client.force_authenticate(user=None)
        public_get = self.client.get(f'/api/listings/{listing_id}/availability')
        self.assertEqual(public_get.status_code, status.HTTP_200_OK)
        self.assertEqual(len(public_get.data['results']), 1)

        self.client.force_authenticate(user=self.guest)
        guest_get = self.client.get(f'/api/listings/{listing_id}/availability')
        self.assertEqual(guest_get.status_code, status.HTTP_200_OK)
        self.assertEqual(len(guest_get.data['results']), 2)

    def test_update_can_remove_image_by_encoded_url(self):
        self.client.force_authenticate(user=self.host)
        image = SimpleUploadedFile(
            'Без имени.png',
            (
                b'GIF89a\x01\x00\x01\x00\x80\x00\x00\x00\x00\x00'
                b'\xff\xff\xff!\xf9\x04\x00\x00\x00\x00\x00,'
                b'\x00\x00\x00\x00\x01\x00\x01\x00\x00\x02\x02D\x01\x00;'
            ),
            content_type='image/png',
        )
        create_response = self.client.post(
            '/api/listings/',
            {
                'title': 'Image remove test',
                'description': 'Should remove encoded image url',
                'location': 'Tashkent, Yunusabad',
                'city': 'Tashkent',
                'district': 'Yunusabad',
                'listing_type': 'home',
                'price_per_night': '120.00',
                'max_guests': 2,
                'min_days': 1,
                'max_days': 7,
                'amenities': ['wifi'],
                'image_files': [image],
            },
            format='multipart',
        )
        self.assertEqual(create_response.status_code, status.HTTP_201_CREATED)
        listing_id = create_response.data['id']
        original_image_url = create_response.data['images'][0]['image']
        encoded_image_url = quote(original_image_url, safe='/:%')

        update_response = self.client.put(
            f'/api/listings/{listing_id}/manage',
            {
                'title': 'Image remove test',
                'description': 'Should remove encoded image url',
                'city': 'Tashkent',
                'district': 'Yunusabad',
                'location': 'Tashkent, Yunusabad',
                'listing_type': 'home',
                'price_per_night': '120.00',
                'max_guests': 2,
                'min_days': 1,
                'max_days': 7,
                'amenities': ['wifi'],
                'show_phone': 'false',
                'free_stay_profile': '{}',
                'remove_image_urls': [encoded_image_url],
            },
            format='multipart',
        )
        self.assertEqual(update_response.status_code, status.HTTP_200_OK)
        self.assertEqual(ListingImage.objects.filter(listing_id=listing_id).count(), 0)

        detail_response = self.client.get(f'/api/listings/{listing_id}')
        self.assertEqual(detail_response.status_code, status.HTTP_200_OK)
        self.assertEqual(detail_response.data['images'], [])

    def test_delete_listing_hides_it_from_host_and_public_lists(self):
        self.client.force_authenticate(user=self.host)
        create_response = self.client.post(
            '/api/listings/',
            {
                'title': 'Delete listing test',
                'description': 'Should disappear from list after delete',
                'location': 'Tashkent, Yakkasaray',
                'city': 'Tashkent',
                'district': 'Yakkasaray',
                'listing_type': 'home',
                'price_per_night': '100.00',
                'max_guests': 2,
                'min_days': 1,
                'max_days': 7,
            },
            format='json',
        )
        self.assertEqual(create_response.status_code, status.HTTP_201_CREATED)
        listing_id = create_response.data['id']

        delete_response = self.client.delete(f'/api/listings/{listing_id}/manage')
        self.assertEqual(delete_response.status_code, status.HTTP_204_NO_CONTENT)

        mine_response = self.client.get('/api/listings/?mine=true')
        self.assertEqual(mine_response.status_code, status.HTTP_200_OK)
        self.assertEqual(mine_response.data['count'], 0)

        self.client.force_authenticate(user=None)
        public_response = self.client.get('/api/listings/')
        self.assertEqual(public_response.status_code, status.HTTP_200_OK)
        self.assertEqual(public_response.data['count'], 0)
