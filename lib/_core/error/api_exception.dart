import 'package:dio/dio.dart';

/// Single source of truth for backend error codes (pxshe_app).
/// Aligned with `F:\wx\pxshe_app\docs\ERROR_CODES.md` (backend SSOT).
///
/// SSOT version: 2026-07-02
/// Backend domain: chat.pxshe.com (chat-api)
/// 28 error keys in 7 sections: 1xxx + 1.5xxx + 2xxx + 3xxx + 4xxx + 5xxx + 6xxx
enum ErrorKey {
  // 1xxx 通用 / 参数 (4)
  argsError(1001, 'ArgsError'),
  noPermission(1002, 'NoPermissionError'),
  duplicateKey(1003, 'DuplicateKeyError'),
  recordNotFound(1004, 'RecordNotFoundError'),

  // 1.5xxx Token 错误 (7, OpenIM 标准)
  tokenExpired(1501, 'TokenExpiredError'),
  tokenInvalid(1502, 'TokenInvalidError'),
  tokenMalformed(1503, 'TokenMalformedError'),
  tokenNotValidYet(1504, 'TokenNotValidYetError'),
  tokenUnknown(1505, 'TokenUnknownError'),
  tokenKicked(1506, 'TokenKickedError'),
  tokenNotExist(1507, 'TokenNotExistError'),

  // 2xxx 注册/登录/账号 (12)
  passwordError(20001, 'PasswordError'),
  accountNotFound(20002, 'AccountNotFound'),
  phoneAlreadyRegister(20003, 'PhoneAlreadyRegister'),
  accountAlreadyRegister(20004, 'AccountAlreadyRegister'),
  verifyCodeSendFrequently(20005, 'VerifyCodeSendFrequently'),
  verifyCodeNotMatch(20006, 'VerifyCodeNotMatch'),
  verifyCodeExpired(20007, 'VerifyCodeExpired'),
  verifyCodeMaxCount(20008, 'VerifyCodeMaxCount'),
  verifyCodeUsed(20009, 'VerifyCodeUsed'),
  invitationCodeUsed(20010, 'InvitationCodeUsed'),
  invitationNotFound(20011, 'InvitationNotFound'),
  forbidden(20012, 'Forbidden'),
  emailAlreadyRegister(20014, 'EmailAlreadyRegister'),

  // 3xxx 资源/文件 (3)
  fileRequired(3001, 'FileRequired'),
  fileTypeNotSupported(3002, 'FileTypeNotSupported'),
  fileTooLarge(3003, 'FileTooLarge'),

  // 4xxx OpenIM 透传 (5)
  imUnavailable(4001, 'IMUnavailable'),
  imTokenNotExist(4002, 'IMTokenNotExist'),
  imTokenKicked(4003, 'IMTokenKicked'),
  imTokenExpired(4004, 'IMTokenExpired'),
  imNotSupported(4005, 'IMNotSupported'),

  // 5xxx 业务逻辑 (6)
  universeAlreadyExists(5001, 'UniverseAlreadyExists'),
  tableAlreadyExists(5002, 'TableAlreadyExists'),
  createFailed(5003, 'CreateFailed'),
  updateFailed(5004, 'UpdateFailed'),
  deleteFailed(5005, 'DeleteFailed'),
  operationForbidden(5006, 'OperationForbidden'),

  // 6xxx 服务异常 (1)
  serverInternalError(6001, 'ServerInternalError'),

  // 兜底
  unknown(-1, 'Unknown');

  const ErrorKey(this.code, this.backendName);
  final int code;
  final String backendName;

  /// Map backend errCode to ErrorKey. Returns [unknown] if no match.
  static ErrorKey fromCode(int? code) {
    if (code == null) return ErrorKey.unknown;
    if (code == 0) return ErrorKey.unknown;
    for (final k in ErrorKey.values) {
      if (k.code == code) return k;
    }
    return ErrorKey.unknown;
  }

  /// Map HTTP status code to a fallback ErrorKey
  /// (when body is not parseable, e.g. nginx 502/503/504).
  static ErrorKey fromStatusCode(int? statusCode) {
    if (statusCode == null) return ErrorKey.unknown;
    if (statusCode == 401) return ErrorKey.tokenInvalid;
    if (statusCode == 403) return ErrorKey.noPermission;
    if (statusCode == 400) return ErrorKey.argsError;
    if (statusCode == 502 || statusCode == 503 || statusCode == 504) {
      return ErrorKey.serverInternalError;
    }
    return ErrorKey.unknown;
  }

  /// Map DioExceptionType to a fallback ErrorKey
  /// (when no response body, e.g. timeout / network failure).
  static ErrorKey fromDioType(DioExceptionType type) {
    switch (type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ErrorKey.unknown;
      case DioExceptionType.unknown:
        return ErrorKey.unknown;
      default:
        return ErrorKey.unknown;
    }
  }

