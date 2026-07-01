import 'package:dio/dio.dart';

import '../error/api_exception.dart';

class ErrorInterceptor extends Interceptor {
  ErrorInterceptor({this.onUnauthorized, this.onApiError});

  final void Function()? onUnauthorized;
  final void Function(ApiException exception)? onApiError;

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    final apiException = ApiException.fromDioError(err);

    if (err.response?.statusCode == 401) {
      onUnauthorized?.call();
    }

    onApiError?.call(apiException);
    handler.next(err);
  }
}