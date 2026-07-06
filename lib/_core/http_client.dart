import 'package:dio/dio.dart';
import 'package:hive_ce/hive.dart';

import 'constants.dart';
import 'di.dart';
import 'error/exceptions.dart';
import 'logger.dart';
import 'network/auth_interceptor.dart';
import 'network/operation_id_interceptor.dart';

class HttpClient {
  static Future<void> init() async {
    Dio dio = Dio(BaseOptions(baseUrl: Constants.apiBaseUrl));

    dio.interceptors.addAll([
      OperationIdInterceptor(),
      AuthInterceptor(tokenProvider: () async {
        try {
          final box = await di<HiveInterface>()
              .openLazyBox<String>(Constants.tokenBoxName);
          return await box.get(Constants.cachedTokenRef);
        } on Exception catch (e) {
          Log.w('HttpClient: failed to read token box', e);
          return null;
        }
      }),
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          Log.d('request: ${options.method} ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          final status = response.statusCode ?? 0;
          final body = response.data;
          final preview = body is Map
              ? ' errCode=${body['errCode']} errMsg=${body['errMsg']}'
              : '';
          Log.d('response: $status ${response.requestOptions.uri}$preview');
          if (status >= 200 && status < 300) {
            return handler.next(response);
          }
          throw ServerException();
        },
        onError: (DioException e, handler) {
          final body = e.response?.data;
          final bodyPreview = body is Map
              ? ' errCode=${body['errCode']} errMsg=${body['errMsg']}'
              : '';
          Log.e(
            'http error: ${e.type} '
            '${e.requestOptions.uri} '
            'status=${e.response?.statusCode}$bodyPreview '
            'msg=${e.message}',
          );
          return handler.next(e);
        },
      ),
    ]);

    di.registerLazySingleton(() => dio);
  }
}