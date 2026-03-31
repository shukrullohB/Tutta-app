import uuid

from django.db import models


class Payment(models.Model):
    class Provider(models.TextChoices):
        CLICK = 'click', 'Click'
        PAYME = 'payme', 'Payme'

    class Status(models.TextChoices):
        PENDING = 'pending', 'Pending'
        SUCCEEDED = 'succeeded', 'Succeeded'
        FAILED = 'failed', 'Failed'
        CANCELLED = 'cancelled', 'Cancelled'

    booking = models.ForeignKey('bookings.Booking', on_delete=models.CASCADE, related_name='payments', null=True, blank=True)
    provider = models.CharField(max_length=20, choices=Provider.choices, default=Provider.CLICK)
    amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    currency = models.CharField(max_length=10, default='UZS')
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)
    provider_payment_id = models.CharField(max_length=64, unique=True, default=uuid.uuid4, editable=False)
    checkout_url = models.URLField(blank=True)
    raw_payload = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'Payment {self.id} ({self.provider}) for booking {self.booking_id}'
