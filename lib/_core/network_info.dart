import 'dart:io';

import 'package:flutter/foundation.dart';
import "package:universal_html/html.dart" as html;

abstract class NetworkInfo {
  Future<bool> isConnected();
}

/// Default implementation. [host] is the address used for the
/// non-web connectivity probe (default: example.com).
class NetworkInfoImpl implements NetworkInfo {
  NetworkInfoImpl({this.host = 'example.com'});

  final String host;

  @override
  Future<bool> isConnected() async {
    try {
      if (kIsWeb) {
        if (html.window.navigator.onLine != null &&
            html.window.navigator.onLine!) {
          return true;
        } else {
          return false;
        }
      } else {
        final result = await InternetAddress.lookup(host);
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          return true;
        }
        return false;
      }
    } on SocketException catch (_) {
      return false;
    }
  }
}