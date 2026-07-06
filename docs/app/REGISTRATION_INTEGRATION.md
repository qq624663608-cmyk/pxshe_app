# 注册策略模块 前端对接文档

> 给 Flutter 客户端用的注册策略 + 隐私协议对接说明
> 后端基于 admin 后台可配置,Flutter 必须启动时拉一次,决定注册页 UI 和行为

---

## ⚠️ 必读

1. **Flutter 启动时必拉**: `GET /business/public/registration/config/get`,**无需 token**
2. **根据返回的 `availableMethods` 动态渲染注册页**:只有 phone 就只显示手机号输入框
3. **隐私协议**: 若 `privacyPolicyUrl` 或 `userAgreementUrl` 非空,注册页**强制勾选**"我已阅读并同意"
4. **三种注册方式关闭 → 拒绝调用**: 调 `/account/register` 时该字段会被后端拒绝(403 + 错误信息)

---

## 1. 基础信息

### 1.1 接口列表

| 接口 | 用途 | 是否鉴权 |
|------|------|----------|
| `POST /business/public/registration/config/get` | 拉取当前注册策略(启动时调) | ❌ 公开 |
| `POST /account/register` | 注册用户(受策略限制) | ❌ 公开,但带策略校验 |

### 1.2 服务地址

| 环境 | base URL |
|------|----------|
| 生产 | `https://chat.pxshe.com` |
| 测试直连 | `http://127.0.0.1:10008` |

> Flutter 客户端在登录完成后会用 IM 长连接：
> - `wss://ws.pxshe.com` （openim-msggateway:10001,SDK 自动连）
> - `https://api.pxshe.com` （openim-api:10002,SDK 内部调）
> 完整后端服务清单见 [SERVICE_INVENTORY.md](SERVICE_INVENTORY.md)。

---

## 2. 拉取注册策略

### 请求

```http
POST https://chat.pxshe.com/business/public/registration/config/get
Content-Type: application/json
operationID: startup-cfg-{ts}
```

```json
{}
```

### 响应

```json
{
  "errorCode": 0,
  "data": {
    "allowRegister": true,
    "availableMethods": ["phone", "email", "username"],
    "privacyPolicyUrl": "https://example.com/privacy",
    "userAgreementUrl": "https://example.com/terms",
    "updatedAt": "2026-07-01T07:25:56+08:00"
  }
}
```

### 字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| `allowRegister` | bool | **总开关**:`false` 时 Flutter 不显示注册入口,只能登录 |
| `availableMethods` | string[] | 当前允许的注册方式列表。**Flutter 根据此动态渲染表单** |
| `privacyPolicyUrl` | string | ⚠️ **deprecated** - 改用 `privacyPolicyMarkdown` |
| `userAgreementUrl` | string | ⚠️ **deprecated** - 改用 `userAgreementMarkdown` |
| `privacyPolicyMarkdown` | string | **隐私政策 Markdown 内容**(推荐)。空字符串 = 未配置 |
| `privacyPolicyVersion` | int | 隐私政策当前版本号(每次修改内容 +1) |
| `privacyPolicyUpdatedAt` | string | 隐私政策最后更新时间 |
| `userAgreementMarkdown` | string | **用户协议 Markdown 内容**(推荐) |
| `userAgreementVersion` | int | 用户协议当前版本号 |
| `userAgreementUpdatedAt` | string | 用户协议最后更新时间 |
| `updatedAt` | string | 整个 config 最后更新时间 |

### 隐私协议版本控制(GDPR 合规)

**对标成熟项目做法**(微信/支付宝等):

- 协议内容用 Markdown(不依赖外链,合规可审计)
- 每次修改内容 → 版本号自动 +1
- Flutter 端提交注册时必须传**当时同意的版本号**
- 服务端对比当前版本,**老版本同意会被拒绝**,提示"协议已更新,请重新阅读"

