# docs/ERROR_HANDLING.md — 错误码详细

> **本文件是 pxshe_app 错误码 SSOT (Single Source of Truth)。**
> 与后端 `F:\wx\pxshe_app\docs\ERROR_CODES.md` 一一对应。
> 后端 errCode 与前端 ErrorKey 一一映射, 改这个文件要同步通知后端。

---

## 1. 错误响应统一格式

所有接口统一返回:

```json
{
  "errCode": 0,
  "errMsg": "",
  "errDlt": "",
  "data": {...}
}
```

| 字段 | 含义 |
|---|---|
| `errCode` | 错误码, 0 = 成功, 非 0 = 错误 |
| `errMsg` | 错误信息 (中文), 用户可见 |
| `errDlt` | 详细原因 (可选), 仅开发者看 |
| `data` | 业务数据 (成功时填充) |

Flutter 端用 `ApiException.fromResponse` 解析, 提取 errCode → `ErrorKey.fromCode` 映射。

---

## 2. 错误码 7 段 (28 个 ErrorKey)

### 2.1 1xxx 通用 / 参数 (4 个)

| errCode | ErrorKey | backendName | 含义 | Flutter 处理 |
|---|---|---|---|---|
| 1001 | `argsError` | ArgsError | 参数错误 | Toast "请求参数错误" |
| 1002 | `noPermission` | NoPermissionError | 权限不足 | 跳登录页 (清 token) |
| 1003 | `duplicateKey` | DuplicateKeyError | 记录重复 | Toast "记录已存在" |
| 1004 | `recordNotFound` | RecordNotFoundError | 记录不存在 | Toast "记录不存在" |

### 2.2 1.5xxx Token 错误 (7 个, OpenIM 标准)

| errCode | ErrorKey | backendName | 含义 | Flutter 处理 |
|---|---|---|---|---|
| 1501 | `tokenExpired` | TokenExpiredError | token 已过期 | 跳登录页, 提示"登录已过期" |
| 1502 | `tokenInvalid` | TokenInvalidError | token 无效 | 跳登录页, 清 token |
| 1503 | `tokenMalformed` | TokenMalformedError | token 格式错误 | 跳登录页, 清 token |
| 1504 | `tokenNotValidYet` | TokenNotValidYetError | token 未生效 | Toast "登录信息未生效" |
| 1505 | `tokenUnknown` | TokenUnknownError | token 未知错误 | 跳登录页, 清 token |
| 1506 | `tokenKicked` | TokenKickedError | token 被踢 | 跳登录页, 提示"已在其他设备登录" |
| 1507 | `tokenNotExist` | TokenNotExistError | token 不存在 | 跳登录页, 提示"请先登录" |

### 2.3 2xxx 注册/登录/账号 (12 个)

| errCode | ErrorKey | backendName | 含义 | Flutter 处理 |
|---|---|---|---|---|
| 20001 | `passwordError` | PasswordError | 密码错误 | Toast "账号或密码错误" |
| 20002 | `accountNotFound` | AccountNotFound | 账号不存在 | Toast "账号不存在" |
| 20003 | `phoneAlreadyRegister` | PhoneAlreadyRegister | 手机号已注册 | Toast "该手机号已注册" |
| 20004 | `accountAlreadyRegister` | AccountAlreadyRegister | 账号已注册 | Toast "该用户名已注册" |
| 20005 | `verifyCodeSendFrequently` | VerifyCodeSendFrequently | 验证码发送太频繁 | Toast "请60秒后重试" |
| 20006 | `verifyCodeNotMatch` | VerifyCodeNotMatch | 验证码错误 | Toast "验证码错误" |
| 20007 | `verifyCodeExpired` | VerifyCodeExpired | 验证码已过期 | Toast "验证码已过期, 请重新获取" |
| 20008 | `verifyCodeMaxCount` | VerifyCodeMaxCount | 验证码超过最大次数 | Toast "今日次数已用完" |
| 20009 | `verifyCodeUsed` | VerifyCodeUsed | 验证码已使用 | Toast "验证码已使用" |
| 20010 | `invitationCodeUsed` | InvitationCodeUsed | 邀请码已使用 | Toast "邀请码已被使用" |
| 20011 | `invitationNotFound` | InvitationNotFound | 邀请码不存在 | Toast "邀请码无效" |
| 20012 | `forbidden` | Forbidden | 禁止访问 | Toast "您的账号已被限制" |
| 20014 | `emailAlreadyRegister` | EmailAlreadyRegister | 邮箱已注册 | Toast "该邮箱已注册" |

