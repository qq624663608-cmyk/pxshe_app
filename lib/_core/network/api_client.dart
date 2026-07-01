import 'package:dio/dio.dart';

import '../env.dart';
import 'auth_interceptor.dart';
import 'error_interceptor.dart';
import 'operation_id_interceptor.dart';

class ApiClient {
  ApiClient({
    Dio? dio,
    String? Function()? tokenProvider,
    void Function()? onUnauthorized,
  }) : _dio = dio ?? _buildDio(tokenProvider, onUnauthorized);

  final Dio _dio;

  Dio get dio => _dio;

  static Dio _buildDio(
    String? Function()? tokenProvider,
    void Function()? onUnauthorized,
  ) {
    final dio = Dio(
      BaseOptions(
        baseUrl: Env.apiBase,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 10),
        contentType: 'application/json',
        responseType: ResponseType.json,
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(tokenProvider: tokenProvider),
      OperationIdInterceptor(),
      if (onUnauthorized != null)
        ErrorInterceptor(onUnauthorized: onUnauthorized),
    ]);

    return dio;
  }

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
    Options? options,
  }) {
    return _dio.get<dynamic>(path, queryParameters: query, options: options);
  }

  Future<Response<dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
    Options? options,
  }) {
    return _dio.post<dynamic>(
      path,
      data: data,
      queryParameters: query,
      options: options,
    );
  }

  Future<Response<dynamic>> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
    Options? options,
  }) {
    return _dio.put<dynamic>(
      path,
      data: data,
      queryParameters: query,
      options: options,
    );
  }

  Future<Response<dynamic>> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
    Options? options,
  }) {
    return _dio.delete<dynamic>(
      path,
      data: data,
      queryParameters: query,
      options: options,
    );
  }
}