**Flutter 端实现**:
1. 启动时调 `/business/public/registration/config/get` 拉配置
2. 注册页用 `flutter_markdown` 包渲染 `privacyPolicyMarkdown` / `userAgreementMarkdown`
3. 用户勾选同意时,把**当前版本号**一起提交
4. 后端校验 `privacyAccepted=true` + `privacyPolicyVersion == 当前版本号`

### 方法枚举

| 值 | 对应字段 | 注册请求必填 |
|----|----------|---------------|
| `phone` | `user.phoneNumber` + `user.areaCode` | ✅ |
| `email` | `user.email` | ✅ |
| `username` | `user.account`(用户名) | ✅ |

⚠️ **后端判断方式优先级**:phone > email > username(谁先填就用谁的方式)。
如果三个都填,按 phone → email → username 顺序判断。

---

## 3. 注册请求

### 请求

```http
POST https://chat.pxshe.com/account/register
Content-Type: application/json
operationID: register-{ts}
```

### 手机号注册(availableMethods 包含 phone)

```json
{
  "user": {
    "phoneNumber": "13900000001",
    "areaCode": "+86",
    "nickname": "小明",
    "password": "Test123456"
  },
  "verifyCode": "666666",
  "platform": 2,
  "autoLogin": true,
  "privacyAccepted": true,
  "privacyPolicyVersion": 1,
  "userAgreementVersion": 1
}
```

⚠️ **`privacyPolicyVersion` 和 `userAgreementVersion` 必须传**,值是用户当时同意的版本号。
后端会校验:如果用户传的版本 < 当前版本 → 拒绝(GDPR 合规)。

### 邮箱注册(availableMethods 包含 email,✅ 后端已实现)

```json
{
  "user": {
    "email": "test@example.com",
    "nickname": "小明",
    "password": "Test123456"
  },
  "platform": 2,
  "autoLogin": true,
  "privacyAccepted": true,
  "privacyPolicyVersion": 1,
  "userAgreementVersion": 1
}
```

⚠️ **当前实现状态**:
- ✅ 手机号注册:已实现。需要 `verifyCode` 验证码。
- ✅ 邮箱注册:已实现。需要 `verifyCode` 验证码(由 SMTP 邮件发送)。
- ✅ 用户名注册:已实现。**不校验验证码**(无手机/邮箱可发送)。密码明文存储于 mongo(建议后续改 bcrypt)。
- ✅ 阿里云 SMS 已集成(`pkg/sms/ali.go`),配置 admin 后台"通知服务"页填写 AccessKey 即可
- ✅ SMTP 邮件已集成(`pkg/email/mail.go`),配置 admin 后台填写 SMTP 即可
- ⚠️ 测试/开发环境:SMS/Mail 未配置时,**默认走 superCode 模式**(`verifyCode="666666"` 通过)
- ⚠️ 生产环境:**必须在 admin 后台"通知服务"页填写真实凭证**,否则验证码发不出去

### 用户名注册(availableMethods 包含 username)

```json
{
  "user": {
    "account": "testuser01",
    "nickname": "小明",
    "password": "Test123456"
  },
  "platform": 2,
  "autoLogin": true,
  "privacyAccepted": true,
  "privacyPolicyVersion": 1,
  "userAgreementVersion": 1
}
```

⚠️ username 3-20 位,字母/数字/下划线。不校验验证码。

### 响应(成功)

```json
{
  "errorCode": 0,
  "data": {
    "userID": "3370159211",
    "chatToken": "eyJhbGc...",
    "imToken": "eyJhbGc..."
  }
}
```

⚠️ Flutter 注册成功后**直接登录**,无需再调 `/account/login`。

---

## 4. 错误码速查

完整错误码对照表见 [docs/ERROR_CODES.md](ERROR_CODES.md)。注册相关错误详见该文档第四、五章。

---

## 5. Flutter 集成流程

### 5.1 App 启动

