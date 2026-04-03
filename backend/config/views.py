from django.db import connection
from drf_spectacular.utils import extend_schema, inline_serializer
from django.utils import timezone
from rest_framework import permissions, response, status, views
from rest_framework import serializers


class HealthCheckView(views.APIView):
    permission_classes = [permissions.AllowAny]
    authentication_classes = []

    @extend_schema(
        responses={
            200: inline_serializer(
                name='HealthCheckResponse',
                fields={
                    'status': serializers.CharField(),
                    'database': serializers.CharField(),
                    'database_engine': serializers.CharField(),
                    'timestamp': serializers.DateTimeField(),
                },
            )
        }
    )
    def get(self, request):
        db_ok = True
        try:
            with connection.cursor() as cursor:
                cursor.execute('SELECT 1')
                cursor.fetchone()
        except Exception:
            db_ok = False

        payload = {
            'status': 'ok' if db_ok else 'degraded',
            'database': 'ok' if db_ok else 'error',
            'database_engine': connection.vendor,
            'timestamp': timezone.now(),
        }
        http_status = status.HTTP_200_OK if db_ok else status.HTTP_503_SERVICE_UNAVAILABLE
        return response.Response(payload, status=http_status)
