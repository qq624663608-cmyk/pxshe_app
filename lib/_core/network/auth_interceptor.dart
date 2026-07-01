import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({this.tokenProvider});

  final String? Function()? tokenProvider;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final token = tokenProvider?.call();
    if (token != null && token.isNotEmpty) {
      options.headers['token'] = token;
    }
    handler.next(options);
  }
}