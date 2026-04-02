from django.urls import path

from .views import MeView, PublicProfileView

urlpatterns = [
    path('me', MeView.as_view(), name='users-me'),
    path('<int:pk>/public-profile', PublicProfileView.as_view(), name='users-public-profile'),
]