```dart
// lib/services/registration_config.dart
class RegistrationConfig {
  final bool allowRegister;
  final List<String> availableMethods;
  final String privacyPolicyMarkdown;
  final int privacyPolicyVersion;
  final DateTime? privacyPolicyUpdatedAt;
  final String userAgreementMarkdown;
  final int userAgreementVersion;
  final DateTime? userAgreementUpdatedAt;

  RegistrationConfig({
    required this.allowRegister,
    required this.availableMethods,
    required this.privacyPolicyMarkdown,
    required this.privacyPolicyVersion,
    this.privacyPolicyUpdatedAt,
    required this.userAgreementMarkdown,
    required this.userAgreementVersion,
    this.userAgreementUpdatedAt,
  });

  bool get hasPhone => availableMethods.contains('phone');
  bool get hasEmail => availableMethods.contains('email');
  bool get hasUsername => availableMethods.contains('username');
  bool get hasPrivacyPolicy => privacyPolicyMarkdown.isNotEmpty;
  bool get hasUserAgreement => userAgreementMarkdown.isNotEmpty;

  factory RegistrationConfig.fromJson(Map<String, dynamic> json) {
    return RegistrationConfig(
      allowRegister: json['allowRegister'] ?? false,
      availableMethods: List<String>.from(json['availableMethods'] ?? []),
      privacyPolicyMarkdown: json['privacyPolicyMarkdown'] ?? '',
      privacyPolicyVersion: json['privacyPolicyVersion'] ?? 0,
      privacyPolicyUpdatedAt: json['privacyPolicyUpdatedAt'] != null
          ? DateTime.parse(json['privacyPolicyUpdatedAt']) : null,
      userAgreementMarkdown: json['userAgreementMarkdown'] ?? '',
      userAgreementVersion: json['userAgreementVersion'] ?? 0,
      userAgreementUpdatedAt: json['userAgreementUpdatedAt'] != null
          ? DateTime.parse(json['userAgreementUpdatedAt']) : null,
    );
  }
}

class RegistrationConfigService {
  RegistrationConfig? _config;

  RegistrationConfig? get config => _config;

  Future<void> loadFromServer() async {
    final res = await Dio().post(
      'https://chat.pxshe.com/business/public/registration/config/get',
      options: Options(headers: {
        'Content-Type': 'application/json',
        'operationID': 'startup-cfg-${DateTime.now().millisecondsSinceEpoch}',
      }),
    );
    _config = RegistrationConfig.fromJson(res.data['data']);
  }

  bool get canRegister => _config?.allowRegister ?? false;
}
```

### 5.2 注册页动态渲染

