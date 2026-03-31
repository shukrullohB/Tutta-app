import os
from pathlib import Path
from datetime import timedelta

from dotenv import load_dotenv

load_dotenv()

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = os.getenv('SECRET_KEY', 'replace-this-with-a-strong-secret-key-at-least-32-characters')
DEBUG = os.getenv('DEBUG', 'False').lower() == 'true'

ALLOWED_HOSTS = [host.strip() for host in os.getenv('ALLOWED_HOSTS', '127.0.0.1,localhost').split(',') if host.strip()]
CORS_ALLOWED_ORIGINS = [origin.strip() for origin in os.getenv('CORS_ALLOWED_ORIGINS', 'http://localhost:3000,http://127.0.0.1:3000,http://localhost:5173,http://127.0.0.1:5173').split(',') if origin.strip()]
CSRF_TRUSTED_ORIGINS = [origin.strip() for origin in os.getenv('CSRF_TRUSTED_ORIGINS', 'http://localhost:3000,http://127.0.0.1:3000,http://localhost:5173,http://127.0.0.1:5173').split(',') if origin.strip()]
CORS_ALLOWED_ORIGIN_REGEXES = []

if os.getenv('CORS_ALLOW_LOCALHOST_ANY_PORT', 'True').lower() == 'true':
    CORS_ALLOWED_ORIGIN_REGEXES += [
        r'^http://localhost:\d+$',
        r'^http://127\.0\.0\.1:\d+$',
    ]

GOOGLE_OAUTH_CLIENT_IDS = [
    value.strip()
    for value in os.getenv(
        'GOOGLE_OAUTH_CLIENT_IDS',
        os.getenv('GOOGLE_WEB_CLIENT_ID', ''),
    ).split(',')
    if value.strip()
]

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'corsheaders',
    'rest_framework',
    'rest_framework_simplejwt',
    'rest_framework_simplejwt.token_blacklist',
    'drf_spectacular',
    'django_filters',
    'apps.users',
    'apps.listings',
    'apps.bookings',
    'apps.reviews',
    'apps.chat',
    'apps.payments',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'corsheaders.middleware.CorsMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'config.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'config.wsgi.application'
ASGI_APPLICATION = 'config.asgi.application'

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.getenv('POSTGRES_DB', 'tutta_db'),
        'USER': os.getenv('POSTGRES_USER', 'tutta_user'),
        'PASSWORD': os.getenv('POSTGRES_PASSWORD', 'tutta_pass'),
        'HOST': os.getenv('POSTGRES_HOST', 'localhost'),
        'PORT': os.getenv('POSTGRES_PORT', '5432'),
    }
}

if os.getenv('USE_SQLITE', 'False').lower() == 'true':
    DATABASES['default'] = {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }

AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

LANGUAGE_CODE = 'en-us'
TIME_ZONE = os.getenv('TIME_ZONE', 'UTC')
USE_I18N = True
USE_TZ = True

STATIC_URL = 'static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'

MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'
AUTH_USER_MODEL = 'users.User'

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ),
    'DEFAULT_PERMISSION_CLASSES': (
        'rest_framework.permissions.IsAuthenticated',
    ),
    'DEFAULT_FILTER_BACKENDS': (
        'django_filters.rest_framework.DjangoFilterBackend',
        'rest_framework.filters.OrderingFilter',
        'rest_framework.filters.SearchFilter',
    ),
    'DEFAULT_THROTTLE_CLASSES': (
        'rest_framework.throttling.ScopedRateThrottle',
    ),
    'DEFAULT_THROTTLE_RATES': {
        'auth_register': os.getenv('THROTTLE_AUTH_REGISTER', '10/hour'),
        'auth_login': os.getenv('THROTTLE_AUTH_LOGIN', '20/hour'),
        'auth_google': os.getenv('THROTTLE_AUTH_GOOGLE', '20/hour'),
        'auth_refresh': os.getenv('THROTTLE_AUTH_REFRESH', '60/hour'),
        'auth_logout': os.getenv('THROTTLE_AUTH_LOGOUT', '60/hour'),
        'users_me': os.getenv('THROTTLE_USERS_ME', '120/hour'),
        'listings_list': os.getenv('THROTTLE_LISTINGS_LIST', '300/hour'),
        'listings_write': os.getenv('THROTTLE_LISTINGS_WRITE', '120/hour'),
        'listings_action': os.getenv('THROTTLE_LISTINGS_ACTION', '120/hour'),
        'bookings_list': os.getenv('THROTTLE_BOOKINGS_LIST', '300/hour'),
        'bookings_write': os.getenv('THROTTLE_BOOKINGS_WRITE', '120/hour'),
        'bookings_action': os.getenv('THROTTLE_BOOKINGS_ACTION', '120/hour'),
        'reviews_list': os.getenv('THROTTLE_REVIEWS_LIST', '300/hour'),
        'reviews_write': os.getenv('THROTTLE_REVIEWS_WRITE', '120/hour'),
        'chat_threads': os.getenv('THROTTLE_CHAT_THREADS', '300/hour'),
        'chat_messages': os.getenv('THROTTLE_CHAT_MESSAGES', '600/hour'),
        'payments_intents': os.getenv('THROTTLE_PAYMENTS_INTENTS', '120/hour'),
        'payments_webhook': os.getenv('THROTTLE_PAYMENTS_WEBHOOK', '300/hour'),
    },
    'DEFAULT_PAGINATION_CLASS': 'config.pagination.DefaultPageNumberPagination',
    'PAGE_SIZE': int(os.getenv('API_PAGE_SIZE', '20')),
    'DEFAULT_SCHEMA_CLASS': 'drf_spectacular.openapi.AutoSchema',
    'EXCEPTION_HANDLER': 'config.exceptions.tutta_exception_handler',
}

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=int(os.getenv('JWT_ACCESS_MINUTES', '60'))),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=int(os.getenv('JWT_REFRESH_DAYS', '7'))),
    'ROTATE_REFRESH_TOKENS': True,
    'BLACKLIST_AFTER_ROTATION': True,
    'UPDATE_LAST_LOGIN': True,
    'AUTH_HEADER_TYPES': ('Bearer',),
}

SPECTACULAR_SETTINGS = {
    'TITLE': 'Tutta Backend API',
    'DESCRIPTION': 'API documentation for Tutta rental marketplace backend.',
    'VERSION': '1.0.0',
    'SERVE_INCLUDE_SCHEMA': False,
    'ENUM_NAME_OVERRIDES': {
        'BookingStatusEnum': [
            ('pending', 'Pending'),
            ('confirmed', 'Confirmed'),
            ('cancelled', 'Cancelled'),
        ],
        'PaymentStatusEnum': [
            ('pending', 'Pending'),
            ('succeeded', 'Succeeded'),
            ('failed', 'Failed'),
            ('cancelled', 'Cancelled'),
        ],
    },
}

if not DEBUG:
    SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
    SECURE_SSL_REDIRECT = os.getenv('SECURE_SSL_REDIRECT', 'False').lower() == 'true'
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
    SECURE_HSTS_SECONDS = int(os.getenv('SECURE_HSTS_SECONDS', '31536000'))
    SECURE_HSTS_INCLUDE_SUBDOMAINS = os.getenv('SECURE_HSTS_INCLUDE_SUBDOMAINS', 'True').lower() == 'true'
    SECURE_HSTS_PRELOAD = os.getenv('SECURE_HSTS_PRELOAD', 'True').lower() == 'true'
    SECURE_CONTENT_TYPE_NOSNIFF = True
    X_FRAME_OPTIONS = os.getenv('X_FRAME_OPTIONS', 'DENY')
    REFERRER_POLICY = os.getenv('REFERRER_POLICY', 'same-origin')
