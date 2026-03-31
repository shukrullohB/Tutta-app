from django.db.models import Q
from django.utils import timezone
from rest_framework import generics, permissions, throttling

from .models import Message, Thread
from .serializers import MessageCreateSerializer, MessageSerializer, ThreadCreateSerializer, ThreadSerializer


class ThreadListCreateView(generics.ListCreateAPIView):
    permission_classes = [permissions.IsAuthenticated]
    throttle_classes = [throttling.ScopedRateThrottle]
    throttle_scope = 'chat_threads'

    def get_queryset(self):
        if not self.request.user.is_authenticated:
            return Thread.objects.none()
        return (
            Thread.objects.select_related('guest', 'host', 'listing')
            .prefetch_related('messages')
            .filter(Q(guest=self.request.user) | Q(host=self.request.user))
        )

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return ThreadCreateSerializer
        return ThreadSerializer


class MessageListCreateView(generics.ListCreateAPIView):
    permission_classes = [permissions.IsAuthenticated]
    throttle_classes = [throttling.ScopedRateThrottle]
    throttle_scope = 'chat_messages'

    def get_queryset(self):
        if not self.request.user.is_authenticated:
            return Message.objects.none()
        return (
            Message.objects.select_related('sender', 'thread')
            .filter(Q(thread__guest=self.request.user) | Q(thread__host=self.request.user))
            .filter(thread_id=self.kwargs['thread_id'])
        )

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return MessageCreateSerializer
        return MessageSerializer

    def perform_create(self, serializer):
        thread = generics.get_object_or_404(
            Thread.objects.filter(Q(guest=self.request.user) | Q(host=self.request.user)),
            pk=self.kwargs['thread_id'],
        )
        message = serializer.save(thread=thread, sender=self.request.user)
        thread.last_message_at = message.created_at or timezone.now()
        thread.save(update_fields=['last_message_at'])

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        queryset.exclude(sender=request.user).update(is_read=True)
        return super().list(request, *args, **kwargs)
