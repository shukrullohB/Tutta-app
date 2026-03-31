from django.contrib import admin

from .models import Listing, ListingImage


class ListingImageInline(admin.TabularInline):
    model = ListingImage
    extra = 1


@admin.register(Listing)
class ListingAdmin(admin.ModelAdmin):
    list_display = ('id', 'title', 'host', 'listing_type', 'price_per_night', 'is_active', 'created_at')
    list_filter = ('listing_type', 'is_active', 'created_at')
    search_fields = ('title', 'location', 'host__email')
    inlines = [ListingImageInline]


@admin.register(ListingImage)
class ListingImageAdmin(admin.ModelAdmin):
    list_display = ('id', 'listing', 'created_at')
