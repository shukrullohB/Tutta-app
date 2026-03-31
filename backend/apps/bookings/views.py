from datetime import date

from django.db.models import Q
from drf_spectacular.utils import extend_schema, inline_serializer
from rest_framework import serializers
from rest_framework.exceptions import PermissionDenied
from rest_framework import generics, permissions, response, status, throttling, views

from .models import Booking
from .serializers import BookingCreateSerializer, BookingSerializer


class BookingListCreateView(generics.ListCreateAPIView):
    permission_classes = [permissions.IsAuthenticated]
    throttle_classes = [throttling.ScopedRateThrottle]

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return BookingCreateSerializer
        return BookingSerializer

    def get_throttles(self):
        self.throttle_scope = 'bookings_write' if self.request.method == 'POST' else 'bookings_list'
        return super().get_throttles()

    def get_queryset(self):
        queryset = Booking.objects.select_related('listing', 'guest', 'listing__host')
        if not self.request.user.is_authenticated:
            return queryset.none()
        role = self.request.query_params.get('role')

        if role == 'host':
            return queryset.filter(listing__host=self.request.user)
        if role == 'guest':
            return queryset.filter(guest=self.request.user)

        if self.request.user.role == 'host':
            return queryset.filter(Q(listing__host=self.request.user) | Q(guest=self.request.user))
        return queryset.filter(guest=self.request.user)

    def perform_create(self, serializer):
        if self.request.user.role != 'guest':
            # Keep initial booking flow strict: only guests can create reservations.
            raise PermissionDenied('Only guest users can create bookings.')
        serializer.save()


class BookingConfirmView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]
    throttle_classes = [throttling.ScopedRateThrottle]
    throttle_scope = 'bookings_action'

    @extend_schema(
        request=None,
        responses={
            200: inline_serializer(
                name='BookingConfirmResponse',
                fields={
                    'booking_id': serializers.IntegerField(),
                    'status': serializers.CharField(),
                    'detail': serializers.CharField(),
                },
            ),
        },
    )
    def post(self, request, pk):
        booking = generics.get_object_or_404(
            Booking.objects.select_related('listing', 'listing__host'),
            pk=pk,
        )

        if booking.listing.host_id != request.user.id:
            return response.Response({'detail': 'Only listing host can confirm this booking.'}, status=status.HTTP_403_FORBIDDEN)

        if booking.status != Booking.Status.PENDING:
            return response.Response({'detail': 'Only pending bookings can be confirmed.'}, status=status.HTTP_400_BAD_REQUEST)

        conflict_exists = Booking.objects.filter(
            listing=booking.listing,
            status=Booking.Status.CONFIRMED,
        ).exclude(pk=booking.pk).filter(
            Q(start_date__lt=booking.end_date) & Q(end_date__gt=booking.start_date)
        ).exists()

        if conflict_exists:
            return response.Response({'detail': 'Booking dates conflict with another confirmed booking.'}, status=status.HTTP_400_BAD_REQUEST)

        booking.status = Booking.Status.CONFIRMED
        booking.save(update_fields=['status'])
        return response.Response({'booking_id': booking.id, 'status': booking.status, 'detail': 'Booking confirmed.'}, status=status.HTTP_200_OK)


class BookingCancelView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]
    throttle_classes = [throttling.ScopedRateThrottle]
    throttle_scope = 'bookings_action'

    @extend_schema(
        request=None,
        responses={
            200: inline_serializer(
                name='BookingCancelResponse',
                fields={
                    'booking_id': serializers.IntegerField(),
                    'status': serializers.CharField(),
                    'detail': serializers.CharField(),
                },
            ),
        },
    )
    def post(self, request, pk):
        booking = generics.get_object_or_404(
            Booking.objects.select_related('listing', 'listing__host', 'guest'),
            pk=pk,
        )

        is_guest = booking.guest_id == request.user.id
        is_host = booking.listing.host_id == request.user.id

        if not (is_guest or is_host):
            return response.Response({'detail': 'Only booking guest or listing host can cancel.'}, status=status.HTTP_403_FORBIDDEN)

        if booking.status == Booking.Status.CANCELLED:
            return response.Response({'detail': 'Booking is already cancelled.'}, status=status.HTTP_400_BAD_REQUEST)

        if booking.end_date < date.today():
            return response.Response({'detail': 'Past bookings cannot be cancelled.'}, status=status.HTTP_400_BAD_REQUEST)

        booking.status = Booking.Status.CANCELLED
        booking.save(update_fields=['status'])
        return response.Response({'booking_id': booking.id, 'status': booking.status, 'detail': 'Booking cancelled.'}, status=status.HTTP_200_OK)
