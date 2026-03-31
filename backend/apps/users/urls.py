from django.urls import path

from .views import GoogleLoginView, LoginView, LogoutView, RefreshView, RegisterView

urlpatterns = [
    path('register', RegisterView.as_view(), name='auth-register'),
    path('login', LoginView.as_view(), name='auth-login'),
    path('google', GoogleLoginView.as_view(), name='auth-google'),
    path('refresh', RefreshView.as_view(), name='auth-refresh'),
    path('logout', LogoutView.as_view(), name='auth-logout'),
]
