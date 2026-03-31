import os

from django.db.models import Q
from drf_spectacular.utils import extend_schema, inline_serializer
from rest_framework import generics, permissions, response, status, throttling, views
from rest_framework import serializers

from .models import Payment
from .serializers import PaymentIntentCreateSerializer, PaymentSerializer, PaymentWebhookSerializer


class PaymentIntentListCreateView(generics.ListCreateAPIView):
    permission_classes = [permissions.IsAuthenticated]
    throttle_classes = [throttling.ScopedRateThrottle]
    throttle_scope = 'payments_intents'

    def get_queryset(self):
        if not self.request.user.is_authenticated:
            return Payment.objects.none()
        return (
            Payment.objects.select_related('booking', 'booking__guest', 'booking__listing', 'booking__listing__host')
            .filter(Q(booking__guest=self.request.user) | Q(booking__listing__host=self.request.user))
        )

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return PaymentIntentCreateSerializer
        return PaymentSerializer


class PaymentIntentDetailView(generics.RetrieveAPIView):
    serializer_class = PaymentSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        if not self.request.user.is_authenticated:
            return Payment.objects.none()
        return (
            Payment.objects.select_related('booking', 'booking__guest', 'booking__listing', 'booking__listing__host')
            .filter(Q(booking__guest=self.request.user) | Q(booking__listing__host=self.request.user))
        )


class PaymentWebhookView(views.APIView):
    permission_classes = [permissions.AllowAny]
    authentication_classes = []
    throttle_classes = [throttling.ScopedRateThrottle]
    throttle_scope = 'payments_webhook'

    @extend_schema(
        request=PaymentWebhookSerializer,
        responses={
            200: PaymentSerializer,
            403: inline_serializer(name='PaymentWebhookForbidden', fields={'detail': serializers.CharField()}),
        },
    )
    def post(self, request, provider):
        if provider not in Payment.Provider.values:
            return response.Response({'detail': 'Unsupported payment provider.'}, status=status.HTTP_400_BAD_REQUEST)

        secret = os.getenv(f'PAYMENT_WEBHOOK_SECRET_{provider.upper()}', '').strip()
        provided = request.headers.get('X-Webhook-Secret', '').strip()

        if secret and provided != secret:
            return response.Response({'detail': 'Invalid webhook secret.'}, status=status.HTTP_403_FORBIDDEN)

        serializer = PaymentWebhookSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        payment = serializer.save(provider=provider)
        return response.Response(PaymentSerializer(payment).data, status=status.HTTP_200_OK)
