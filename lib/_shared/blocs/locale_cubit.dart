import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

import '../../_core/constants.dart';

/// Holds the currently active [Locale]. Persists across app restarts via
/// the same Hive box as [ThemeModeCubit] (THEME_BOX). Used by `MaterialApp.router`
/// `locale:` to drive all `AppLocalizations.of(context)` lookups.
class LocaleCubit extends Cubit<Locale> {
  LocaleCubit({required HiveInterface hive})
      : _hive = hive,
        super(const Locale('en'));

  static const String _ref = 'Locale';
  final HiveInterface _hive;

  Future<LazyBox<dynamic>> _box() =>
      _hive.openLazyBox(Constants.themeBoxName);

  /// Called once at app boot to restore the persisted locale (if any).
  /// Falls back to English on first launch or on any read error.
  Future<void> load() async {
    try {
      final box = await _box();
      final code = await box.get(_ref) as String?;
      if (code != null && code.isNotEmpty) {
        emit(Locale(code));
      }
    } catch (_) {
      // Ignore — keep default English locale.
    }
  }

  /// Switch to a new locale and persist the choice.
  Future<void> setLocale(Locale locale) async {
    emit(locale);
    try {
      final box = await _box();
      await box.put(_ref, locale.languageCode);
    } catch (_) {
      // Persistence is best-effort; in-memory state is already updated.
    }
  }
}
