import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/l10n/language.dart';
import '../core/storage/secure_storage_service.dart';
import '../l10n/app_localizations.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

final localeProvider = StateNotifierProvider<LocaleController, Locale?>((ref) {
  return LocaleController(ref);
});

class LocaleController extends StateNotifier<Locale?> {
  LocaleController(this._ref) : super(const Locale('en')) {
    _restore();
  }

  final Ref _ref;
  static const _storageKey = 'app_locale_code';

  Future<void> _restore() async {
    final code = await _ref
        .read(secureStorageServiceProvider)
        .readString(_storageKey);
    if (code == null || code.isEmpty) {
      state = const Locale('en');
      return;
    }
    state = Locale(code);
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    if (locale == null) {
      await _ref.read(secureStorageServiceProvider).delete(_storageKey);
      return;
    }
    await _ref
        .read(secureStorageServiceProvider)
        .writeString(key: _storageKey, value: locale.languageCode);
  }
}

class TuttaApp extends ConsumerWidget {
  const TuttaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Tutta',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
    );
  }
}

class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final rawLocale = locale ?? Localizations.localeOf(context);
    final effectiveLocale = supportedLanguages
        .map((lang) => Locale(lang.code))
        .firstWhere(
          (item) => item.languageCode == rawLocale.languageCode,
          orElse: () => const Locale('en'),
        );

    return DropdownButton<Locale>(
      value: effectiveLocale,
      items: supportedLanguages.map((lang) {
        final loc = Locale(lang.code);
        return DropdownMenuItem<Locale>(
          value: loc,
          child: Text('${lang.flag} ${lang.name}'),
        );
      }).toList(),
      underline: const SizedBox.shrink(),
      onChanged: (newLocale) {
        ref.read(localeProvider.notifier).setLocale(newLocale);
      },
    );
  }
}
