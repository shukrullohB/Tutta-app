from django.urls import path

from .views import MessageListCreateView, ThreadListCreateView

urlpatterns = [
    path('threads', ThreadListCreateView.as_view(), name='chat-threads'),
    path('threads/<int:thread_id>/messages', MessageListCreateView.as_view(), name='chat-thread-messages'),
]
