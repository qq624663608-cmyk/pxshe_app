import 'package:dio/dio.dart';

class OperationIdInterceptor extends Interceptor {
  OperationIdInterceptor();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    options.headers['operationID'] = _generate(options.path);
    handler.next(options);
  }

  String _generate(String path) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = (ts % 9999).toString().padLeft(4, '0');
    final biz = _extractBiz(path);
    return '$biz-$ts-$rand';
  }

  String _extractBiz(String path) {
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.length >= 2) {
      return '${segments[0]}-${segments[1]}';
    }
    return segments.isNotEmpty ? segments.first : 'req';
  }
}