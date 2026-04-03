from django.db.models import Q
from drf_spectacular.utils import extend_schema, inline_serializer
from rest_framework import generics, permissions, response, status, throttling, views
from rest_framework import serializers

from .models import AvailabilityDay, Listing
from .permissions import IsHostUser, IsListingOwner
from .serializers import AvailabilityDaySerializer, ListingCreateSerializer, ListingSerializer

HOST_DELETED_NOTE = '__HOST_DELETED__'


class ListingListCreateView(generics.ListCreateAPIView):
    queryset = Listing.objects.select_related('host').prefetch_related('images')
    filterset_fields = ('listing_type', 'location', 'city', 'district')
    search_fields = ('title', 'description', 'location', 'city', 'district', 'landmark', 'metro')
    ordering_fields = ('price_per_night', 'created_at')

    def get_permissions(self):
        if self.request.method == 'POST':
            return [permissions.IsAuthenticated()]
        return [permissions.AllowAny()]

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return ListingCreateSerializer
        return ListingSerializer

    def get_throttles(self):
        self.throttle_scope = 'listings_write' if self.request.method == 'POST' else 'listings_list'
        return super().get_throttles()

    def get_queryset(self):
        queryset = self.queryset.exclude(moderation_note=HOST_DELETED_NOTE)
        user = self.request.user
        q = self.request.query_params.get('q')
        city = self.request.query_params.get('city')
        district = self.request.query_params.get('district')
        host = self.request.query_params.get('host')
        listing_type = self.request.query_params.get('type')
        guests = self.request.query_params.get('guests')
        min_price = self.request.query_params.get('min_price')
        max_price = self.request.query_params.get('max_price')

        if q:
            queryset = queryset.filter(
                Q(title__icontains=q)
                | Q(description__icontains=q)
                | Q(location__icontains=q)
            )
        if city:
            queryset = queryset.filter(Q(city__icontains=city) | Q(location__icontains=city))
        if district:
            queryset = queryset.filter(
                Q(district__icontains=district)
                | Q(location__icontains=district)
                | Q(landmark__icontains=district)
                | Q(metro__icontains=district)
            )
        if listing_type:
            queryset = queryset.filter(listing_type=listing_type)
        if host:
            queryset = queryset.filter(host_id=host)
        if guests:
            try:
                guests_count = int(guests)
                queryset = queryset.filter(max_guests__gte=guests_count)
            except (TypeError, ValueError):
                pass
        if min_price:
            queryset = queryset.filter(price_per_night__gte=min_price)
        if max_price:
            queryset = queryset.filter(price_per_night__lte=max_price)

        public_queryset = queryset.filter(
            is_active=True,
            moderation_status=Listing.ModerationStatus.APPROVED,
        )

        if host:
            if user.is_authenticated and str(user.id) == str(host):
                return queryset
            return public_queryset

        if user.is_authenticated:
            mine = self.request.query_params.get('mine')
            if mine in {'1', 'true', 'True'}:
                return queryset.filter(host=user)
            own_queryset = queryset.filter(host=user)
            return (public_queryset | own_queryset).distinct()

        return public_queryset

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        listing = serializer.save()
        listing.refresh_from_db()
        response_serializer = ListingSerializer(
            listing,
            context=self.get_serializer_context(),
        )
        headers = self.get_success_headers(response_serializer.data)
        return response.Response(
            response_serializer.data,
            status=status.HTTP_201_CREATED,
            headers=headers,
        )


class ListingDetailView(generics.RetrieveAPIView):
    queryset = Listing.objects.select_related('host').prefetch_related('images')
    serializer_class = ListingSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        user = self.request.user
        base_queryset = self.queryset.exclude(moderation_note=HOST_DELETED_NOTE)
        public_queryset = base_queryset.filter(
            is_active=True,
            moderation_status=Listing.ModerationStatus.APPROVED,
        )
        if user.is_authenticated:
            return base_queryset.filter(
                Q(
                    is_active=True,
                    moderation_status=Listing.ModerationStatus.APPROVED,
                )
                | Q(host=user)
            )
        return public_queryset


