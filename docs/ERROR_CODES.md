# Chat 服务错误码对照表

> **本文件是后端错误码 SSOT (Single Source of Truth)。**
> 错误码与前端 `docs/ERROR_HANDLING.md` (前端 SSOT, 28 个 ErrorKey) 一一对应。
> 改这个文件要同步通知前端。

所有接口统一返回格式：
```json
{"errCode": 0, "errMsg": "", "errDlt": "", "data": {...}}
> ```
> `errCode=0` 表示成功，非 0 为错误。

---

## 一、通用错误码（OpenIM 标准）

| errCode | errMsg | 含义 | Flutter 处理建议 |
|---------|--------|------|----------------|
| 0 | - | 成功 | 正常解析 data |
| 500 | ServerInternalError | 服务器内部错误（兜底错误） | Toast "服务器异常，请稍后重试" |
| 1001 | ArgsError | 参数错误 | Toast "请求参数错误" + 检查字段类型 |
| 1002 | NoPermissionError | 权限不足 | 跳登录页（token 无效） |
| 1003 | DuplicateKeyError | 记录重复 | Toast "该记录已存在" |
| 1004 | RecordNotFoundError | 记录不存在 | Toast "记录不存在" |

---

## 二、Token 相关错误码

| errCode | errMsg | 含义 | Flutter 处理建议 |
|---------|--------|------|----------------|
| 1501 | TokenExpiredError | token 已过期 | 跳登录页，提示"登录已过期，请重新登录" |
| 1502 | TokenInvalidError | token 无效 | 跳登录页，清除本地 token |
| 1503 | TokenMalformedError | token 格式错误 | 跳登录页，清除本地 token |
| 1504 | TokenNotValidYetError | token 未生效 | Toast "登录信息未生效，请稍后" |
| 1505 | TokenUnknownError | token 未知错误 | 跳登录页，清除本地 token |
| 1506 | TokenKickedError | token 被踢下线 | 跳登录页，提示"您的账号已在其他设备登录" |
| 1507 | TokenNotExistError / ErrTokenNotExist | token 不存在 | 跳登录页，提示"请先登录" |

---

## 三、注册/登录/账号错误码

| errCode | errMsg | 含义 | Flutter 处理建议 |
|---------|--------|------|----------------|
| 20001 | PasswordError | 密码错误 | Toast "密码错误，请重新输入" |
| 20002 | AccountNotFound | 账号不存在 | Toast "该账号未注册" |
| 20003 | PhoneAlreadyRegister | 手机号已注册 | Toast "该手机号已注册，请直接登录" |
| 20004 | AccountAlreadyRegister | 账号已注册 | Toast "该用户名已注册，请直接登录" |
| 20005 | VerifyCodeSendFrequently | 验证码发送太频繁 | Toast "验证码已发送，请60秒后重试" |
| 20006 | VerifyCodeNotMatch | 验证码错误 | Toast "验证码错误，请重新输入" |
| 20007 | VerifyCodeExpired | 验证码已过期 | Toast "验证码已过期，请重新获取" |
| 20008 | VerifyCodeMaxCount | 验证码超过最大次数 | Toast "今日验证码次数已用完，请明天再试" |
| 20009 | VerifyCodeUsed | 验证码已使用 | Toast "验证码已使用，请重新获取" |
| 20010 | InvitationCodeUsed | 邀请码已使用 | Toast "邀请码已被使用" |
| 20011 | InvitationNotFound | 邀请码不存在 | Toast "邀请码无效" |
| 20012 | Forbidden | 禁止访问（账号/IP 被封） | Toast "您的账号已被限制，请联系客服" |
| 20014 | EmailAlreadyRegister | 邮箱已注册 | Toast "该邮箱已注册，请直接登录" |

---

## 四、注册策略错误码（chat-api checkRegisterPolicy）

> 注册策略校验错误使用 `errs.New()` 返回，框架转为 **500 ServerInternalError**，通过 `errMsg` 字段区分。
> Flutter 端判断 `errCode==500` 时，应读取 `errMsg` 做精确提示。