### 2.4 3xxx 资源/文件 (3 个)

| errCode | ErrorKey | backendName | 含义 | Flutter 处理 |
|---|---|---|---|---|
| 3001 | `fileRequired` | FileRequired | 缺文件 | Toast "请选择文件" |
| 3002 | `fileTypeNotSupported` | FileTypeNotSupported | 文件类型不支持 | Toast "仅支持 JPG/PNG/PDF" |
| 3003 | `fileTooLarge` | FileTooLarge | 文件 > 10MB | Toast "文件大小不能超过 10MB" |

### 2.5 4xxx OpenIM 透传 (5 个)

| errCode | ErrorKey | backendName | 含义 | Flutter 处理 |
|---|---|---|---|---|
| 4001 | `imUnavailable` | IMUnavailable | IM 服务暂不可用 | Toast "IM 服务暂不可用" |
| 4002 | `imTokenNotExist` | IMTokenNotExist | IM token 不存在 | 跳登录页 |
| 4003 | `imTokenKicked` | IMTokenKicked | IM 已被踢 | 跳登录页, 提示"已被踢" |
| 4004 | `imTokenExpired` | IMTokenExpired | IM token 过期 | 跳登录页 |
| 4005 | `imNotSupported` | IMNotSupported | IM 不支持 | Toast "当前不支持" |

### 2.6 5xxx 业务逻辑 (6 个)

| errCode | ErrorKey | backendName | 含义 | Flutter 处理 |
|---|---|---|---|---|
| 5001 | `universeAlreadyExists` | UniverseAlreadyExists | 宇宙名重 | Toast "宇宙名已存在" |
| 5002 | `tableAlreadyExists` | TableAlreadyExists | 子表名重 | Toast "子表名已存在" |
| 5003 | `createFailed` | CreateFailed | 创建失败 | Toast "创建失败" |
| 5004 | `updateFailed` | UpdateFailed | 更新失败 | Toast "更新失败" |
| 5005 | `deleteFailed` | DeleteFailed | 删除失败 | Toast "删除失败" |
| 5006 | `operationForbidden` | OperationForbidden | 操作被禁 | Toast "操作被禁止" |

### 2.7 6xxx 服务异常 (1 个)

| errCode | ErrorKey | backendName | 含义 | Flutter 处理 |
|---|---|---|---|---|
| 6001 | `serverInternalError` | ServerInternalError | 服务器内部错误 (兜底) | Toast "服务异常" |

---

## 3. HTTP Status Code 兜底映射

OpenIM 框架所有接口**统一返回 HTTP 200**, 错误码在 body 的 `errCode` 字段。

但 nginx 反代可能返回:

| HTTP Status | ErrorKey | 含义 |
|---|---|---|
| 200 | 走 errCode | 正常 (看 errCode) |
| 400 | `argsError` | nginx 层参数错 |
| 401 | `tokenInvalid` | nginx 层 token 缺失 |
| 403 | `noPermission` | nginx 层权限不足 |
| 404 | `recordNotFound` | 接口路径错 |
| 502 / 503 / 504 | `serverInternalError` | 后端服务未启动 / 响应超时 |

Flutter 端 `ErrorKey.fromStatusCode` 处理。

---

## 4. Flutter 端全局错误处理

```dart
// lib/_core/error/error_handler.dart
class ErrorHandler {
  static void handle(
    BuildContext context,
    Object error, {
    bool isOnAuthPage = false,
    void Function()? onUnauthorized,
  }) {
    final apiException = error is ApiException
        ? error
        : ApiException(errorKey: ErrorKey.unknown, message: error.toString());

    final isAuthError = apiException.errorKey.isAuthError;

    if (isAuthError) {
      onUnauthorized?.call();  // 清 token + 跳登录
    }

    if (isOnAuthPage && isAuthError) {
      return;  // 登录页不显示 snack
    }

    _showSnack(context, apiException.message);
  }
}
```

