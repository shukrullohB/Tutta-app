from django.urls import path

from .views import (
    ListingAvailabilityView,
    ListingApproveView,
    ListingDetailView,
    ListingListCreateView,
    ListingManageView,
    ListingPublishView,
    ListingRejectView,
    ListingUnpublishView,
)

urlpatterns = [
    path('', ListingListCreateView.as_view(), name='listings-list-create'),
    path('<int:pk>', ListingDetailView.as_view(), name='listings-detail'),
    path('<int:pk>/manage', ListingManageView.as_view(), name='listings-manage'),
    path('<int:pk>/publish', ListingPublishView.as_view(), name='listings-publish'),
    path('<int:pk>/unpublish', ListingUnpublishView.as_view(), name='listings-unpublish'),
    path('<int:pk>/availability', ListingAvailabilityView.as_view(), name='listings-availability'),
    path('<int:pk>/approve', ListingApproveView.as_view(), name='listings-approve'),
    path('<int:pk>/reject', ListingRejectView.as_view(), name='listings-reject'),
]