```dart
// lib/pages/register_page.dart
class RegisterPage extends StatefulWidget { ... }

class _RegisterPageState extends State<RegisterPage> {
  final cfg = RegistrationConfigService();
  bool privacyChecked = false;

  @override
  Widget build(BuildContext context) {
    final config = cfg.config;
    if (config == null) return CircularProgressIndicator();
    if (!config.allowRegister) {
      return Text('注册功能已被管理员关闭');
    }

    return Column(children: [
      if (config.hasPhone) PhoneInput(...),
      if (config.hasEmail) EmailInput(...),
      if (config.hasUsername) UsernameInput(...),

      if (config.hasPrivacyPolicy || config.hasUserAgreement) ...[
        Row(children: [
          Checkbox(
            value: privacyChecked,
            onChanged: (v) => setState(() => privacyChecked = v ?? false),
          ),
          Expanded(child: Text('我已阅读并同意')),
          if (config.hasUserAgreement)
            TextButton(
              onPressed: () => launchUrl(Uri.parse(config.userAgreementUrl)),
              child: Text('《用户协议》'),
            ),
          if (config.hasPrivacyPolicy)
            TextButton(
              onPressed: () => launchUrl(Uri.parse(config.privacyPolicyUrl)),
              child: Text('《隐私政策》'),
            ),
        ]),
      ],

      ElevatedButton(
        onPressed: privacyChecked || !config.hasPrivacyPolicy && !config.hasUserAgreement
            ? _submit : null,
        child: Text('注册'),
      ),
    ]);
  }

  Future<void> _submit() async {
    final res = await Dio().post(
      'https://chat.pxshe.com/account/register',
      data: {
        'user': {
          if (cfg.config!.hasPhone) 'phoneNumber': phoneCtrl.text,
          if (cfg.config!.hasPhone) 'areaCode': '+86',
          if (cfg.config!.hasEmail) 'email': emailCtrl.text,
          if (cfg.config!.hasUsername) 'account': usernameCtrl.text,
          'nickname': nicknameCtrl.text,
          'password': passwordCtrl.text,
        },
        'verifyCode': '666666',  // superCode(测试固定值,未来替换为 SMS)
        'platform': 2,
        'autoLogin': true,
        'privacyAccepted': privacyChecked,
        // ⚠️ 必须传用户当时同意的版本号(GDPR 合规)
        'privacyPolicyVersion': cfg.config!.privacyPolicyVersion,
        'userAgreementVersion': cfg.config!.userAgreementVersion,
      },
      options: Options(headers: {
        'operationID': 'register-${DateTime.now().millisecondsSinceEpoch}',
      }),
    );

    if (res.data['errorCode'] == 0) {
      // 注册成功 → 直接登录
      final token = res.data['data']['chatToken'];
      await saveToken(token);
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.data['errMsg'] ?? '注册失败')),
      );
    }
  }
}
```

### 5.3 渲染 Markdown 隐私协议(flutter_markdown)

在注册页同意条款时,**用 `flutter_markdown` 包渲染后端返回的 Markdown 内容**:

```yaml
# pubspec.yaml
dependencies:
  flutter_markdown: ^0.7.0
```

```dart
// lib/pages/register_page.dart
import 'package:flutter_markdown/flutter_markdown.dart';

class _PrivacySection extends StatelessWidget {
  final RegistrationConfig config;
  final ValueChanged<bool> onAgree;

  const _PrivacySection({required this.config, required this.onAgree});

  @override
  Widget build(BuildContext context) {
    // 隐私政策 + 用户协议 一起渲染
    final fullText = '''
# 隐私政策 (v${config.privacyPolicyVersion})

${config.privacyPolicyMarkdown}

---

# 用户协议 (v${config.userAgreementVersion})

${config.userAgreementMarkdown}
    ''';

    return ExpansionPanelList(
      children: [
        ExpansionPanel(
          headerBuilder: (_, __) => ListTile(title: Text('阅读隐私政策与用户协议')),
          body: Padding(
            padding: EdgeInsets.all(16),
            child: Container(
              height: 400,  // 限制高度,内部可滚动
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: MarkdownBody(
                  data: fullText,
                  // 样式自己调
                ),
              ),
            ),
          ),
          isExpanded: false,
        ),
      ],
    );
  }
}

// 注册时传版本号
Future<void> _submit() async {
  // ...
  await Dio().post(
    'https://chat.pxshe.com/account/register',
    data: {
      // ...
      'privacyAccepted': _agreed,
      'privacyPolicyVersion': config.privacyPolicyVersion,
      'userAgreementVersion': config.userAgreementVersion,
    },
  );
}
```

### 5.4 错误处理建议

```dart
void _handleRegisterError(int code, String msg) {
  // 策略类错误 → 重新拉配置(可能 admin 后台刚改了开关)
  if (msg.contains('已被关闭') || msg.contains('已被管理员关闭')) {
    cfg.loadFromServer();  // 重新拉策略
    showSnackBar('注册方式已变更,请刷新页面');
    return;
  }
  if (msg.contains('请先阅读并同意')) {
    setState(() => privacyChecked = false);
    showSnackBar('请勾选隐私协议');
    return;
  }
  showSnackBar(msg);
}
```