### 4.0 Snackbar 3 级 fallback (避免静默失败)

**之前 bug**: `_showSnack` 用 `ScaffoldMessenger.maybeOf(context)`, local 找不到时**静默 `return`**, 用户看不到错误, 也无任何 log 提示。

**修法 (3 级 fallback)**:

```dart
// lib/_core/error/error_handler.dart
static void _showSnack(BuildContext context, String message) {
  SchedulerBinding.instance.addPostFrameCallback((_) {
    // 1. 本地 context 的 messenger (正常路径)
    // 2. rootNavigatorKey 的 messenger (fallback)
    // 3. Log.e 兜底 (最起码 logcat 看得到)
    final messenger = ScaffoldMessenger.maybeOf(context) ??
        _rootMessenger();
    if (messenger == null) {
      Log.e('ErrorHandler: cannot show SnackBar, no ScaffoldMessenger: $message');
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text(message), duration: AppDurations.snack),
    );
  });
}

static ScaffoldMessengerState? _rootMessenger() {
  final ctx = rootNavigatorKey.currentContext;
  if (ctx == null) return null;
  return ScaffoldMessenger.maybeOf(ctx);
}
```

**触发场景**: 嵌套 Navigator + ScaffoldMessenger 作用域不一致时 (如 GoRouter 跨 Navigator 跳页), local context 找不到 ScaffoldMessenger, fallback 到 root 一定能找到。

### 4.1 哪些算 auth 错误 (isAuthError)

```dart
bool get isAuthError =>
    (code >= 1501 && code <= 1507) ||  // Token 错误
    code == 1002 ||                       // NoPermissionError
    code == 20012;                        // Forbidden
```

### 4.2 调用方

```dart
// 在 Repository 层
try {
  final res = await dio.post('/account/login', data: {...});
  return Right(User.fromJson(res.data));
} on DioException catch (e) {
  return Left(ApiException.fromDioError(e).message ?? '网络错误');
}

// 在 Widget 层
ErrorHandler.handle(context, error);
```

---

## 5. 注册策略 (500 + errMsg 文本匹配)

后端某些错误 (注册策略) 用 `errCode=500` + `errMsg` 区分。Flutter 端:

```dart
if (apiException.errorKey == ErrorKey.serverInternalError) {
  // 检查 errMsg 文本
  final msg = apiException.message ?? '';
  if (msg.contains('已被管理员关闭')) {
    showToast('注册通道已关闭');
  } else if (msg.contains('手机号注册已被关闭')) {
    showToast('手机号注册已关闭');
  }
  // ... 其他策略
}
```

具体见 `F:\wx\app\BACKEND_DESIGN_SPEC.md` 第三节。

---

## 6. 错误码变更流程

**改错误码要同步**:
1. 后端工程师改 `F:\wx\app\chat\pkg\common\errcode\codes.go`
2. 后端工程师更新 `F:\wx\pxshe_app\docs/ERROR_CODES.md` (后端 SSOT)
3. 前端工程师更新 `F:\wx\pxshe_app\docs/ERROR_HANDLING.md` (前端 SSOT, 本文件)
4. 前端工程师更新 `lib/_core/error/api_exception.dart` ErrorKey enum
5. 前端工程师跑 `tool/check_official.ps1` 验证
6. CI 通过后,通知后端发版

---

## 7. 覆盖率检查

每个 ErrorKey 必须有对应测试:

```dart
// test/_core/error/api_exception_test.dart
test('returns argsError for 1001', () {
  expect(ErrorKey.fromCode(1001), ErrorKey.argsError);
});
// ... 28 个 ErrorKey 都有
```

CI 强制覆盖率 ≥ 80% (widget tree 100% 难达)。

---

*最后更新: 2026-07-02 — 对齐后端 ERROR_CODES.md v1.0*
*覆盖: 28 个 ErrorKey, 7 段 (1xxx/1.5xxx/2xxx/3xxx/4xxx/5xxx/6xxx)*