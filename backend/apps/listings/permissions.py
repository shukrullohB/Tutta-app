from rest_framework import permissions


class IsHostUser(permissions.BasePermission):
    message = 'Only host users can perform this action.'

    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.role == 'host')


class IsListingOwner(permissions.BasePermission):
    message = 'You can only modify your own listings.'

    def has_object_permission(self, request, view, obj):
        return bool(request.user and request.user.is_authenticated and obj.host_id == request.user.id)
