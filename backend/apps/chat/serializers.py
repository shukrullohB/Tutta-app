from rest_framework import serializers
from drf_spectacular.types import OpenApiTypes
from drf_spectacular.utils import extend_schema_field

from .models import Message, Thread


class MessageSerializer(serializers.ModelSerializer):
    sender_id = serializers.IntegerField(source='sender.id', read_only=True)

    class Meta:
        model = Message
        fields = ('id', 'thread', 'sender_id', 'content', 'is_read', 'created_at')
        read_only_fields = ('id', 'thread', 'sender_id', 'is_read', 'created_at')


class ThreadSerializer(serializers.ModelSerializer):
    guest_id = serializers.IntegerField(source='guest.id', read_only=True)
    host_id = serializers.IntegerField(source='host.id', read_only=True)
    last_message = serializers.SerializerMethodField()
    unread_count = serializers.SerializerMethodField()

    class Meta:
        model = Thread
        fields = (
            'id',
            'listing',
            'guest_id',
            'host_id',
            'last_message_at',
            'last_message',
            'unread_count',
            'created_at',
        )
        read_only_fields = ('id', 'guest_id', 'host_id', 'last_message_at', 'last_message', 'unread_count', 'created_at')

    @extend_schema_field(OpenApiTypes.OBJECT)
    def get_last_message(self, obj):
        message = obj.messages.order_by('-created_at').first()
        if not message:
            return None
        return {'id': message.id, 'content': message.content, 'sender_id': message.sender_id, 'created_at': message.created_at}

    @extend_schema_field(OpenApiTypes.INT)
    def get_unread_count(self, obj):
        user = self.context['request'].user
        return obj.messages.filter(is_read=False).exclude(sender=user).count()


class ThreadCreateSerializer(serializers.ModelSerializer):
    guest_id = serializers.IntegerField(write_only=True)
    host_id = serializers.IntegerField(write_only=True)

    class Meta:
        model = Thread
        fields = ('id', 'listing', 'guest_id', 'host_id', 'created_at')
        read_only_fields = ('id', 'created_at')

    def validate(self, attrs):
        request = self.context['request']
        guest_id = attrs['guest_id']
        host_id = attrs['host_id']
        listing = attrs.get('listing')

        if guest_id == host_id:
            raise serializers.ValidationError('guest_id and host_id must be different users.')

        if request.user.id not in (guest_id, host_id):
            raise serializers.ValidationError('You can only create thread where you are a participant.')

        if listing and listing.host_id != host_id:
            raise serializers.ValidationError('host_id must match listing host.')

        return attrs

    def create(self, validated_data):
        guest_id = validated_data.pop('guest_id')
        host_id = validated_data.pop('host_id')
        listing = validated_data.get('listing')

        thread, _ = Thread.objects.get_or_create(
            listing=listing,
            guest_id=guest_id,
            host_id=host_id,
            defaults=validated_data,
        )
        return thread

    def to_representation(self, instance):
        return ThreadSerializer(instance, context=self.context).data


class MessageCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Message
        fields = ('id', 'content', 'created_at')
        read_only_fields = ('id', 'created_at')

    def validate_content(self, value):
        if not value.strip():
            raise serializers.ValidationError('Message content cannot be empty.')
        return value.strip()
