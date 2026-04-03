String resolveRussianCopy(String en, String fallback) {
  final direct = _ruOverrides[en];
  if (direct != null) {
    return direct;
  }

  final savedListings = RegExp(r'^(\d+)\s+saved listing\(s\)$').firstMatch(en);
  if (savedListings != null) {
    return 'Сохранено объявлений: ${savedListings.group(1)}';
  }

  if (en.startsWith('Host #')) {
    return en.replaceFirst('Host #', 'Хозяин #');
  }
  if (en.startsWith('Guest #')) {
    return en.replaceFirst('Guest #', 'Гость #');
  }

  return fallback.isNotEmpty ? fallback : en;
}

const Map<String, String> _ruOverrides = <String, String>{
  'Choose mode': 'Выберите режим',
  'Please choose renter or host mode to continue.':
      'Пожалуйста, выберите режим гостя или хозяина, чтобы продолжить.',
  'Open role selector': 'Открыть выбор роли',
  'Tutta Host': 'Tutta Хозяин',
  'Tutta Renter': 'Tutta Арендатор',
  'Choose role': 'Выбрать роль',
  'Switch role': 'Сменить роль',
  'Sign out': 'Выйти',
  'Dashboard': 'Панель',
  'Listings': 'Объявления',
  'Bookings': 'Брони',
  'Chats': 'Чаты',
  'Profile': 'Профиль',
  'Explore': 'Поиск',
  'Favorites': 'Избранное',
  'Find your next stay in Uzbekistan': 'Найдите следующее жильё в Узбекистане',
  'Short stays only, direct host contact, and fast booking requests.':
      'Только краткосрочная аренда, прямой контакт с хозяином и быстрые заявки на бронь.',
  'Open search': 'Открыть поиск',
  'Open map': 'Открыть карту',
  'Recommended stays': 'Рекомендуемые варианты',
  'Clean stable preview from the real backend.':
      'Стабильная подборка из реального backend.',
  'Stable list from the active backend.':
      'Стабильный список из активного backend.',
  'No listings are available yet.': 'Пока нет доступных объявлений.',
  'Saved stays': 'Сохранённые варианты',
  'Your favorites open directly into the listing details screen.':
      'Избранные объявления открываются сразу на экран жилья.',
  'No favorites yet': 'Пока нет избранного',
  'Tap the heart on any apartment to save it here.':
      'Нажмите на сердце в любом объявлении, чтобы сохранить его здесь.',
  'Browse listings': 'Смотреть объявления',
  'Saved items are no longer available.':
      'Сохранённые объявления больше недоступны.',
  'Guest account': 'Аккаунт гостя',
  'No email': 'Нет email',
  'Phone not added': 'Телефон не добавлен',
  'Saved': 'Сохранено',
  'Guest': 'Гость',
  'Host': 'Хозяин',
  'Mode': 'Режим',
  'Edit profile': 'Редактировать профиль',
  'Update your name and phone number.': 'Обновите имя и номер телефона.',
  'Settings': 'Настройки',
  'Language, privacy, and app preferences.':
      'Язык, приватность и настройки приложения.',
  'Premium': 'Премиум',
  'Manage Free Stay access and premium benefits.':
      'Управляйте доступом к Free Stay и премиум-возможностями.',
  'Notifications': 'Уведомления',
  'Booking updates and important activity.':
      'Обновления по броням и важная активность.',
  'Support': 'Поддержка',
  'Help center and contact options.': 'Центр помощи и способы связи.',
  'Switch between renter and host mode.':
      'Переключайтесь между режимом гостя и хозяина.',
  'Sign out of account': 'Выйти из аккаунта',
  'Leave this account on this device.':
      'Выйти из этого аккаунта на этом устройстве.',
  'Host dashboard': 'Панель хозяина',
  'Host requests': 'Заявки хозяину',
  'Review and respond to incoming requests.':
      'Просматривайте входящие заявки и отвечайте на них.',
  'Host tools': 'Инструменты хозяина',
  'New listing': 'Новое объявление',
  'No bookings yet': 'Бронирований пока нет',
  'Your upcoming trips and requests will appear here.':
      'Здесь появятся ваши будущие поездки и заявки.',
  'Incoming guest requests and approved stays will appear here.':
      'Здесь появятся входящие заявки гостей и подтверждённые проживания.',
  'Pending': 'Ожидает',
  'Confirmed': 'Подтверждено',
  'Cancelled': 'Отменено',
  'Completed': 'Завершено',
  'Guests': 'Гости',
  'Could not load chats.': 'Не удалось загрузить чаты.',
  'Open chat': 'Открыть чат',
  'Could not load messages.': 'Не удалось загрузить сообщения.',
  'Type a message': 'Введите сообщение',
  'Send': 'Отправить',
  'No messages yet': 'Пока нет сообщений',
  'Send the first message below.': 'Отправьте первое сообщение ниже.',
  'No conversations yet': 'Пока нет чатов',
  'Open any apartment and message the host directly.':
      'Откройте любое объявление и напишите хозяину напрямую.',
  'Browse apartments': 'Смотреть жильё',
  'Chat': 'Чат',
  'Could not open this conversation.': 'Не удалось открыть этот диалог.',
  'Stay': 'Жильё',
  'Apartment': 'Квартира',
  'Apartment not found.': 'Жильё не найдено.',
  'No description yet.': 'Описание пока не добавлено.',
  'Free stay': 'Бесплатно',
  'Price on request': 'Цена по запросу',
  'Min days': 'Мин. дней',
  'Max days': 'Макс. дней',
  'Amenities': 'Удобства',
  'Amenities are not available in this listing yet.':
      'Удобства для этого жилья пока не указаны.',
  'Host contact': 'Контакты хозяина',
  'Message': 'Написать',
  'Contact': 'Контакт',
  'Phone': 'Телефон',
  'Please message the host in chat first.':
      'Сначала свяжитесь с хозяином в чате.',
  'Location': 'Локация',
  'Address': 'Адрес',
  'Landmark': 'Ориентир',
  'Metro': 'Метро',
  'Open in Google Maps': 'Открыть в Google Maps',
  'Reviews': 'Отзывы',
  'No guest reviews yet': 'Отзывов гостей пока нет',
  'reviews': 'отзывов',
  'Newest': 'Новые',
  'Popular': 'Популярные',
  'See all reviews': 'Все отзывы',
  'You can leave a review after a completed stay.':
      'Оставить отзыв можно после завершённого проживания.',
  'Write review': 'Написать отзыв',
  'This apartment does not have public reviews yet.':
      'У этого жилья пока нет публичных отзывов.',
  'Delete review?': 'Удалить отзыв?',
  'This action cannot be undone.': 'Это действие нельзя отменить.',
  'Cancel': 'Отмена',
  'Delete': 'Удалить',
  'Review deleted': 'Отзыв удалён',
  'All reviews': 'Все отзывы',
  'You': 'Вы',
  'No written comment.': 'Текст отзыва не добавлен.',
  'Try again': 'Повторить',
  'Room': 'Комната',
  'Home': 'Дом',
  'Air conditioner': 'Кондиционер',
  'Kitchen': 'Кухня',
  'Washing machine': 'Стиральная машина',
  'Parking': 'Парковка',
  'Private bathroom': 'Отдельная ванная',
  'Children allowed': 'Можно с детьми',
  'Pets allowed': 'Можно с животными',
  'Women only': 'Только для женщин',
  'Men only': 'Только для мужчин',
  'Host lives together': 'Хозяин живёт вместе',
  'Instant confirm': 'Мгновенное подтверждение',
  'Renter mode': 'Режим гостя',
  'Host mode': 'Режим хозяина',
  'Current mode': 'Текущий режим',
  'Signed in': 'Вход выполнен',
  'Profile updated': 'Профиль обновлён',
  'First name': 'Имя',
  'Last name': 'Фамилия',
  'Save': 'Сохранить',
  'Create listing': 'Создать объявление',
  'Create a new listing': 'Создать новое объявление',
  'Search, save, chat, and request bookings.':
      'Ищите, сохраняйте, общайтесь и отправляйте заявки на бронь.',
  'Manage listings, chats, availability, and guest requests.':
      'Управляйте объявлениями, чатами, доступностью и заявками гостей.',
  'This screen is intentionally simple while Chrome MVP is being stabilized.':
      'Этот экран пока упрощен, пока мы стабилизируем Chrome MVP.',
  'Booking requests': 'Заявки на бронь',
  'Track your requests and upcoming stays.':
      'Следите за заявками и предстоящими проживаниями.',
  'Create listings, respond to requests, and keep communication in one place.':
      'Создавайте объявления, отвечайте на заявки и держите переписку в одном месте.',
  'Open the Chats tab to reply to guests.':
      'Откройте вкладку «Чаты», чтобы отвечать гостям.',
  'All of your stays appear here, including drafts that are still invisible to guests.':
      'Здесь отображаются все ваши объявления, включая черновики, которые пока не видны гостям.',
  'Your listings': 'Ваши объявления',
  'Open, edit, and track the visibility of each stay.':
      'Открывайте, редактируйте и отслеживайте статус каждого объявления.',
  'Reload': 'Обновить',
  'You have not created any stays yet.':
      'Вы пока не создали ни одного объявления.',
  'Start the multi-step listing flow.':
      'Запустите пошаговый сценарий создания объявления.',
  'Open booking requests': 'Открыть заявки на бронь',
  'No listing title': 'Без названия',
};