---

## 6. admin 后台 SMS / SMTP 通知服务配置

### 6.1 进入配置页
- 路径:`/notification-config`
- 菜单:左侧"通知服务"入口

### 6.2 配置 SMS(阿里云)
字段(必填):
- `endpoint`: `dysmsapi.aliyuncs.com`
- `accessKeyId`: 阿里云 AccessKey ID
- `accessKeySecret`: 阿里云 AccessKey Secret
- `signName`: 短信签名(如"我的APP")
- `verificationCodeTemplateCode`: 阿里云短信模板 ID,模板中需含 `${code}` 占位符

保存后系统会自动:
1. 写入 postgres `notification_config` 表
2. 同步生成 `chat/config/chat-rpc-chat.yml` 的 `verifyCode.phone.ali` 段
3. **需要手动重启 chat-rpc 才能生效**:
   ```bash
   # 杀掉旧 chat-rpc
   kill $(ss -tlnp | grep :30300 | grep -oP 'pid=\K\d+')
   # 启动新 chat-rpc
   nohup /www/wwwroot/openim-stack/chat/_output/bin/platforms/linux/amd64/chat-rpc \
     -i 0 -c /www/wwwroot/openim-stack/chat/config/ &
   ```

### 6.3 配置 SMTP(邮箱验证码)
字段(必填):
- `enable`: true 启用 / false 禁用
- `smtpAddr`: SMTP 服务器(如 `smtp.qq.com` / `smtp.gmail.com` / `smtp.163.com`)
- `smtpPort`: SSL 用 465 / STARTTLS 用 587 / 明文用 25
- `senderMail`: 发件人邮箱
- `senderAuthorizationCode`: **SMTP 授权码**(QQ/163/Gmail 的"授权码",不是登录密码!)
- `title`: 邮件主题(默认 "Verification Code")

保存后同样需要重启 chat-rpc 生效。

### 6.4 工作模式
- **未配置 SMS + 未配置 Mail**:走 superCode 模式,验证码 = `"666666"`(仅测试用)
- **只配 SMS**:手机号注册走阿里云,邮箱注册仍走 superCode
- **只配 Mail**:邮箱注册走 SMTP,手机号注册仍走 superCode
- **SMS + Mail 都配**:手机号 + 邮箱注册都走真服务

⚠️ **username 注册**永远不校验验证码(没有发送通道),仅校验密码。

---

## 7. 隐私策略(对标成熟项目做法)

### 7.1 当前实现(最小方案)

| 维度 | 实现 |
|------|------|
| URL 配置 | admin 后台维护两个 URL,持久化到数据库 |
| 用户确认 | Flutter 注册页强制勾选 "我已阅读并同意" |
| 后端校验 | `privacyAccepted=false` 直接拒绝 |
| 协议内容 | 外链(指向 web 页面) |

### 7.2 当前未实现(后续可补)

| 维度 | 成熟项目做法 | 当前状态 |
|------|-------------|----------|
| SMS 真发送 | 接阿里云/Twilio | ❌ 用 superCode 硬编码 |
| 邮箱验证邮件 | 发激活链接 | ❌ 暂未实现 |
| 账号注销 | GDPR Right to Erasure | ❌ 暂未实现 |
| 数据导出 | GDPR Right to Access | ❌ 暂未实现 |
| 注册频率限制 | 防刷 | ❌ 暂未实现 |
| 图形验证码 | 防机器人 | ❌ 暂未实现 |
| 协议版本控制 | 记录用户同意时的版本号 | ❌ 暂未实现 |

---

## 8. 数据流图

