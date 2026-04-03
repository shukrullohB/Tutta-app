from django.urls import path

from .views import (
    MessageDetailView,
    MessageListCreateView,
    ThreadDetailView,
    ThreadListCreateView,
)

urlpatterns = [
    path('threads', ThreadListCreateView.as_view(), name='chat-threads'),
    path('threads/<int:pk>', ThreadDetailView.as_view(), name='chat-thread-detail'),
    path('threads/<int:thread_id>/messages', MessageListCreateView.as_view(), name='chat-thread-messages'),
    path(
        'threads/<int:thread_id>/messages/<int:pk>',
        MessageDetailView.as_view(),
        name='chat-thread-message-detail',
    ),
]
