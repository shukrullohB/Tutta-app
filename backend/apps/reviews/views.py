from rest_framework import generics, permissions, throttling

from .models import Review
from .serializers import ReviewSerializer


class ReviewListCreateView(generics.ListCreateAPIView):
    queryset = Review.objects.select_related('listing', 'guest', 'booking')
    serializer_class = ReviewSerializer
    filterset_fields = ('listing', 'rating')
    ordering_fields = ('created_at', 'rating')
    throttle_classes = [throttling.ScopedRateThrottle]

    def get_permissions(self):
        if self.request.method == 'POST':
            return [permissions.IsAuthenticated()]
        return [permissions.AllowAny()]

    def get_throttles(self):
        self.throttle_scope = 'reviews_write' if self.request.method == 'POST' else 'reviews_list'
        return super().get_throttles()

    def get_queryset(self):
        queryset = super().get_queryset()
        listing_id = self.request.query_params.get('listing_id')
        if listing_id:
            queryset = queryset.filter(listing_id=listing_id)
        return queryset
