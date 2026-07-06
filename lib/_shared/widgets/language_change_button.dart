import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/locale_cubit.dart';
import '../../l10n/gen/app_localizations.dart';

class LanguageChangeButton extends StatelessWidget {
  const LanguageChangeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: AppLocalizations.of(context).layoutPageChangeLanguage,
      icon: const Icon(Icons.language),
      onPressed: () async {
        final RenderBox button = context.findRenderObject() as RenderBox;
        final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
        final Offset offset = button.localToGlobal(Offset.zero, ancestor: overlay);

        final Locale? selected = await showMenu<Locale>(
          context: context,
          position: RelativeRect.fromLTRB(
            offset.dx,
            offset.dy + button.size.height,
            overlay.size.width - offset.dx - 15,
            0,
          ),
          items: const [
            PopupMenuItem(
              value: Locale('en'),
              child: Text('English 🇺🇸'),
            ),
            PopupMenuItem(
              value: Locale('ar'),
              child: Text('العربية 🇸🇦'),
            ),
            PopupMenuItem(
              value: Locale('zh'),
              child: Text('中文 🇨🇳'),
            ),
            PopupMenuItem(
              value: Locale('es'),
              child: Text('Español 🇪🇸'),
            ),
          ],
        );

        if (selected != null && context.mounted) {
          context.read<LocaleCubit>().setLocale(selected);
        }
      },
    );
  }
}