```
┌──────────────┐                    ┌──────────────┐
│  admin 后台  │  PUT (超管操作)    │              │
│  (admin-api) │ ──────────────────▶│  postgres    │
│              │                    │  pxshe_business
└──────────────┘                    │  registration_config
                                    │              │
┌──────────────┐  GET 公开          │              │
│ Flutter 客户端│ ────────────────▶ │              │
│  (chat-api)  │                    └──────────────┘
│              │                           ▲
│              │    POST /register         │
│              │ ─────────────────────────▶│ chat-api
│              │    (查 config + 校验)     │ checkRegisterPolicy
└──────────────┘                           │
                                          ▼
                                    chat-rpc.RegisterUser
                                    (chat-rpc 内部逻辑)
```

---

## 9. 接口 URL 速查表

```
# 公开(无 token)
POST https://chat.pxshe.com/business/public/registration/config/get

# 注册(无 token,但带策略校验)
POST https://chat.pxshe.com/account/register
```

---

## 10. 关键约束

1. **Flutter 启动必须拉 config**:不要硬编码注册页 UI
2. **字段顺序很重要**: 后端判断 phone → email → username 优先级
3. **隐私勾选**: 后端只在 URL 非空时校验,URL 空时不强制
4. **错误信息要透传**: Flutter 直接显示后端 errMsg,做策略类错误特殊处理
5. **superCode**: 测试时写死 "666666",生产应替换为 SMS 验证码(未来工作)
6. **重启配置无需重启服务**: 改 admin 后台 → Flutter 下次启动自动拉新值

---

## 11. 已实现(本轮)+ 待确认事项(后续迭代)

### ✅ 已实现
- [x] 邮箱注册后端实现(chat-rpc.RegisterUser + chat-api checkRegisterPolicy)
- [x] 用户名注册后端实现(`account` 字段)
- [x] 阿里云 SMS 集成(`pkg/sms/ali.go` 已就绪,admin 后台"通知服务"页可配)
- [x] SMTP 邮件集成(`pkg/email/mail.go` 已就绪,admin 后台"通知服务"页可配)
- [x] admin 后台"SMS / SMTP 通知服务"配置页(整合到 `/register-management?tab=notification`)
- [x] **隐私协议 Markdown 内容 + 版本号管理**(GDPR 合规)
  - 数据库字段:`privacy_policy_markdown`, `privacy_policy_version`, `privacy_policy_updated_at`
  - 同理 `user_agreement_*` 三个字段
  - 每次保存若内容变化,版本号自动 +1
  - chat-api register 校验:老版本同意会被强制重新同意
  - admin 前端用 `<Input.TextArea>` 编辑(支持 Markdown 语法)
  - Flutter 端用 `flutter_markdown` 包渲染(文档 §5.3)
- [x] 三级菜单整合(9 个分组,注册类统一到 `/register-management`)
- [x] 隐私 URL 老字段保留(向后兼容,但 deprecated)

### 待办
- [ ] 注册频率限制(防刷)
- [ ] 密码加密(目前 username 明文存储,Flutter 用户也是明文)
- [ ] 找回密码流程(username 注册没邮箱/手机,无法找回)

---

文档结束。后端实现位置:

### 注册策略模块
- Repository: `chat/pkg/common/db/business/repository.go:362`
- Model: `chat/pkg/common/db/business/registration_config.go`
- admin Handler: `chat/internal/api/admin/business/config_handler.go`
- chat Handler: `chat/internal/api/chat/business.go`(GetRegistrationConfig)

### 通知服务模块
- Model: `chat/pkg/common/db/business/notification_config.go`
- admin Handler: `chat/internal/api/admin/business/notification_handler.go`
- 前端页: `chat/web/src/pages/NotificationConfig.tsx`
- 阿里云 SMS: `chat/pkg/sms/ali.go`(原生 OpenIM)
- SMTP 邮件: `chat/pkg/email/mail.go`(原生 OpenIM)

### proto 改动
- `chat/pkg/protocol/chat/chat.go`:`RegisterUserReq.Check()` / `LoginReq.Check()` 支持 username (`x.Account`)
- chat 注册校验: `chat/internal/api/chat/chat.go:checkRegisterPolicy`