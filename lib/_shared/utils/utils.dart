import 'package:flutter/foundation.dart';

class GlobalUtils {
  static void setThemeModeForWeb(String mode) {
    if (kIsWeb) {
      return;
    }
  }
}