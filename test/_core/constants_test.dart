import 'package:flutter_test/flutter_test.dart';
import 'package:pxshe_app/_core/constants.dart';

void main() {
  group('Constants', () {
    test('apiBaseUrl delegates to Env', () {
      expect(Constants.apiBaseUrl, isNotEmpty);
    });

    test('tokenBoxName is not empty', () {
      expect(Constants.tokenBoxName, isNotEmpty);
    });

    test('cachedTokenRef is not empty', () {
      expect(Constants.cachedTokenRef, isNotEmpty);
    });

    test('userBoxName is not empty', () {
      expect(Constants.userBoxName, isNotEmpty);
    });

    test('cachedUserRef is not empty', () {
      expect(Constants.cachedUserRef, isNotEmpty);
    });

    test('themeBoxName is not empty', () {
      expect(Constants.themeBoxName, isNotEmpty);
    });

    test('themeModeRef is not empty', () {
      expect(Constants.themeModeRef, isNotEmpty);
    });

    test('mainRouesDiKey is MainRoutes', () {
      expect(Constants.mainRouesDiKey, 'MainRoutes');
    });

    test('navTabsDiKey is NavTabs', () {
      expect(Constants.navTabsDiKey, 'NavTabs');
    });

    test('langAssetPath is not empty', () {
      expect(Constants.langAssetPath, isNotEmpty);
    });

    test('supportedLocales contains zh', () {
      expect(
        Constants.supportedLocales.any((l) => l.languageCode == 'zh'),
        isTrue,
      );
    });

    test('breakpoints is not empty', () {
      expect(Constants.breakpoints, isNotEmpty);
    });
  });
}