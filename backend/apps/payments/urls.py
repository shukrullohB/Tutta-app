from django.urls import path

from .views import PaymentIntentDetailView, PaymentIntentListCreateView, PaymentWebhookView

urlpatterns = [
    path('intents', PaymentIntentListCreateView.as_view(), name='payments-intents'),
    path('intents/<int:pk>', PaymentIntentDetailView.as_view(), name='payments-intent-detail'),
    path('webhooks/<str:provider>', PaymentWebhookView.as_view(), name='payments-webhook'),
]
