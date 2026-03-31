from django.conf import settings
from django.contrib.auth.password_validation import validate_password
from urllib import error as urllib_error
from urllib import request as urllib_request
import json
from rest_framework import serializers
from rest_framework_simplejwt.exceptions import TokenError
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.tokens import RefreshToken
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token as google_id_token

from .models import User


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ('id', 'email', 'first_name', 'last_name', 'role', 'phone_number', 'created_at')
        read_only_fields = ('id', 'created_at')


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8)
    password_confirm = serializers.CharField(write_only=True, min_length=8)

    class Meta:
        model = User
        fields = (
            'id',
            'email',
            'password',
            'password_confirm',
            'first_name',
            'last_name',
            'role',
            'phone_number',
            'created_at',
        )
        read_only_fields = ('id', 'created_at')

    def validate_email(self, value):
        if User.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError('A user with this email already exists.')
        return value

    def validate(self, attrs):
        if attrs['password'] != attrs['password_confirm']:
            raise serializers.ValidationError({'password_confirm': 'Passwords do not match.'})

        validate_password(attrs['password'])
        return attrs

    def create(self, validated_data):
        validated_data.pop('password_confirm', None)
        password = validated_data.pop('password')
        return User.objects.create_user(password=password, **validated_data)


class TuttaTokenObtainPairSerializer(TokenObtainPairSerializer):
    username_field = User.USERNAME_FIELD

    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token['email'] = user.email
        token['role'] = user.role
        return token

    def validate(self, attrs):
        data = super().validate(attrs)
        data['user'] = UserSerializer(self.user).data
        return data


class LogoutSerializer(serializers.Serializer):
    refresh = serializers.CharField()

    def validate(self, attrs):
        self.token = attrs['refresh']
        return attrs

    def save(self, **kwargs):
        try:
            token = RefreshToken(self.token)
            token.blacklist()
        except TokenError as exc:
            raise serializers.ValidationError({'refresh': 'Invalid or expired refresh token.'}) from exc


class GoogleLoginSerializer(serializers.Serializer):
    id_token = serializers.CharField(required=False, allow_blank=True)
    access_token = serializers.CharField(required=False, allow_blank=True)
    email = serializers.EmailField(required=False)
    display_name = serializers.CharField(required=False, allow_blank=True)

    def validate(self, attrs):
        token = (attrs.get('id_token') or '').strip()
        access_token = (attrs.get('access_token') or '').strip()
        if not token and not access_token:
            raise serializers.ValidationError(
                {'detail': 'id_token or access_token is required.'}
            )

        client_ids = getattr(settings, 'GOOGLE_OAUTH_CLIENT_IDS', [])
        if token and not client_ids:
            raise serializers.ValidationError(
                {'detail': 'Google OAuth is not configured on the server.'}
            )

        idinfo = {}
        last_error = None
        if token:
            request = google_requests.Request()
            for client_id in client_ids:
                try:
                    idinfo = google_id_token.verify_oauth2_token(token, request, client_id)
                    break
                except Exception as exc:  # noqa: BLE001
                    last_error = exc
            if not idinfo:
                raise serializers.ValidationError(
                    {'id_token': 'Invalid Google token.'}
                ) from last_error
        else:
            try:
                req = urllib_request.Request(
                    'https://www.googleapis.com/oauth2/v3/userinfo',
                    headers={'Authorization': f'Bearer {access_token}'},
                )
                with urllib_request.urlopen(req, timeout=5) as resp:
                    payload = resp.read().decode('utf-8')
                idinfo = json.loads(payload)
            except (urllib_error.URLError, TimeoutError, json.JSONDecodeError) as exc:
                raise serializers.ValidationError(
                    {'access_token': 'Invalid Google access token.'}
                ) from exc

        email = (idinfo.get('email') or '').strip()
        if not email:
            raise serializers.ValidationError({'detail': 'Google token has no email claim.'})

        self.idinfo = idinfo
        self.email = email.lower()
        return attrs

    def _split_name(self):
        name = (self.idinfo.get('name') or '').strip()
        given_name = (self.idinfo.get('given_name') or '').strip()
        family_name = (self.idinfo.get('family_name') or '').strip()

        if given_name or family_name:
            return given_name or 'Google', family_name or 'User'

        if name:
            parts = [part for part in name.split(' ') if part]
            if len(parts) == 1:
                return parts[0], 'User'
            if len(parts) > 1:
                return parts[0], ' '.join(parts[1:])

        return 'Google', 'User'

    def create(self, validated_data):
        first_name, last_name = self._split_name()
        user, created = User.objects.get_or_create(
            email=self.email,
            defaults={
                'first_name': first_name,
                'last_name': last_name,
                'role': User.Role.GUEST,
                'phone_number': '',
            },
        )

        # keep existing accounts, but fill empty names if needed
        changed = False
        if not user.first_name:
            user.first_name = first_name
            changed = True
        if not user.last_name:
            user.last_name = last_name
            changed = True
        if changed and not created:
            user.save(update_fields=['first_name', 'last_name'])

        refresh = RefreshToken.for_user(user)
        refresh['email'] = user.email
        refresh['role'] = user.role
        return {
            'user': user,
            'access': str(refresh.access_token),
            'refresh': str(refresh),
        }