| errMsg（中文） | 含义 | Flutter 处理建议 |
|---------------|------|----------------|
| 注册功能已被管理员关闭 | 总开关 AllowRegister=false | Toast "注册通道已关闭，请稍后重试" |
| 手机号注册已被关闭 | AllowPhoneRegister=false | Toast "手机号注册已关闭，请使用邮箱或用户名注册" |
| 邮箱注册已被关闭 | AllowEmailRegister=false | Toast "邮箱注册已关闭，请使用手机号或用户名注册" |
| 用户名注册已被关闭 | AllowUsernameRegister=false | Toast "用户名注册已关闭，请使用手机号或邮箱注册" |
| 注册必须填写手机号/邮箱/用户名至少一种 | 三者都为空 | Toast "请填写手机号、邮箱或用户名" |
| 用户名格式错误:3-20 位,字母/数字/下划线 | account 格式校验失败 | Toast "用户名需3-20位，仅支持字母、数字、下划线" |
| 请先阅读并同意《用户协议》和《隐私政策》 | privacyAccepted=false | Toast "请先阅读并同意用户协议和隐私政策" |
| 隐私政策已更新,请重新阅读并同意(当前版本 vN) | 客户端版本号低于服务端 | Toast 提示"隐私政策已更新，请重新同意"，同时刷新隐私协议内容 |
| 用户协议已更新,请重新阅读并同意(当前版本 vN) | 客户端版本号低于服务端 | Toast 提示"用户协议已更新，请重新同意"，同时刷新用户协议内容 |
| 读取请求失败 | request body 读取失败 | 重试请求 |
| 请求体解析失败 | JSON 解析失败 | 检查请求体格式 |
| 读取注册策略失败 | DB 查询失败 | Toast "服务器异常，请稍后重试" |

---

## 五、注册 RPC 错误码（chat-rpc）

> 由 chat-rpc 返回，经 chat-api 透传给前端。

| errCode | errMsg | 含义 | Flutter 处理建议 |
|---------|--------|------|----------------|
| 1001 | ArgsError: area code or phone number is empty | 手机号注册但号码为空 | 检查手机号字段 |
| 1001 | ArgsError: area code must be number | 区号非数字 | 检查 areaCode 格式 |
| 1001 | ArgsError: phone number must be number | 手机号非数字 | 检查 phoneNumber 格式 |
| 1001 | ArgsError: email must be right | 邮箱格式错误 | Toast "请输入正确的邮箱地址" |
| 1001 | ArgsError: invitation code is empty | 邀请码模式但未填写 | 检查邀请码字段 |
| 1001 | ArgsError: email, phone or account must be set | 三种注册方式都未填 | 检查注册请求体 |
| 1001 | ArgsError: password or code must be set | 登录时密码和验证码都未填 | 检查登录字段 |
| 1001 | ArgsError: used unknown | 使用方式未知 | 联系后端 |
| 1001 | ArgsError: verify code is empty | 验证码为空 | Toast "请输入验证码" |
| 1001 | ArgsError: appoint user id already register | 指定的 userID 已存在 | Toast "该用户ID已被使用" |
| 1001 | ArgsError: user is nil | 用户信息为空 | 检查请求体 user 字段 |
| 1001 | ArgsError: at least one valid account is required | 至少需要一种登录方式 | 检查账号字段 |
| 1001 | ArgsError: account must be alphanumeric | 用户名格式错误 | Toast "用户名仅支持字母和数字" |
| 20001 | PasswordError | 密码错误 | Toast "密码错误" |
| 20002 | AccountNotFound | 账号不存在 | Toast "账号未注册" |
| 20003 | PhoneAlreadyRegister | 手机号已注册 | Toast "手机号已注册" |
| 20004 | AccountAlreadyRegister | 账号已注册 | Toast "用户名已注册" |
| 20005 | VerifyCodeSendFrequently | 验证码发送太频繁 | Toast "请60秒后重试" |
| 20006 | VerifyCodeNotMatch | 验证码错误 | Toast "验证码错误" |
| 20007 | VerifyCodeExpired | 验证码过期 | Toast "验证码已过期，请重新获取" |
| 20008 | VerifyCodeMaxCount | 验证码次数用完 | Toast "今日验证码次数已用完" |
| 20009 | VerifyCodeUsed | 验证码已使用 | Toast "验证码已使用，请重新获取" |
| 1002 | NoPermissionError: register user is disabled | 注册被关闭 | Toast "注册已关闭" |
| 1002 | NoPermissionError: only admin can set user id | 普通用户不能指定 userID | 检查请求体 |
| 500 | ServerInternalError: email verification code is not enabled | 邮箱验证码未开启 | Toast "邮箱验证暂不可用" |
| 500 | ServerInternalError: mobile phone verification code is not enabled | 短信验证码未开启 | Toast "短信验证暂不可用" |
| 500 | ServerInternalError: gen user id failed | 生成 userID 失败 | 重试或联系后端 |

