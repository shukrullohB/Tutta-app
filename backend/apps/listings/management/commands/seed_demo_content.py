from datetime import date, datetime, timedelta
from decimal import Decimal

from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils import timezone

from apps.bookings.models import Booking
from apps.chat.models import Message, Thread
from apps.listings.models import Listing
from apps.reviews.models import Review
from apps.users.models import User


class Command(BaseCommand):
    help = 'Seed local demo listings, chats, bookings, and reviews for Chrome MVP.'

    def add_arguments(self, parser):
        parser.add_argument(
            '--guest-email',
            dest='guest_email',
            help='Optional guest email to prioritize for seeded chat threads.',
        )

    @transaction.atomic
    def handle(self, *args, **options):
        prioritized_email = (options.get('guest_email') or '').strip().lower()

        hosts = self._ensure_hosts()
        extra_guests = self._ensure_extra_guests()
        listings = self._ensure_listings(hosts)

        app_guests = list(User.objects.filter(role=User.Role.GUEST).order_by('-created_at'))
        target_guests = self._select_target_guests(app_guests, prioritized_email)

        self._ensure_threads(target_guests, listings)
        self._ensure_guest_bookings(target_guests, listings)
        self._ensure_review_history(extra_guests, listings)

        self.stdout.write(
            self.style.SUCCESS(
                f'Seeded {len(listings)} listings, {len(target_guests)} active guest chat profiles, '
                f'{len(extra_guests)} extra review guests.'
            )
        )

    def _ensure_hosts(self):
        specs = [
            {
                'email': 'aziza.host@tutta.uz',
                'first_name': 'Aziza',
                'last_name': 'Karimova',
                'phone_number': '+998901110011',
            },
            {
                'email': 'dilshod.host@tutta.uz',
                'first_name': 'Dilshod',
                'last_name': 'Rakhimov',
                'phone_number': '+998901110022',
            },
            {
                'email': 'madina.host@tutta.uz',
                'first_name': 'Madina',
                'last_name': 'Yuldasheva',
                'phone_number': '+998901110033',
            },
            {
                'email': 'kamola.host@tutta.uz',
                'first_name': 'Kamola',
                'last_name': 'Ismoilova',
                'phone_number': '+998901110044',
            },
        ]

        hosts = []
        for spec in specs:
            user, created = User.objects.get_or_create(
                email=spec['email'],
                defaults={
                    **spec,
                    'role': User.Role.HOST,
                },
            )
            updated = False
            for field, value in spec.items():
                if getattr(user, field) != value:
                    setattr(user, field, value)
                    updated = True
            if user.role != User.Role.HOST:
                user.role = User.Role.HOST
                updated = True
            if created or updated:
                user.set_password('DemoPass123!')
                user.save()
            hosts.append(user)
        return hosts

    def _ensure_extra_guests(self):
        specs = [
            {
                'email': 'nilufar.demo@tutta.uz',
                'first_name': 'Nilufar',
                'last_name': 'Akbarova',
                'phone_number': '+998909990011',
            },
            {
                'email': 'sardor.demo@tutta.uz',
                'first_name': 'Sardor',
                'last_name': 'Qodirov',
                'phone_number': '+998909990022',
            },
        ]

        guests = []
        for spec in specs:
            user, created = User.objects.get_or_create(
                email=spec['email'],
                defaults={
                    **spec,
                    'role': User.Role.GUEST,
                },
            )
            updated = False
            for field, value in spec.items():
                if getattr(user, field) != value:
                    setattr(user, field, value)
                    updated = True
            if user.role != User.Role.GUEST:
                user.role = User.Role.GUEST
                updated = True
            if created or updated:
                user.set_password('DemoPass123!')
                user.save()
            guests.append(user)
        return guests

    def _ensure_listings(self, hosts):
        specs = [
            {
                'host': hosts[0],
                'title': 'Cozy apartment near Tashkent Metro',
                'description': (
                    'Bright designer apartment for short stays in Yunusabad. '
                    'Fast Wi-Fi, quiet bedroom, kitchen, and easy metro access.'
                ),
                'location': 'Tashkent, Yunusabad',
                'city': 'Tashkent',
                'district': 'Yunusabad',
                'landmark': 'Minor Mosque',
                'metro': 'Shahriston',
                'listing_type': Listing.Type.HOME,
                'price_per_night': Decimal('420000.00'),
                'max_guests': 3,
                'min_days': 1,
                'max_days': 30,
                'show_phone': True,
            },
            {
                'host': hosts[1],
                'title': 'Modern loft in City Center',
                'description': (
                    'Minimal loft with self check-in, work desk, and strong air conditioning. '
                    'Perfect for business or weekend city stays.'
                ),
                'location': 'Tashkent, Mirobod',
                'city': 'Tashkent',
                'district': 'Mirobod',
                'landmark': 'Tashkent City Mall',
                'metro': 'Kosmonavtlar',
                'listing_type': Listing.Type.HOME,
                'price_per_night': Decimal('510000.00'),
                'max_guests': 2,
                'min_days': 1,
                'max_days': 14,
                'show_phone': True,
            },
            {
                'host': hosts[2],
                'title': 'Family apartment near Magic City',
                'description': (
                    'Spacious family-friendly apartment with full kitchen, washer, and living room. '
                    'Great for guests who want comfort close to city attractions.'
                ),
                'location': 'Tashkent, Chilonzor',
                'city': 'Tashkent',
                'district': 'Chilonzor',
                'landmark': 'Magic City',
                'metro': 'Novza',
                'listing_type': Listing.Type.HOME,
                'price_per_night': Decimal('610000.00'),
                'max_guests': 5,
                'min_days': 2,
                'max_days': 21,
                'show_phone': True,
            },
            {
                'host': hosts[3],
                'title': 'Quiet room with balcony in central Tashkent',
                'description': (
                    'Private room in a calm shared apartment with balcony, coffee corner, '
                    'and easy access to cafés and metro.'
                ),
                'location': 'Tashkent, Yakkasaroy',
                'city': 'Tashkent',
                'district': 'Yakkasaroy',
                'landmark': 'Next Mall',
                'metro': 'Oybek',
                'listing_type': Listing.Type.ROOM,
                'price_per_night': Decimal('290000.00'),
                'max_guests': 2,
                'min_days': 1,
                'max_days': 10,
                'show_phone': True,
            },
        ]

        listings = []
        for spec in specs:
            listing, _ = Listing.objects.update_or_create(
                host=spec['host'],
                title=spec['title'],
                defaults={
                    **spec,
                    'free_stay_profile': {},
                    'is_active': True,
                    'moderation_status': Listing.ModerationStatus.APPROVED,
                    'moderation_note': '',
                },
            )
            listings.append(listing)
        return listings

    def _select_target_guests(self, guests, prioritized_email):
        if not guests:
            return []

        prioritized = []
        if prioritized_email:
            prioritized = [guest for guest in guests if guest.email.lower() == prioritized_email]

        latest_real = [guest for guest in guests if guest.email.endswith('@gmail.com')]
        ordered = []
        seen_ids = set()
        for guest in prioritized + latest_real + guests:
            if guest.id in seen_ids:
                continue
            seen_ids.add(guest.id)
            ordered.append(guest)
        return ordered[:4]

    def _ensure_threads(self, guests, listings):
        thread_specs = [
            (
                listings[0],
                'Assalomu alaykum, ertaroq check-in qilish mumkinmi?',
                'Ha, 12:00 dan keyin tayyor bo‘ladi.',
            ),
            (
                listings[1],
                'Hi, is late self check-in available after 23:00?',
                'Yes, I will send you the self check-in details in chat.',
            ),
            (
                listings[2],
                'Bolalar bilan qolish qulaymi?',
                'Yes, the apartment is family-friendly and fully ready.',
            ),
        ]

        now = timezone.now()
        for guest in guests:
            for index, (listing, guest_text, host_text) in enumerate(thread_specs):
                thread, _ = Thread.objects.get_or_create(
                    listing=listing,
                    guest=guest,
                    host=listing.host,
                )

                if not thread.messages.exists():
                    first = Message.objects.create(
                        thread=thread,
                        sender=guest,
                        content=guest_text,
                        is_read=True,
                    )
                    second = Message.objects.create(
                        thread=thread,
                        sender=listing.host,
                        content=host_text,
                        is_read=(index != 1),
                    )
                    thread.last_message_at = second.created_at
                    thread.save(update_fields=['last_message_at'])
                elif thread.last_message_at is None:
                    last = thread.messages.order_by('-created_at').first()
                    thread.last_message_at = last.created_at if last else now
                    thread.save(update_fields=['last_message_at'])

    def _ensure_guest_bookings(self, guests, listings):
        today = date.today()
        for guest in guests:
            self._upsert_booking(
                listing=listings[0],
                guest=guest,
                start_date=today - timedelta(days=8),
                end_date=today - timedelta(days=4),
                total_price=Decimal('1680000.00'),
                status=Booking.Status.COMPLETED,
            )
            self._upsert_booking(
                listing=listings[1],
                guest=guest,
                start_date=today + timedelta(days=5),
                end_date=today + timedelta(days=8),
                total_price=Decimal('1530000.00'),
                status=Booking.Status.CONFIRMED,
            )

    def _ensure_review_history(self, extra_guests, listings):
        today = date.today()
        review_specs = [
            (
                extra_guests[0],
                listings[0],
                today - timedelta(days=20),
                today - timedelta(days=17),
                Decimal('1260000.00'),
                5,
                'Very clean apartment, smooth check-in, and metro access was excellent.',
            ),
            (
                extra_guests[1],
                listings[1],
                today - timedelta(days=15),
                today - timedelta(days=12),
                Decimal('1530000.00'),
                4,
                'Stylish loft, strong Wi-Fi, and perfect for a short city stay.',
            ),
            (
                extra_guests[0],
                listings[2],
                today - timedelta(days=11),
                today - timedelta(days=7),
                Decimal('2440000.00'),
                5,
                'Great for families, very spacious, and the host was kind and responsive.',
            ),
            (
                extra_guests[1],
                listings[3],
                today - timedelta(days=9),
                today - timedelta(days=6),
                Decimal('870000.00'),
                4,
                'Quiet room, cozy balcony, and easy access to the center.',
            ),
        ]

        for guest, listing, start_date, end_date, total_price, rating, comment in review_specs:
            booking = self._upsert_booking(
                listing=listing,
                guest=guest,
                start_date=start_date,
                end_date=end_date,
                total_price=total_price,
                status=Booking.Status.COMPLETED,
            )
            Review.objects.get_or_create(
                booking=booking,
                defaults={
                    'listing': listing,
                    'guest': guest,
                    'rating': rating,
                    'comment': comment,
                },
            )

    def _upsert_booking(self, listing, guest, start_date, end_date, total_price, status):
        booking, _ = Booking.objects.update_or_create(
            listing=listing,
            guest=guest,
            start_date=start_date,
            end_date=end_date,
            defaults={
                'total_price': total_price,
                'status': status,
            },
        )
        return booking
