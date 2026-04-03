import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app.dart';
import '../../../../app/router/route_names.dart';
import '../../../../l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(RouteNames.home),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(loc.settingsTitle),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: LanguageSelector(),
          ),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: Text(loc.languageTitle),
            subtitle: Text(loc.languageSubtitle),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: Text(loc.notificationsTitle),
            subtitle: Text(loc.notificationsSubtitle),
            onTap: () => context.push(RouteNames.notifications),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(loc.privacyTitle),
            subtitle: Text(loc.privacySubtitle),
            onTap: () => context.go(RouteNames.support),
          ),
        ],
      ),
    );
  }
}
