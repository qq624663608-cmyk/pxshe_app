# docs/ERROR_HANDLING.md — 错误码详细

> **本文件是错误处理 SSOT。**
> 客户端唯一错误入口: `ErrorHandler.handle(context, e)`。

---

## 1. 错误码分类 (6 段)

| 段位 | 含义 | HTTP | 客户端动作 |
|---|---|---|---|
| 1xxx | 参数/校验错 | 400 | SnackBar |
| 2xxx | 鉴权错 (token/账号) | 401 | 跳登录 + 清 Token |
| 3xxx | 资源/文件错 | 400/404 | SnackBar |
| 4xxx | OpenIM 集成错 | 401/403/500/503 | 跳登录/SnackBar |
| 5xxx | 业务逻辑错 | 400/409 | SnackBar |
| 6xxx | 服务异常 | 500 | SnackBar |

---

## 2. 完整错误码表 (pxshe_app 定制)

### 1xxx 参数/校验

| ErrorKey | errCode | 后端触发 | i18n (zh) |
|---|---|---|---|
| `missingRequiredField` | 1001 | 缺字段 | 请填写所有必填项 |
| `passwordTooShort` | 1002 | 密码 < 6 位 | 密码至少 6 位 |
| `phoneInvalid` | 1003 | 手机号格式错 | 手机号格式错误 |
| `userAlreadyExists` | 1004 | 用户名重 | 该用户名已被使用 |
| `emailInvalid` | 1005 | 邮箱格式错 | 邮箱格式错误 |
| `verifyCodeInvalid` | 1006 | 验证码错 | 验证码错误 |
| `policyVersionExpired` | 1007 | 协议版本过期 | 协议已更新,请重新阅读 |
| `policyNotAccepted` | 1008 | 协议未勾选 | 请勾选隐私协议 |

### 2xxx 鉴权

| ErrorKey | errCode | 后端触发 | i18n |
|---|---|---|---|
| `passwordError` | 20001 | 登录密码错 | 账号或密码错误 |
| `userNotFound` | 20002 | 用户不存在 | 用户不存在 |
| `accountBanned` | 20003 | User.is_active=False | 账号已被封禁 |
| `tokenInvalid` | 20004 | JWT 格式错 | 登录信息异常 |
| `tokenExpired` | 20005 | JWT exp | 登录已过期 |
| `tokenMissing` | 20006 | 无 Authorization | 未登录 |
| `kickedOffline` | 20007 | 另一设备登录 | 您的账号在另一台设备登录 |
| `forbidden` | 20008 | 权限不足 | 没有权限 |

### 3xxx 资源/文件

| ErrorKey | errCode | i18n |
|---|---|---|
| `fileRequired` | 3001 | 请选择文件 |
| `fileTypeNotSupported` | 3002 | 仅支持 JPG/PNG/PDF |
| `fileTooLarge` | 3003 | 文件大小不能超过 10MB |
| `universeNotFound` | 3004 | 宇宙不存在 |
| `tableNotFound` | 3005 | 子表不存在 |
| `rowNotFound` | 3006 | 数据行不存在 |

### 4xxx OpenIM

| ErrorKey | errCode | i18n |
|---|---|---|
| `imUnavailable` | 4001 | IM 服务暂不可用 |
| `imTokenNotExist` | 4002 | IM 登录已过期 |
| `imTokenKicked` | 4003 | 您已被踢下线 |
| `imTokenExpired` | 4004 | IM 登录已过期 |
| `imNotSupported` | 4005 | 当前不支持 |
| `imConnectFailed` | 4006 | IM 连接失败 |
| `imSendMessageFailed` | 4007 | 消息发送失败 |

### 5xxx 业务逻辑