class ListingManageView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Listing.objects.select_related('host').prefetch_related('images')
    serializer_class = ListingCreateSerializer
    permission_classes = [permissions.IsAuthenticated, IsHostUser, IsListingOwner]
    throttle_classes = [throttling.ScopedRateThrottle]
    throttle_scope = 'listings_write'

    def get_queryset(self):
        return self.queryset.exclude(moderation_note=HOST_DELETED_NOTE)

    def perform_destroy(self, instance):
        # Soft delete keeps booking/review history intact.
        instance.is_active = False
        instance.moderation_status = Listing.ModerationStatus.REJECTED
        instance.moderation_note = HOST_DELETED_NOTE
        instance.save(
            update_fields=[
                'is_active',
                'moderation_status',
                'moderation_note',
                'updated_at',
            ]
        )

    def update(self, request, *args, **kwargs):
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        serializer = self.get_serializer(
            instance,
            data=request.data,
            partial=partial,
        )
        serializer.is_valid(raise_exception=True)
        listing = serializer.save()
        listing = (
            Listing.objects.select_related('host')
            .prefetch_related('images')
            .get(pk=listing.pk)
        )
        response_serializer = ListingSerializer(
            listing,
            context=self.get_serializer_context(),
        )
        return response.Response(response_serializer.data, status=status.HTTP_200_OK)


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
        if listing.moderation_status in {
            Listing.ModerationStatus.DRAFT,
            Listing.ModerationStatus.REJECTED,
        }:
            listing.moderation_status = Listing.ModerationStatus.PENDING
            listing.moderation_note = ''
            listing.save(update_fields=['is_active', 'moderation_status', 'moderation_note', 'updated_at'])
            return response.Response({'detail': 'Listing submitted for moderation.'}, status=status.HTTP_200_OK)

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


class ListingApproveView(views.APIView):
    permission_classes = [permissions.IsAdminUser]
    throttle_classes = [throttling.ScopedRateThrottle]
    throttle_scope = 'listings_action'

    @extend_schema(
        request=None,
        responses={200: inline_serializer(name='ListingApproveResponse', fields={'detail': serializers.CharField()})},
    )
    def post(self, request, pk):
        listing = generics.get_object_or_404(Listing, pk=pk)
        listing.moderation_status = Listing.ModerationStatus.APPROVED
        listing.moderation_note = ''
        listing.save(update_fields=['moderation_status', 'moderation_note', 'updated_at'])
        return response.Response({'detail': 'Listing approved.'}, status=status.HTTP_200_OK)


class ListingRejectView(views.APIView):
    permission_classes = [permissions.IsAdminUser]
    throttle_classes = [throttling.ScopedRateThrottle]
    throttle_scope = 'listings_action'

    @extend_schema(
        request=inline_serializer(
            name='ListingRejectRequest',
            fields={'note': serializers.CharField(required=False)},
        ),
        responses={200: inline_serializer(name='ListingRejectResponse', fields={'detail': serializers.CharField()})},
    )
    def post(self, request, pk):
        listing = generics.get_object_or_404(Listing, pk=pk)
        listing.moderation_status = Listing.ModerationStatus.REJECTED
        listing.is_active = False
        listing.moderation_note = (request.data.get('note') or '').strip()
        listing.save(update_fields=['moderation_status', 'is_active', 'moderation_note', 'updated_at'])
        return response.Response({'detail': 'Listing rejected.'}, status=status.HTTP_200_OK)


class ListingAvailabilityView(views.APIView):
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    throttle_classes = [throttling.ScopedRateThrottle]
    throttle_scope = 'listings_list'

    def get(self, request, pk):
        listing = generics.get_object_or_404(Listing, pk=pk)
        if request.user.is_authenticated:
            queryset = AvailabilityDay.objects.filter(listing=listing)
        else:
            queryset = AvailabilityDay.objects.filter(listing=listing, is_available=True)
        serializer = AvailabilityDaySerializer(queryset, many=True)
        return response.Response({'results': serializer.data}, status=status.HTTP_200_OK)

    def put(self, request, pk):
        listing = generics.get_object_or_404(Listing, pk=pk, host=request.user)
        days = request.data.get('days')
        if not isinstance(days, list):
            return response.Response({'detail': 'days must be a list.'}, status=status.HTTP_400_BAD_REQUEST)

        updated = []
        for item in days:
            serializer = AvailabilityDaySerializer(data=item)
            serializer.is_valid(raise_exception=True)
            payload = serializer.validated_data
            obj, _ = AvailabilityDay.objects.update_or_create(
                listing=listing,
                date=payload['date'],
                defaults={
                    'is_available': payload.get('is_available', True),
                    'price_override': payload.get('price_override'),
                    'min_nights_override': payload.get('min_nights_override'),
                    'note': payload.get('note', ''),
                },
            )
            updated.append(obj)

        return response.Response(
            {'results': AvailabilityDaySerializer(updated, many=True).data},
            status=status.HTTP_200_OK,
        )
