from rest_framework import status
from rest_framework.test import APITestCase

from .models import User


class AuthApiTests(APITestCase):
    def test_health_endpoint_is_public(self):
        response = self.client.get('/api/health')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['status'], 'ok')
        self.assertEqual(response.data['database'], 'ok')
        self.assertIn('timestamp', response.data)

    def test_register_login_and_me_flow(self):
        register_payload = {
            'email': 'guest1@example.com',
            'password': 'StrongPass123!',
            'password_confirm': 'StrongPass123!',
            'first_name': 'Guest',
            'last_name': 'One',
            'role': 'guest',
            'phone_number': '+998901112233',
        }
        register_response = self.client.post('/api/auth/register', register_payload, format='json')
        self.assertEqual(register_response.status_code, status.HTTP_201_CREATED)

        login_response = self.client.post(
            '/api/auth/login',
            {'email': register_payload['email'], 'password': register_payload['password']},
            format='json',
        )
        self.assertEqual(login_response.status_code, status.HTTP_200_OK)
        self.assertIn('access', login_response.data)

        token = login_response.data['access']
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        me_response = self.client.get('/api/users/me')
        self.assertEqual(me_response.status_code, status.HTTP_200_OK)
        self.assertEqual(me_response.data['email'], register_payload['email'])

    def test_register_fails_when_password_mismatch(self):
        payload = {
            'email': 'guest2@example.com',
            'password': 'StrongPass123!',
            'password_confirm': 'StrongPass124!',
            'first_name': 'Guest',
            'last_name': 'Two',
            'role': 'guest',
            'phone_number': '+998909999999',
        }
        response = self.client.post('/api/auth/register', payload, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(User.objects.filter(email=payload['email']).count(), 0)
