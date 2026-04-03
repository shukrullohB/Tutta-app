import os

from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path, re_path
from django.views.static import serve
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView

from .views import HealthCheckView

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/health', HealthCheckView.as_view(), name='api-health'),
    path('api/schema/', SpectacularAPIView.as_view(), name='api-schema'),
    path('api/docs/', SpectacularSwaggerView.as_view(url_name='api-schema'), name='api-docs'),
    path('api/auth/', include('apps.users.urls')),
    path('api/users/', include('apps.users.urls_user')),
    path('api/listings/', include('apps.listings.urls')),
    path('api/bookings/', include('apps.bookings.urls')),
    path('api/reviews/', include('apps.reviews.urls')),
    path('api/chat/', include('apps.chat.urls')),
    path('api/payments/', include('apps.payments.urls')),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
elif os.getenv('SERVE_MEDIA', 'True').lower() == 'true':
    media_prefix = settings.MEDIA_URL.lstrip('/')
    urlpatterns += [
        re_path(
            rf'^{media_prefix}(?P<path>.*)$',
            serve,
            kwargs={'document_root': settings.MEDIA_ROOT},
        ),
    ]