---

## 六、admin 后台错误码（admin-api）

> admin 后台接口错误格式与 chat-api 相同，但部分接口用 `errorMsg` 字段。

| errCode | errMsg / errorMsg | 含义 | 前端处理建议 |
|---------|------------------|------|------------|
| 1001 | ArgsError: account is empty | 账号为空 | 检查输入 |
| 1001 | ArgsError: password is empty | 密码为空 | 检查输入 |
| 1001 | ArgsError: 原密码错误 | 修改密码时原密码错误 | Toast "原密码错误" |
| 1001 | ArgsError: 新密码长度不能少于 6 位 | 密码太短 | Toast "密码至少6位" |
| 1001 | ArgsError: 新密码不能与原密码相同 | 新旧密码一样 | Toast "新密码不能与原密码相同" |
| 1001 | ArgsError: config name not found | 配置名不存在 | Toast "配置不存在" |
| 1003 | DuplicateKeyError: the account is registered | 账号已存在 | Toast "该管理员账号已存在" |
| 1002 | NoPermissionError: 验证超管权限失败 | token 无效 | 跳登录页 |
| 1002 | NoPermissionError: 此操作仅限超级管理员 | level 不足 | Toast "仅超级管理员可操作" |

---

## 七、Universe 接口业务错误码（chat-api / admin-api）

> Universe 接口统一返回 `{"errorCode": 0, "data": ...}` 成功，错误时 HTTP status 非 200 或 `errorCode` 非 0。
> chat-api 普通用户接口用 `errorCode` 字段；admin-api 也用 `errorCode` 字段。

| errCode | 含义 | 前端处理建议 |
|---------|------|------------|
| 0 | 成功 | 解析 data |
| 1001 | 参数错误（参数为空/格式错误） | 检查请求体 |
| 1003 | 名称重复（创建同名世界/子表） | Toast "名称已存在，请换一个" |
| 1004 | 记录不存在（世界/子表/行不存在） | Toast "数据不存在" |
| 500 | 服务器错误 | Toast "服务器异常" |

---

## 八、HTTP Status Code 对照

> OpenIM 框架所有接口**统一返回 HTTP 200**，错误码在 response body 的 `errCode` 字段。
> nginx 反代层可能出现的 HTTP 状态码：

| HTTP Status | 含义 | Flutter 处理建议 |
|-------------|------|----------------|
| 200 | 正常（看 errCode） | 解析 response body |
| 401 | nginx 层 token 缺失 | 跳登录页 |
| 403 | nginx 层权限不足 | 跳登录页 |
| 404 | 接口路径错误 | 检查 API 路径拼写 |
| 502 | 后端服务未启动 | Toast "服务暂不可用" |
| 504 | 后端响应超时 | Toast "请求超时，请重试" |

---

## 九、Flutter 端全局错误处理建议

```dart
/// 统一错误处理
void handleApiError(Map<String, dynamic> response) {
  final errCode = response['errCode'] ?? 0;
  final errMsg = response['errMsg'] ?? '';

  if (errCode == 0) return; // 成功

  // Token 相关 → 跳登录页
  if ([1501, 1502, 1503, 1504, 1505, 1506, 1507].contains(errCode)) {
    Navigator.of(context).pushReplacementNamed('/login');
    return;
  }

  // 需要读 errMsg 的 500 错误（注册策略等）
  if (errCode == 500 && errMsg.isNotEmpty) {
    showToast(errMsg);
    return;
  }

  // 其他错误
  showToast(errMsg.isNotEmpty ? errMsg : '操作失败，请重试');
}
```

---

**文档版本**: v1.0 | 2026-07-02
**覆盖范围**: chat-api / chat-rpc / admin-api / admin-rpc 所有返回错误码的路径
