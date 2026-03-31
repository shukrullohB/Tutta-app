from django.urls import path

from .views import BookingCancelView, BookingConfirmView, BookingListCreateView

urlpatterns = [
    path('', BookingListCreateView.as_view(), name='bookings-list-create'),
    path('<int:pk>/confirm', BookingConfirmView.as_view(), name='bookings-confirm'),
    path('<int:pk>/cancel', BookingCancelView.as_view(), name='bookings-cancel'),
]