  /// Whether this error indicates an auth failure that should
  /// trigger token cleanup + redirect to login.
  bool get isAuthError =>
      (code >= 1501 && code <= 1507) ||
      code == 1002 ||
      code == 20012;
}

/// API exception with code + message.
class ApiException implements Exception {
  ApiException({
    required this.errorKey,
    this.errCode,
    this.message,
    this.statusCode,
  });

  factory ApiException.fromResponse(Response<dynamic> res) {
    final data = res.data;
    int? errCode;
    String? errMsg;
    if (data is Map) {
      errCode = data['errCode'] as int?;
      errMsg = (data['errMsg'] ?? data['errMsg'])?.toString();
    }
    final key = errCode != null
        ? ErrorKey.fromCode(errCode)
        : ErrorKey.fromStatusCode(res.statusCode);

    return ApiException(
      errorKey: key,
      errCode: errCode,
      message: errMsg ?? _defaultMessageFor(key),
      statusCode: res.statusCode,
    );
  }

  factory ApiException.fromDioError(DioException err) {
    if (err.response != null) {
      return ApiException.fromResponse(err.response!);
    }
    final key = ErrorKey.fromDioType(err.type);
    return ApiException(
      errorKey: key,
      message: _defaultDioTypeMessage(err.type),
      statusCode: err.response?.statusCode,
    );
  }

  final ErrorKey errorKey;
  final int? errCode;
  final String? message;
  final int? statusCode;

  @override
  String toString() => message ?? errorKey.name;
}

String _defaultMessageFor(ErrorKey key) {
  switch (key) {
    case ErrorKey.argsError:
      return '请求参数错误';
    case ErrorKey.noPermission:
      return '权限不足';
    case ErrorKey.duplicateKey:
      return '记录已存在';
    case ErrorKey.recordNotFound:
      return '记录不存在';
    case ErrorKey.tokenExpired:
    case ErrorKey.tokenInvalid:
    case ErrorKey.tokenMalformed:
    case ErrorKey.tokenNotValidYet:
    case ErrorKey.tokenUnknown:
    case ErrorKey.tokenNotExist:
      return '登录已过期,请重新登录';
    case ErrorKey.tokenKicked:
      return '您的账号在另一台设备登录';
    case ErrorKey.passwordError:
      return '账号或密码错误';
    case ErrorKey.accountNotFound:
      return '账号不存在';
    case ErrorKey.phoneAlreadyRegister:
      return '该手机号已注册,请直接登录';
    case ErrorKey.accountAlreadyRegister:
      return '该用户名已注册,请直接登录';
    case ErrorKey.emailAlreadyRegister:
      return '该邮箱已注册,请直接登录';
    case ErrorKey.verifyCodeSendFrequently:
      return '请60秒后重试';
    case ErrorKey.verifyCodeNotMatch:
      return '验证码错误';
    case ErrorKey.verifyCodeExpired:
      return '验证码已过期,请重新获取';
    case ErrorKey.verifyCodeMaxCount:
      return '今日验证码次数已用完';
    case ErrorKey.verifyCodeUsed:
      return '验证码已使用,请重新获取';
    case ErrorKey.invitationCodeUsed:
      return '邀请码已被使用';
    case ErrorKey.invitationNotFound:
      return '邀请码无效';
    case ErrorKey.forbidden:
      return '没有权限';
    case ErrorKey.fileRequired:
      return '请选择文件';
    case ErrorKey.fileTypeNotSupported:
      return '仅支持 JPG/PNG/PDF';
    case ErrorKey.fileTooLarge:
      return '文件大小不能超过 10MB';
    case ErrorKey.imUnavailable:
      return 'IM 服务暂不可用';
    case ErrorKey.imTokenNotExist:
      return 'IM 登录已过期';
    case ErrorKey.imTokenKicked:
      return '您已被踢下线';
    case ErrorKey.imTokenExpired:
      return 'IM 登录已过期';
    case ErrorKey.imNotSupported:
      return '当前不支持';
    case ErrorKey.universeAlreadyExists:
      return '宇宙名已存在';
    case ErrorKey.tableAlreadyExists:
      return '子表名已存在';
    case ErrorKey.createFailed:
      return '创建失败';
    case ErrorKey.updateFailed:
      return '更新失败';
    case ErrorKey.deleteFailed:
      return '删除失败';
    case ErrorKey.operationForbidden:
      return '操作被禁止';
    case ErrorKey.serverInternalError:
      return '服务异常';
    case ErrorKey.unknown:
      return '操作失败';
  }
}

String _defaultDioTypeMessage(DioExceptionType type) {
  switch (type) {
    case DioExceptionType.cancel:
      return '请求被取消';
    case DioExceptionType.connectionTimeout:
      return '连接超时';
    case DioExceptionType.receiveTimeout:
      return '响应超时';
    case DioExceptionType.sendTimeout:
      return '发送超时';
    case DioExceptionType.badResponse:
      return '服务器错误';
    case DioExceptionType.unknown:
      return '网络错误';
    default:
      return '未知错误';
  }
}