| ErrorKey | errCode | i18n |
|---|---|---|
| `universeAlreadyExists` | 5001 | 宇宙名已存在 |
| `tableAlreadyExists` | 5002 | 子表名已存在 |
| `createFailed` | 5003 | 创建失败 |
| `updateFailed` | 5004 | 更新失败 |
| `deleteFailed` | 5005 | 删除失败 |
| `operationForbidden` | 5006 | 操作被禁止 (不是自己创建的) |

### 6xxx 服务异常

| ErrorKey | errCode | i18n |
|---|---|---|
| `serverInternalError` | 6001-6009 | 服务异常,请稍后重试 |
| `serviceUnavailable` | 6010 | 服务暂不可用 |
| `timeout` | 6020 | 请求超时 |
| `networkError` | 6030 | 网络错误 |
| `unknown` | -1 | 操作失败 (兜底) |

---

## 3. ApiException 推断顺序 (3 层)

```dart
// lib/_core/error/api_exception.dart
int? _resolveErrCode(ApiException e) {
  // 1. 后端已返 errCode
  if (e.errCode != null) return e.errCode;

  // 2. NetworkException / TimeoutException
  if (e is NetworkException) return 6030;  // networkError
  if (e is TimeoutException) return 6020;  // timeout

  // 3. statusCode 兜底
  switch (e.statusCode) {
    case 401: return ErrCodeInferrer.infer(e.message) ?? 20004;  // tokenInvalid
    case 403: return 20008;  // forbidden
    case 404: return ErrCodeInferrer.infer(e.message) ?? 3004;  // universeNotFound
    case 502:
    case 503:
    case 504: return 4001;  // imUnavailable
  }

  // 4. detail 关键词推断
  return ErrCodeInferrer.infer(e.message) ?? -1;  // unknown
}
```

---

## 4. ApiException 实现

```dart
// lib/_core/error/api_exception.dart
class ApiException implements Exception {
  ApiException({
    required this.errorKey,
    this.errCode,
    this.message,
    this.statusCode,
  });

  final ErrorKey errorKey;
  final int? errCode;
  final String? message;
  final int? statusCode;

  factory ApiException.fromResponse(Response<dynamic> res) {
    final data = res.data as Map?;
    if (data != null && data['errorCode'] != null) {
      return ApiException(
        errorKey: ErrCodeInferrer.infer(data['errMsg']?.toString()) ?? ErrorKey.unknown,
        errCode: data['errorCode'] as int?,
        message: data['errMsg']?.toString(),
        statusCode: res.statusCode,
      );
    }
    return ApiException(
      errorKey: ErrorKey.unknown,
      statusCode: res.statusCode,
    );
  }
}
```

---

## 5. ErrorHandler

```dart
// lib/_core/error/error_handler.dart
class ErrorHandler {
  static void handle(BuildContext context, Object e, {bool isOnAuthPage = false}) {
    final apiEx = e is ApiException ? e : ApiException.fromError(e);
    final errorKey = apiEx.errorKey;
    final message = ErrorMessages.t(context, errorKey);

    if (isOnAuthPage) {
      // 登录/注册页不跳登录 (避免误清 token)
      showErrorSnackBar(context, message);
      return;
    }

    if (errorKey == ErrorKey.tokenExpired
        || errorKey == ErrorKey.tokenInvalid
        || errorKey == ErrorKey.tokenMissing
        || errorKey == ErrorKey.kickedOffline) {
      // 清 token + 跳登录
      di<AuthRepository>().logout();
      di<AppRouter>().router.go('/login');
      showErrorSnackBar(context, message);
      return;
    }

    showErrorSnackBar(context, message);
  }
}
```

---

## 6. 加新错误码 (3 步)

```
□ 1. lib/_core/error/error_keys.dart enum 加 1 行 (ErrorKey + i18n key + errCode)
□ 2. lib/_core/i18n/error_messages.dart 加中文 + 英文 2 行
□ 3. test/_core/error/error_keys_test.dart 加 1 case
```

详见 [RECIPES.md §4](./RECIPES.md)。

---

*最后更新: 2026-07-01*