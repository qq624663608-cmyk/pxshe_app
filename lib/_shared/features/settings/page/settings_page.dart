import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../_core/layout/page_layout.dart';
import '../../../blocs/locale_cubit.dart';
import '../../../blocs/theme_mode_cubit.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../shared_routes.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PageLayout(
      title: l10n.settingsPageTitle,
      navTab: SharedNavTab.settings,
      page: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                const SizedBox(height: 40),
                const _SettingsCard(child: ThemeModeSettingButton()),
                const SizedBox(height: 20),
                const _SettingsCard(child: LanguageSettingTile()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ThemeModeSettingButton extends StatelessWidget {
  const ThemeModeSettingButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        final cubit = BlocProvider.of<ThemeModeCubit>(context);
        isDark ? cubit.lightMode() : cubit.darkMode();
      },
      child: ListTile(
        leading: Icon(
          isDark ? Icons.light_mode : Icons.dark_mode,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          isDark ? l10n.settingsPageLightMode : l10n.settingsPageDarkMode,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        trailing: Switch(
          value: isDark,
          onChanged: (val) {
            final cubit = context.read<ThemeModeCubit>();
            val ? cubit.darkMode() : cubit.lightMode();
          },
        ),
      ),
    );
  }
}

class LanguageSettingTile extends StatelessWidget {
  const LanguageSettingTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentLocale = Localizations.localeOf(context);

    return ListTile(
      leading: const Icon(Icons.language, color: Colors.teal),
      title: Text(
        l10n.settingsPageLanguage,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      trailing: BlocBuilder<LocaleCubit, Locale>(
        builder: (context, locale) {
          return DropdownButton<Locale>(
            value: locale,
            underline: const SizedBox(),
            onChanged: (Locale? newLocale) {
              if (newLocale != null) {
                context.read<LocaleCubit>().setLocale(newLocale);
              }
            },
            items: const [
              DropdownMenuItem(value: Locale('en'), child: Text('English 🇺🇸')),
              DropdownMenuItem(value: Locale('ar'), child: Text('العربية 🇸🇦')),
              DropdownMenuItem(value: Locale('zh'), child: Text('中文 🇨🇳')),
              DropdownMenuItem(value: Locale('es'), child: Text('Español 🇪🇸')),
            ],
          );
        },
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;

  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
        child: child,
      ),
    );
  }
}
