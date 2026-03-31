from django.contrib import admin

from .models import Booking


@admin.register(Booking)
class BookingAdmin(admin.ModelAdmin):
    list_display = ('id', 'listing', 'guest', 'start_date', 'end_date', 'status', 'total_price', 'created_at')
    list_filter = ('status', 'created_at')
    search_fields = ('listing__title', 'guest__email')
