import 'dart:async';

import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({this.tokenProvider});

  /// Token lookup. May be sync (returns `String?`) or async
  /// (returns `Future<String?>`) — `FutureOr` accepts both.
  final FutureOr<String?> Function()? tokenProvider;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await tokenProvider?.call();
    if (token != null && token.isNotEmpty) {
      options.headers['token'] = token;
    }
    handler.next(options);
  }
}
