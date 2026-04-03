from django.conf import settings
from django.db import models


class Listing(models.Model):
    class Type(models.TextChoices):
        HOME = 'home', 'Home'
        ROOM = 'room', 'Room'
        FREE_STAY = 'free_stay', 'Free Stay'

    class ModerationStatus(models.TextChoices):
        DRAFT = 'draft', 'Draft'
        PENDING = 'pending', 'Pending Review'
        APPROVED = 'approved', 'Approved'
        REJECTED = 'rejected', 'Rejected'

    host = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='listings')
    title = models.CharField(max_length=255)
    description = models.TextField()
    location = models.CharField(max_length=255)
    city = models.CharField(max_length=120, blank=True, default='')
    district = models.CharField(max_length=120, blank=True, default='')
    landmark = models.CharField(max_length=160, blank=True, default='')
    metro = models.CharField(max_length=120, blank=True, default='')
    listing_type = models.CharField(max_length=20, choices=Type.choices)
    price_per_night = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    max_guests = models.PositiveIntegerField(default=1)
    min_days = models.PositiveIntegerField(default=1)
    max_days = models.PositiveIntegerField(default=30)
    show_phone = models.BooleanField(default=False)
    free_stay_profile = models.JSONField(default=dict, blank=True)
    moderation_status = models.CharField(
        max_length=20,
        choices=ModerationStatus.choices,
        default=ModerationStatus.DRAFT,
    )
    moderation_note = models.CharField(max_length=255, blank=True, default='')
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return self.title


class ListingImage(models.Model):
    listing = models.ForeignKey(Listing, on_delete=models.CASCADE, related_name='images')
    image = models.ImageField(upload_to='listings/%Y/%m/%d/')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['created_at']

    def __str__(self):
        return f'Image {self.id} for listing {self.listing_id}'


class AvailabilityDay(models.Model):
    listing = models.ForeignKey(Listing, on_delete=models.CASCADE, related_name='availability_days')
    date = models.DateField()
    is_available = models.BooleanField(default=True)
    price_override = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    min_nights_override = models.PositiveIntegerField(null=True, blank=True)
    note = models.CharField(max_length=255, blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['date']
        unique_together = ('listing', 'date')

    def __str__(self):
        return f'Availability {self.listing_id} {self.date} ({self.is_available})'
