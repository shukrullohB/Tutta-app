from django.db.models import Q
from drf_spectacular.utils import extend_schema, inline_serializer
from rest_framework import generics, permissions, response, status, throttling, views
from rest_framework import serializers

from .models import Listing
from .permissions import IsHostUser, IsListingOwner
from .serializers import ListingCreateSerializer, ListingSerializer


class ListingListCreateView(generics.ListCreateAPIView):
    queryset = Listing.objects.select_related('host').prefetch_related('images')
    filterset_fields = ('listing_type', 'location')
    search_fields = ('title', 'description', 'location')
    ordering_fields = ('price_per_night', 'created_at')

    def get_permissions(self):
        if self.request.method == 'POST':
            return [permissions.IsAuthenticated(), IsHostUser()]
        return [permissions.AllowAny()]

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return ListingCreateSerializer
        return ListingSerializer

    def get_throttles(self):
        self.throttle_scope = 'listings_write' if self.request.method == 'POST' else 'listings_list'
        return super().get_throttles()

    def get_queryset(self):
        queryset = self.queryset.filter(is_active=True)
        min_price = self.request.query_params.get('min_price')
        max_price = self.request.query_params.get('max_price')

        if min_price:
            queryset = queryset.filter(price_per_night__gte=min_price)
        if max_price:
            queryset = queryset.filter(price_per_night__lte=max_price)

        return queryset


class ListingDetailView(generics.RetrieveAPIView):
    queryset = Listing.objects.select_related('host').prefetch_related('images')
    serializer_class = ListingSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        user = self.request.user
        if user.is_authenticated:
            return self.queryset.filter(Q(is_active=True) | Q(host=user))
        return self.queryset.filter(is_active=True)


class ListingManageView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Listing.objects.select_related('host').prefetch_related('images')
    serializer_class = ListingCreateSerializer
    permission_classes = [permissions.IsAuthenticated, IsHostUser, IsListingOwner]
    throttle_classes = [throttling.ScopedRateThrottle]
    throttle_scope = 'listings_write'

    def perform_destroy(self, instance):
        # Soft delete keeps booking/review history intact.
        instance.is_active = False
        instance.save(update_fields=['is_active', 'updated_at'])


class ListingPublishView(views.APIView):
    permission_classes = [permissions.IsAuthenticated, IsHostUser]
    throttle_classes = [throttling.ScopedRateThrottle]
    throttle_scope = 'listings_action'

    @extend_schema(
        request=None,
        responses={200: inline_serializer(name='ListingPublishResponse', fields={'detail': serializers.CharField()})},
    )
    def post(self, request, pk):
        listing = generics.get_object_or_404(Listing, pk=pk, host=request.user)
        listing.is_active = True
        listing.save(update_fields=['is_active', 'updated_at'])
        return response.Response({'detail': 'Listing published.'}, status=status.HTTP_200_OK)


class ListingUnpublishView(views.APIView):
    permission_classes = [permissions.IsAuthenticated, IsHostUser]
    throttle_classes = [throttling.ScopedRateThrottle]
    throttle_scope = 'listings_action'

    @extend_schema(
        request=None,
        responses={200: inline_serializer(name='ListingUnpublishResponse', fields={'detail': serializers.CharField()})},
    )
    def post(self, request, pk):
        listing = generics.get_object_or_404(Listing, pk=pk, host=request.user)
        listing.is_active = False
        listing.save(update_fields=['is_active', 'updated_at'])
        return response.Response({'detail': 'Listing unpublished.'}, status=status.HTTP_200_OK)
    throttle_classes = [throttling.ScopedRateThrottle]
