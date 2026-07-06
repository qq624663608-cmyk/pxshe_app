# 宇宙模块前端对接清单 (Frontend Integration Checklist)

> 本文档用 **Checklist** 形式,前端工程师每完成一项打勾即可
> 配合 `UNIVERSE_API.md` 使用(那份是字段参考手册)
> 所有代码示例以 **Flutter / Dart** 为主

---

## ⚠️ 三域架构(必读,版本 v2)

**Flutter 客户端调的是 `chat.pxshe.com`,不是 `admin.pxshe.com`。**

```
https://api.pxshe.com      → openim-server  (反代: 443 → 10002)  IM 核心 (被 SDK 调用,禁直连)
https://chat.pxshe.com     → chat-api       (反代: 443 → 10008)  ✅ Flutter 客户端走这个
https://admin.pxshe.com    → admin-api      (反代: 443 → 10009)  超管用,Flutter 不应该用
```

**重要**: 客户端**不带端口**,全走 443 反代。直接 `:10002` 写 SDK 不会走反代,会被 GFW 拦 (海外主机常见)。

| Flutter 客户端业务 | 走哪个域 | 方式 |
|--------------------|---------|------|
| 用户登录/注册 | `chat.pxshe.com` | HTTP 调 `/account/login` 等 |
| IM 消息收发 | SDK 自动 | `openim-sdk-flutter` 内部连 openim-api |
| **宇宙业务 CRUD** | `chat.pxshe.com` | HTTP 调 `/business/universe/*` |
| 直接 HTTP 调 openim-api | ❌ 禁止直连 | (反代 443) |

⚠️ **历史说明**: 早期版本误把所有 URL 写成 `admin.pxshe.com`,已修正。**所有 Flutter 端调用必须改成 `https://chat.pxshe.com/business/*`**。

📘 **完整 Flutter 端 API 列表**见 `chat/docs/UNIVERSE_API.md` 的 **F 章**(Flutter 用户专属 RPC),里面有 `/business/universe/list`、`list_mine`、`find`、`add`、`update`、`del` 和所有 `table/row` 接口的字段说明 + 权限规则。

---

## 0. 文档约定

- ✅ Checklist 项,完成打勾
- ⚠️ 容易踩的坑,必读
- 🔧 代码片段,直接复制用
- 📞 不知道问谁:找后端 DBA 或 OpenIM 群

---

## 1. 快速上手 Checklist (10 分钟跑通)

目标:**5 步完成"登录 → 建世界 → 建子表 → 加数据 → 显示"**

```
[ ] 1.1 用普通用户账号登录(phoneNumber + password),拿到 userToken / chatToken
[ ] 1.2 调 /business/universe/add 创建第一个测试世界
[ ] 1.3 调 /business/table/create 在该世界下建一个名为 weapon 的子表
[ ] 1.4 调 /business/row/add 往 weapon 加一行数据(name=倚天剑, data={attack:999})
[ ] 1.5 调 /business/row/list 验证能查出刚才加的那行
```

### 1.1 关键概念理解

```
宇宙(universe) = 一本书 / 一个世界
  ↓
子表(table) = 这个世界里的一种数据集合(用户自己起名,如 weapon / character / city)
  ↓
行(row) = 子表里的具体一条数据,有 name 和 data(JSON)两个字段
```

### 1.2 三条铁律

⚠️ **规则 1**: 每个世界完全独立,跨世界**看不到**对方的数据
⚠️ **规则 2**: 子表名只能是**英文/数字/下划线**,长度 1-50,大小写敏感
⚠️ **规则 3**: 每个 HTTP 请求必须带 `token` 和 `operationID` 两个 header

---

## 2. 登录鉴权 Checklist

### 2.1 调用接口

- URL: `POST https://chat.pxshe.com/account/login`
- 需要鉴权: **否**(这是拿 token 的接口)
- Content-Type: `application/json`
- operationID: 需要(任意唯一字符串)
- ⚠️ **这是普通用户登录,不是 admin 登录**(admin 用 `admin.pxshe.com/account/login`)

### 2.2 请求体

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| phoneNumber | string | ✅ | 普通用户手机号 |
| areaCode | string | ✅ | 区号,如 `+86` |
| password | string | ✅ | 用户密码(明文,前端不要做 md5)|
| platform | number | ✅ | 平台:1=iOS 2=Android 3=Windows ... |

### 2.3 响应处理

```
成功(errCode=0):
  data.chatToken = "eyJhbGciOiJIUzI1NiIs..."  ← 必须存到本地(普通用户 token, UserType=1)
  data.userID = "3370159211"                  ← 当前登录用户的 ID
  data.imToken = "eyJhbGciOiJIUzI1NiIs..."    ← IM SDK 用(也存本地)

失败(errCode=20001/20002):
  phoneNumber 或密码错误,弹 toast 提示
```

### 2.4 前端要做的事

```
[ ] 2.4.1 启动 App 时先读本地缓存的 chatToken + userId,如果有就不重新登录
[ ] 2.4.2 如果没有 token,弹登录页(phoneNumber + password + 登录按钮)
[ ] 2.4.3 登录成功后,把 chatToken + userId 存到本地(SharedPreferences / local_storage)
[ ] 2.4.4 后续所有 /business/* 请求,自动在 header 里加 token: <chatToken>
[ ] 2.4.5 每个请求同时生成唯一 operationID,推荐格式 <业务>-<时间戳>-<随机数>
[ ] 2.4.6 任何接口返回 401(token 失效),自动清 token + 跳登录页
```

### 2.5 容易踩的坑

⚠️ **密码不要做 md5**: Flutter 端登录密码明文传输(只有 admin 后台 Web 登录页会做 md5,因为是早期代码)
⚠️ **token 必须 header 带**: 不能放 body,不能放 query string
⚠️ **operationID 必须全局唯一**: 不能两次请求用同一个 ID(后端用这个做幂等/日志去重)
⚠️ **token 名是 `chatToken` 不是 `adminToken`**: 字段名别搞混

### 2.6 Flutter 代码片段 🔧

```dart
// lib/api/auth.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

// 注意:Flutter 客户端登录走 chat.pxshe.com,不是 admin.pxshe.com
// 这里 chatToken 是普通用户 token(调 /account/login 或 /account/register)
class AuthService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://chat.pxshe.com',     // ⚠️ chat 域,不是 admin
    contentType: 'application/json',
  ));
  String? _chatToken;
  String? _userId;

  String? get token => _chatToken;
  String? get userId => _userId;

  // 1.4.1 启动时尝试恢复 token
  Future<void> loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    _chatToken = prefs.getString('chatToken');
    _userId = prefs.getString('userId');
    if (_chatToken != null) _dio.options.headers['token'] = _chatToken;
  }

  // 1.4.2/3 普通用户登录(phoneNumber + password)
  Future<bool> login(String areaCode, String phoneNumber, String password) async {
    final res = await _dio.post('/account/login', data: {
      'areaCode': areaCode,        // 如 "+86"
      'phoneNumber': phoneNumber,  // 如 "13900000001"
      'password': password,        // 明文
      'platform': 2,               // 2=Android,1=iOS 等
    });
    if (res.data['errCode'] != 0) {
      throw Exception(res.data['errMsg']);
    }
    _chatToken = res.data['data']['chatToken'];
    _userId = res.data['data']['userID'];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chatToken', _chatToken!);
    await prefs.setString('userId', _userId!);
    _dio.options.headers['token'] = _chatToken;
    return true;
  }

  // 1.4.5 生成 operationID(全局唯一)
  String newOpId(String biz) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = (ts % 9999).toString().padLeft(4, '0');
    return '$biz-$ts-$rand';
  }
}
```

---

## 3. 世界列表功能 Checklist

⚠️ **Flutter 端用 `/business/universe/list`**(返回公开世界 + 自己的私有世界),不是超管的 `/universe/search`。
⚠️ Flutter 端如果只想看自己创建的世界,用 `/business/universe/list_mine`(详见 UNIVERSE_API.md F.3)。

### 3.1 调用接口

- URL: `POST https://chat.pxshe.com/business/universe/list`
- 需要鉴权: ✅ 普通用户 token
- Header: token + operationID

### 3.2 请求体

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| keyword | string | - | 模糊搜名称或简介,**空字符串**=全部 |
| page | number | - | 默认 1 |
| size | number | - | 默认 20,最大 200 |

### 3.3 响应处理

```
成功:
  data.total = 5           ← 总数(用于分页)
  data.list = [{           ← 数组,每条是一个世界
    id: 1,
    name: "...",
    summary: "...",
    coverUrl: "...",
    creatorId: "...",
    visibility: "public" | "private",  ← 公开/私有
    createdAt: "2026-07-01T..."   ← ISO 8601 字符串
  }]
  data.currentUid = "3370159211"  ← 当前登录用户(用于前端判断是不是自己创建的)
```

### 3.4 前端要做的事

```
[ ] 3.4.1 列表页进入时,立刻调一次 list 接口(size=20)
[ ] 3.4.2 把返回的 list 渲染成卡片,每张卡片显示:
         - 封面图(优先 coverUrl,无则显示默认图标)
         - 名称(标题)
         - 简介(单行截断,超出...省略)
         - 作者(显示 creatorId)
         - 创建时间(右下角小字)
         - 可见性 Tag(public=绿色 / private=橙色)
[ ] 3.4.3 顶部搜索框支持按名称模糊查,输入时 debounce 500ms 再发请求
[ ] 3.4.4 列表支持下拉刷新 + 上拉加载更多(用 page + size)
[ ] 3.4.5 显示当前共 N 个宇宙(用 total)
[ ] 3.4.6 空状态:显示 "还没有世界" + "新建第一个" 按钮
[ ] 3.4.7 点击卡片 → 跳转世界详情页(传 universeId)
```

### 3.5 容易踩的坑

⚠️ **list 返回的包含所有人的公开世界 + 自己的私有世界**,不是只显示自己创建的(那是 `list_mine`)
⚠️ **coverUrl 可能为空字符串或 null**,显示前必须判断
⚠️ **createdAt 是 ISO 字符串**(如 `"2026-07-01T10:30:00+08:00"`),Flutter 用 `DateTime.parse()` 转 DateTime
⚠️ **summary 可能超长**,卡片展示要单行截断,详情页才显示全
⚠️ **搜索 keyword 空字符串** = 查全部,不要传 null

### 3.6 Flutter 代码片段 🔧

```dart
// lib/pages/universe_list_page.dart
class UniverseListPage extends StatefulWidget {
  @override
  _UniverseListPageState createState() => _UniverseListPageState();
}

class _UniverseListPageState extends State<UniverseListPage> {
  final auth = AuthService();  // 单例
  List universes = [];
  int total = 0;
  String keyword = '';
  bool loading = false;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() => loading = true);
    final dio = Dio(BaseOptions(
      baseUrl: 'https://chat.pxshe.com',  // ⚠️ Flutter 用 chat.pxshe.com,不是 admin
      headers: {
        'token': auth.token ?? '',
        'Content-Type': 'application/json',
      },
    ));
    final res = await dio.post('/business/universe/list', data: {
      'keyword': keyword,
      'page': 1,
      'size': 20,
    }, options: Options(headers: {'operationID': auth.newOpId('search')}));
    setState(() {
      universes = res.data['data']['list'];
      total = res.data['data']['total'];
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('宇宙 (共 $total)'),
        actions: [IconButton(icon: Icon(Icons.refresh), onPressed: fetchData)],
      ),
      body: loading
        ? Center(child: CircularProgressIndicator())
        : universes.isEmpty
          ? Center(child: Text('还没有世界'))
          : ListView.builder(
              itemCount: universes.length,
              itemBuilder: (ctx, i) {
                final u = universes[i];
                return Card(
                  child: ListTile(
                    leading: (u['coverUrl'] ?? '').isNotEmpty
                      ? Image.network(u['coverUrl'], width: 48, height: 48, fit: BoxFit.cover)
                      : Icon(Icons.public, size: 48),
                    title: Text(u['name']),
                    subtitle: Text(u['summary'] ?? ''),
                    trailing: Text(DateTime.parse(u['createdAt']).toString().substring(0, 10)),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => UniverseDetailPage(universeId: u['id']),
                      ));
                    },
                  ),
                );
              },
            ),
    );
  }
}

---

## 4. 创建世界 Checklist

### 4.1 调用接口

- URL: `POST https://chat.pxshe.com/business/universe/add`
- 需要鉴权: ✅

### 4.2 请求体

| 字段 | 类型 | 必填 | 校验 | 说明 |
|------|------|------|------|------|
| name | string | ✅ | 1-200 字符 | 世界名称 |
| summary | string | - | <= 2000 字符 | 简介(可不填) |
| coverUrl | string | - | <= 500 字符,合法 URL | 封面图 URL(可不填) |
| creatorId | string | ✅ | <= 64 字符 | 作者 userID |

### 4.3 响应处理

```
成功:
  data.id = 15    ← 新世界的 ID(关键!后续所有操作都靠这个 ID)
  data.createdAt = "2026-07-01T..."

失败(errCode=400):
  通常是 name 或 creatorId 没填,弹 toast 提示
```

### 4.4 前端要做的事

```
[ ] 4.4.1 列表页右上角放"新建世界"按钮(主操作按钮,蓝色)
[ ] 4.4.2 点按钮 → 弹窗 / 跳转新建页(任选,推荐跳转详情页同款表单)
[ ] 4.4.3 表单字段:
         - 名称 *(必填,1-200 字符)
         - 简介 (选填,提示"2000 字以内")
         - 封面 URL (选填,提示"粘贴图片地址")
         - 作者 userID *(必填,可提供一个下拉建议列表)
[ ] 4.4.4 提交前先前端校验(必填 / 长度),避免无效请求
[ ] 4.4.5 提交时按钮变 loading 态(防重复提交)
[ ] 4.4.6 成功后:
         - 弹 "世界已创建" 成功 toast
         - 自动跳到世界详情页(传新拿到的 ID)
         - 让用户立即能继续建子表
[ ] 4.4.7 失败时:
         - 弹具体错误信息(toast)
         - 表单不关闭,让用户改完再提交
```

### 4.5 容易踩的坑

⚠️ **creatorId 不要写 "admin"**: 后端期望的是聊天系统的 userID(如 `user_001` / `imAdmin`),不是管理后台账号
⚠️ **创建后立刻要保存 ID**: 后续建子表/加数据全部要传这个 ID
⚠️ **封面 URL 不要传 base64 图片**: 必须是 https/http 开头的可访问 URL
⚠️ **名称长度限制 200**: 后端会校验,前端要软提示

### 4.6 Flutter 代码片段 🔧

```dart
// lib/pages/universe_create_page.dart
class UniverseCreatePage extends StatefulWidget {
  @override
  _UniverseCreatePageState createState() => _UniverseCreatePageState();
}

class _UniverseCreatePageState extends State<UniverseCreatePage> {
  final _formKey = GlobalKey<FormState>();
  bool saving = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      final dio = Dio(BaseOptions(baseUrl: 'https://chat.pxshe.com'));  // ⚠️ chat 域,不是 admin
      final res = await dio.post('/business/universe/add',
        options: Options(headers: {
          'token': AuthService().token ?? '',  // 普通用户 chatToken
          'operationID': AuthService().newOpId('uni-add'),
        }),
        data: {
          'name': _nameCtrl.text,
          'summary': _summaryCtrl.text,
          'coverUrl': _coverCtrl.text,
          // ⚠️ 注意:不要传 creatorId!后端从 token 自动拿当前 userID
          // 改成传 visibility 字段(public / private)
          'visibility': 'public',
        },
      );
      if (res.data['errCode'] != 0) throw Exception(res.data['errMsg']);
      final newId = res.data['data']['id'];
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => UniverseDetailPage(universeId: newId),
      ));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('世界已创建')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('创建失败: $e')));
    } finally {
      setState(() => saving = false);
    }
  }
}
```

---

## 5. 编辑世界 Checklist

### 5.1 调用接口(2 个)

**进入页面**(读):
- URL: `POST https://chat.pxshe.com/business/universe/find`
- 请求体: `{ "id": 15 }`

**保存修改**(写):
- URL: `POST https://chat.pxshe.com/business/universe/update`
- 请求体(只传要改的字段):
  ```json
  {
    "id": 15,
    "name": "新名字",
    "summary": "新简介",
    "coverUrl": "...",
    "creatorId": "user_002"
  }
  ```

### 5.2 字段对照(可改 / 只读)

| 字段 | 可改? | 说明 |
|------|-------|------|
| id | ❌ 不可改 | 系统生成,详情页显示为 Tag |
| name | ✅ 可改 | 用户填的 |
| summary | ✅ 可改 | 用户填的 |
| coverUrl | ✅ 可改 | 用户填的 |
| creatorId | ✅ 可改 | 用户填的(允许换作者) |
| createdAt | ❌ 只读 | 系统记录,显示但不可编辑 |

### 5.3 响应处理

```
find 成功:  data.id, data.name, data.summary, data.coverUrl, data.creatorId, data.createdAt
update 成功: data 为空 {} 或 errCode=0 即可
```

### 5.4 前端要做的事

```
[ ] 5.4.1 进入详情页立刻调 /universe/find 拿到当前世界数据
[ ] 5.4.2 把数据填到表单(name/summary/coverUrl/creatorId 4 个输入框)
[ ] 5.4.3 创建时间(createdAt)用只读 TextField 显示 + "只读" Tag 标识
[ ] 5.4.4 用户改完点"保存" → 调 /universe/update(只传改过的字段)
[ ] 5.4.5 保存成功: 弹 toast + 留在当前页(不跳)
[ ] 5.4.6 保存失败: 弹错误信息,保留用户输入
[ ] 5.4.7 详情页顶部可以预览封面(根据 coverUrl 实时显示)
```

### 5.5 容易踩的坑

⚠️ **update 只传改过的字段**: 不需要把所有字段都传,只传修改的就行
⚠️ **update 不返回新数据**: 成功后需要手动 refetch / 刷新 UI
⚠️ **update 也用于新建**: 实际不会,新建走 /add 接口,update 用于编辑已有
⚠️ **表单默认值**: 进入页面要把当前值填到表单,否则用户看到的是空白表单

### 5.6 Flutter 代码片段 🔧

```dart
Future<void> _load() async {
  final res = await Dio().post('https://chat.pxshe.com/business/universe/find',
    options: Options(headers: {
      'token': AuthService().token ?? '',
      'operationID': AuthService().newOpId('uni-find'),
    }),
    data: {'id': widget.universeId},
  );
  final u = res.data['data'];
  _nameCtrl.text = u['name'];
  _summaryCtrl.text = u['summary'] ?? '';
  _coverCtrl.text = u['coverUrl'] ?? '';
  _creatorCtrl.text = u['creatorId'];
  setState(() => _createdAt = u['createdAt']);
}

Future<void> _save() async {
  await Dio().post('https://chat.pxshe.com/business/universe/update',
    options: Options(headers: {
      'token': AuthService().token ?? '',
      'operationID': AuthService().newOpId('uni-update'),
    }),
    data: {
      'id': widget.universeId,
      'name': _nameCtrl.text,
      'summary': _summaryCtrl.text,
      'coverUrl': _coverCtrl.text,
      'creatorId': _creatorCtrl.text,
    },
  );
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已保存')));
}
```

---

## 6. 删除世界 Checklist

### 6.1 调用接口

- URL: `POST https://chat.pxshe.com/business/universe/del`
- 请求体: `{ "id": 15 }`

### 6.2 响应处理

```
成功: errCode=0, data.id = 15
失败(errCode=404): 世界不存在
```

### 6.3 前端要做的事

```
[ ] 6.3.1 详情页顶部放"删除"按钮(红色,危险操作,右上角)
[ ] 6.3.2 点击"删除" → 弹二次确认 Modal:
         - 标题:"确认删除该世界?"
         - 内容: "将同时删除该世界下的所有数据表(武器/角色等),且无法恢复"
         - 确认按钮: 红色 "确认删除"
         - 取消按钮: 灰色 "取消"
[ ] 6.3.3 用户点确认后,调 /universe/del
[ ] 6.3.4 删除中: 按钮变 loading,防止重复点
[ ] 6.3.5 成功后: 弹 "已删除" → 自动跳回列表页
[ ] 6.3.6 失败: 弹错误信息,留在详情页
```

### 6.4 容易踩的坑

⚠️ **删除是不可逆的**: 前端必须有二次确认(不能只点一次就删)
⚠️ **删除会级联 DROP 所有子表**: 必须在确认文案里明确告诉用户
⚠️ **删除后跳转要立刻**: 不要让用户留在已删除的世界页(404 状态)

### 6.5 Flutter 代码片段 🔧

```dart
Future<void> _onDelete() async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('确认删除该世界?'),
      content: Text('将同时删除该世界下的所有数据表(武器/角色等),且无法恢复'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('取消')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: Text('确认删除'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  await Dio().post('https://chat.pxshe.com/business/universe/del',
    options: Options(headers: {
      'token': AuthService().token ?? '',
      'operationID': AuthService().newOpId('uni-del'),
    }),
    data: {'id': widget.universeId},
  );
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已删除')));
  Navigator.pop(context);
}
```

---

## 7. 子表列表 Checklist

### 7.1 调用接口

- URL: `POST https://chat.pxshe.com/business/table/list`
- 请求体: `{ "universeId": 15 }`

### 7.2 响应处理

```
成功:
  data.tables = ["weapon", "character", "city"]
  空数组 = 该世界没建任何子表
```

### 7.3 前端要做的事

```
[ ] 7.3.1 详情页进入时,展示"我的数据表"区块(在 5 字段编辑下方)
[ ] 7.3.2 区块标题旁边显示子表总数 Tag(例:"我的数据表 [3 个]")
[ ] 7.3.3 子表以按钮组或 Tab 形式展示(每个子表名一个按钮)
[ ] 7.3.4 点击某个子表按钮 → 进入该子表的数据管理(见第 10 章)
[ ] 7.3.5 空状态: 显示 "还没有数据表,点击右上角新建数据表开始"
[ ] 7.3.6 子表按钮旁可以有小操作(重命名 / 删除,见第 9 章)
```

### 7.4 容易踩的坑

⚠️ **tables 是字符串数组,不是对象数组**: 每个元素只是子表名字符串
⚠️ **返回空数组 ≠ 接口报错**: 成功但没子表,展示空状态
⚠️ **子表名是用户起的**: 不要假设固定名字
⚠️ **大小写敏感**: weapon ≠ Weapon

### 7.5 Flutter 代码片段 🔧

```dart
Future<List<String>> _loadTables(int universeId) async {
  final res = await Dio().post('https://chat.pxshe.com/business/table/list',
    options: Options(headers: {
      'token': AuthService().token ?? '',
      'operationID': AuthService().newOpId('tbl-list'),
    }),
    data: {'universeId': universeId},
  );
  return List<String>.from(res.data['data']['tables']);
}

Widget _buildTableSelector(List<String> tables, String active, ValueChanged<String> onChange) {
  return Wrap(spacing: 8, children: tables.map((t) => ChoiceChip(
    label: Text(t), selected: t == active, onSelected: (_) => onChange(t),
  )).toList());
}
```

---

## 8. 创建子表 Checklist

### 8.1 调用接口

- URL: `POST https://chat.pxshe.com/business/table/create`
- 请求体: `{ "universeId": 15, "name": "weapon" }`

### 8.2 请求体字段

| 字段 | 类型 | 必填 | 校验 |
|------|------|------|------|
| universeId | number | ✅ | 已存在的世界 ID |
| name | string | ✅ | **英文/数字/下划线,1-50 字符** |

### 8.3 响应处理

```
成功: errCode=0, data.name = "weapon"
失败(400): 表名非法字符 / 超长度
```

### 8.4 前端要做的事

```
[ ] 8.4.1 详情页"我的数据表"区块右上角放"+ 新建数据表"按钮(主操作)
[ ] 8.4.2 点按钮 → 弹窗:
         - 输入框: "表名" (placeholder: "例如 weapon")
         - 提示: "建议命名:weapon / character / city / faqi / level,英文+下划线"
         - 确认按钮: "创建"
[ ] 8.4.3 前端校验(提交前):
         - 不能为空
         - 必须符合正则 ^[A-Za-z0-9_]+$
         - 长度 1-50
[ ] 8.4.4 提交后:
         - 成功: 弹 "创建成功" → 关弹窗 → 刷新列表 → 自动选中新表
         - 失败: 弹具体错误
[ ] 8.4.5 重名校验: 提交前可先调 /table/list 看是否已存在同名子表
```

### 8.5 容易踩的坑

⚠️ **中文表名绝对不行**: 正则只允许 `[A-Za-z0-9_]+`,传中文直接 400
⚠️ **同名子表会报错**: 同一世界下不能有两个同名子表
⚠️ **不要带空格**: `my table` 不行,写 `my_table`

### 8.6 Flutter 代码片段 🔧

```dart
Future<void> _createTable() async {
  final ctrl = TextEditingController();
  final name = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('新建数据表'),
      content: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          hintText: '例如 weapon',
          helperText: '只能英文/数字/下划线,1-50 字符',
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('取消')),
        TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: Text('创建')),
      ],
    ),
  );
  if (name == null || name.isEmpty) return;
  if (!RegExp(r'^[A-Za-z0-9_]+$').hasMatch(name)) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('表名只能英文/数字/下划线')));
    return;
  }
  await Dio().post('https://chat.pxshe.com/business/table/create',
    options: Options(headers: {
      'token': AuthService().token ?? '',
      'operationID': AuthService().newOpId('tbl-create'),
    }),
    data: {'universeId': widget.universeId, 'name': name},
  );
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('创建成功')));
  _loadTables();
}
```

---

## 9. 重命名/删除子表 Checklist

### 9.1 重命名子表

- URL: `POST https://chat.pxshe.com/business/table/rename`
- 请求体: `{ "universeId": 15, "oldName": "weapon", "newName": "weapons" }`
- 响应: 成功 data.name = "weapons",数据**全部保留**
- 注意: newName 也要符合英文/数字/下划线

### 9.2 删除子表

- URL: `POST https://chat.pxshe.com/business/table/delete`
- 请求体: `{ "universeId": 15, "name": "weapon" }`
- 响应: 成功 data.name = "weapon"
- ⚠️ **数据不可恢复**: 子表里所有行都丢

### 9.3 前端要做的事

```
[ ] 9.3.1 每个子表按钮旁边放两个小图标(编辑 + 删除)
[ ] 9.3.2 点编辑图标 → 弹窗让用户输入新名字(预填旧名字)
         - 正则校验
         - 调 /table/rename
         - 成功后刷新列表(选中表也要更新成新名字)
[ ] 9.3.3 点删除图标 → 二次确认弹窗:
         - 标题: "删除数据表 weapon?"
         - 内容: "该表里的所有数据都将丢失,且无法恢复"
         - 确认按钮红色
[ ] 9.3.4 用户确认后调 /table/delete
[ ] 9.3.5 如果删的是当前激活的子表,删后切到列表第一个,或清空选中
```

### 9.4 容易踩的坑

⚠️ **删除不可逆**: 必须二次确认,文案要说清"数据丢失"
⚠️ **重命名不会丢数据**: 但前端必须把当前选中的子表名也更新
⚠️ **newName 不能重名**: 和该世界下其它子表冲突会报错

### 9.5 Flutter 代码片段 🔧

```dart
Future<void> _renameTable(String oldName) async {
  final ctrl = TextEditingController(text: oldName);
  final newName = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('重命名'),
      content: TextField(controller: ctrl),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('取消')),
        TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: Text('确定')),
      ],
    ),
  );
  if (newName == null || newName == oldName) return;
  if (!RegExp(r'^[A-Za-z0-9_]+$').hasMatch(newName)) return;

  await Dio().post('https://chat.pxshe.com/business/table/rename',
    options: Options(headers: {
      'token': AuthService().token ?? '',
      'operationID': AuthService().newOpId('tbl-rename'),
    }),
    data: {'universeId': widget.universeId, 'oldName': oldName, 'newName': newName},
  );
  if (activeTable == oldName) setState(() => activeTable = newName);
  _loadTables();
}

Future<void> _deleteTable(String name) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('删除数据表 "$name"?'),
      content: Text('该表里的所有数据都将丢失,且无法恢复'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('取消')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: Text('确认删除'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  await Dio().post('https://chat.pxshe.com/business/table/delete',
    options: Options(headers: {
      'token': AuthService().token ?? '',
      'operationID': AuthService().newOpId('tbl-del'),
    }),
    data: {'universeId': widget.universeId, 'name': name},
  );
  if (activeTable == name) setState(() => activeTable = '');
  _loadTables();
}
```

---
```

---

## 10. 数据行列表 Checklist

### 10.1 调用接口

- URL: `POST https://chat.pxshe.com/business/row/list`
- 请求体: `{ "universeId": 15, "table": "weapon", "page": 1, "size": 20 }`

### 10.2 请求体字段

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| universeId | number | ✅ | 世界 ID |
| table | string | ✅ | 子表名(英文/数字/下划线) |
| page | number | - | 默认 1 |
| size | number | - | 默认 20 |

### 10.3 响应处理

```
成功:
  data.total = 8   ← 总条数
  data.list = [
    {
      id: 1,
      name: "倚天剑",
      data: {"attack": 999, "skill": "独孤九剑"},
      createdAt: "2026-07-01 10:35:00"
    },
    ...
  ]
  data.page = 1
  data.size = 20
```

### 10.4 前端要做的事

```
[ ] 10.4.1 子表详情区显示当前选中子表的所有行(表格形式)
[ ] 10.4.2 表格列:
         - ID (系统,小字号灰色)
         - 名称 (name)
         - 自定义字段 (data,JSON 格式化展示)
         - 创建时间
         - 操作按钮(编辑 / 删除)
[ ] 10.4.3 顶部加搜索框(按名称过滤,前端本地过滤即可,不需要调接口)
[ ] 10.4.4 表格分页(后端分页,不是前端)
[ ] 10.4.5 显示当前共 N 条(用 total)
[ ] 10.4.6 空状态: "暂无数据,点击右上角添加"
[ ] 10.4.7 data 字段展示方式(二选一):
         - 简单方案:用 JSON 字符串展示(JSON.stringify(data, null, 2))
         - 美化方案:遍历 data key-value,渲染成卡片网格
```

### 10.5 容易踩的坑

⚠️ **data 是对象,不是字符串**: 后端已经返回 JSON 对象,前端不要再 parse
⚠️ **data 可能为 null**: 子表里某些行可能没填 data,前端要兼容空值
⚠️ **data 字段不固定**: 每个世界每个子表的 data key 不一样,前端不要写死字段名
⚠️ **createdAt 是 "2006-01-02 15:04:05" 格式字符串**: 不是 ISO 格式,直接显示即可

### 10.6 Flutter 代码片段 🔧

```dart
Future<void> _loadRows() async {
  final res = await Dio().post('https://chat.pxshe.com/business/row/list',
    options: Options(headers: {
      'token': AuthService().token ?? '',
      'operationID': AuthService().newOpId('row-list'),
    }),
    data: {
      'universeId': widget.universeId,
      'table': widget.activeTable,
      'page': widget.page,
      'size': 20,
    },
  );
  setState(() {
    rows = List<Map>.from(res.data['data']['list']);
    total = res.data['data']['total'];
  });
}

// 表格列定义
DataColumn(_build('ID', width: 50)),
DataColumn(_build('名称')),
DataColumn(_build('自定义字段')),  // 渲染 data JSON
DataColumn(_build('创建时间', width: 150)),
DataColumn(_build('操作', width: 100)),
```

---

## 11. 添加/编辑数据行 Checklist

### 11.1 添加数据行

- URL: `POST https://chat.pxshe.com/business/row/add`
- 请求体:
  ```json
  {
    "universeId": 15,
    "table": "weapon",
    "name": "倚天剑",
    "data": {"attack": 999, "skill": "独孤九剑"}
  }
  ```

### 11.2 编辑数据行

- URL: `POST https://chat.pxshe.com/business/row/update`
- 请求体:
  ```json
  {
    "universeId": 15,
    "table": "weapon",
    "id": 1,
    "name": "倚天剑",
    "data": {"attack": 1500}
  }
  ```

### 11.3 请求体字段

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| universeId | number | ✅ | 世界 ID |
| table | string | ✅ | 子表名 |
| id | number | ✅(只 update 需要)| 要改的行的 ID |
| name | string | ✅ | 数据行的名称 |
| data | object | - | 灵活字段,任意 key-value |

### 11.4 响应处理

```
add 成功: data.id = 123   ← 新行 ID
update 成功: errCode=0, data 为空
```

### 11.5 前端要做的事

```
[ ] 11.5.1 表格上方放"+ 添加数据"按钮
[ ] 11.5.2 点按钮 → 弹窗:
         - 输入框 1: "名称" (必填)
         - 输入框 2: "自定义字段 (JSON)" (选填)
           提示: '例如 {"攻击力": 999, "门派": "剑宗"}'
[ ] 11.5.3 编辑模式(从表格点编辑图标进入):
         - 弹窗预填当前行的 name 和 data
         - 标题改为 "编辑数据 #<id>"
         - 保存按钮文案改 "保存"
[ ] 11.5.4 data 编辑器两种实现(选一种):
         方案 A: JSON TextArea + 实时格式校验(JSON.parse 异常时给红色提示)
         方案 B: 动态生成表单(后端给出 schema,但目前没有 schema,所以用 A)
[ ] 11.5.5 提交时前端校验:
         - name 必填
         - dataJson 如果填了,必须是合法 JSON
[ ] 11.5.6 成功后: 关弹窗 + 刷新列表
[ ] 11.5.7 失败时: 弹错误,留在弹窗
```

### 11.6 容易踩的坑

⚠️ **data 是 JSON 对象,不是字符串**: 前端收集 data 后直接当对象传,不要手动 JSON.stringify
⚠️ **空 data 要传 {}**: 如果用户没填 data,传空对象 `{}`,不要传 null
⚠️ **JSON 格式错就报错**: 前端必须 catch JSON.parse 异常,弹友好提示
⚠️ **id 只在 update 时传**: add 不传 id(后端自增)
⚠️ **name 是必填**: 不传会被后端 400 拒绝

### 11.7 Flutter 代码片段 🔧

```dart
Future<void> _addOrUpdateRow({Map? existing}) async {
  final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
  final dataCtrl = TextEditingController(
    text: existing?['data'] != null ? jsonEncode(existing['data']) : '',
  );
  final saved = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(existing == null ? '添加数据' : '编辑数据 #${existing['id']}'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: InputDecoration(labelText: '名称')),
        SizedBox(height: 8),
        TextField(
          controller: dataCtrl,
          maxLines: 5,
          decoration: InputDecoration(
            labelText: '自定义字段 (JSON)',
            helperText: '例如 {"攻击力": 999, "门派": "剑宗"}',
          ),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('取消')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(existing == null ? '添加' : '保存')),
      ],
    ),
  );
  if (saved != true) return;
  if (nameCtrl.text.isEmpty) return;

  // 解析 data JSON
  Map<String, dynamic> dataObj = {};
  if (dataCtrl.text.trim().isNotEmpty) {
    try {
      dataObj = jsonDecode(dataCtrl.text) as Map<String, dynamic>;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('JSON 格式错误')));
      return;
    }
  }

  if (existing == null) {
    // add
    await Dio().post('https://chat.pxshe.com/business/row/add',
      options: Options(headers: {
        'token': AuthService().token ?? '',
        'operationID': AuthService().newOpId('row-add'),
      }),
      data: {
        'universeId': widget.universeId,
        'table': widget.activeTable,
        'name': nameCtrl.text,
        'data': dataObj,
      },
    );
  } else {
    // update
    await Dio().post('https://chat.pxshe.com/business/row/update',
      options: Options(headers: {
        'token': AuthService().token ?? '',
        'operationID': AuthService().newOpId('row-update'),
      }),
      data: {
        'universeId': widget.universeId,
        'table': widget.activeTable,
        'id': existing['id'],
        'name': nameCtrl.text,
        'data': dataObj,
      },
    );
  }
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已保存')));
  _loadRows();
}
```

---

## 12. 删除数据行 Checklist

### 12.1 调用接口

- URL: `POST https://chat.pxshe.com/business/row/delete`
- 请求体: `{ "universeId": 15, "table": "weapon", "id": 1 }`

### 12.2 响应处理

```
成功: errCode=0, data.id = 1
失败(404): 该行不存在
```

### 12.3 前端要做的事

```
[ ] 12.3.1 表格每行右侧放"删除"按钮(红色小图标)
[ ] 12.3.2 点击 → 二次确认:
         - 标题: '删除 "倚天剑"?'
         - 内容: "确认删除这条数据?"
         - 确认按钮红色
[ ] 12.3.3 用户确认后调 /row/delete
[ ] 12.3.4 删除中: 按钮变 loading
[ ] 12.3.5 成功后: 弹 toast + 刷新表格
[ ] 12.3.6 失败: 弹错误,留在表格
```

### 12.4 容易踩的坑

⚠️ **删除单行不删子表**: 子表本身还在,只是少一条数据
⚠️ **删除后必须 refetch**: 表格数据是缓存的,删除后必须重新拉取
⚠️ **二次确认**: 不要省,虽然风险比删子表小,但仍是不可逆操作

### 12.5 Flutter 代码片段 🔧

```dart
Future<void> _deleteRow(Map row) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('删除 "${row['name']}"?'),
      content: Text('确认删除这条数据?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('取消')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: Text('确认删除'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  await Dio().post('https://chat.pxshe.com/business/row/delete',
    options: Options(headers: {
      'token': AuthService().token ?? '',
      'operationID': AuthService().newOpId('row-del'),
    }),
    data: {
      'universeId': widget.universeId,
      'table': widget.activeTable,
      'id': row['id'],
    },
  );
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已删除')));
  _loadRows();
}
```

---
## 13. 完整流程图 Checklist

### 13.1 场景 1:新用户首次使用(0 → 1)

```
启动 App
  ↓
没 token,跳登录页
  ↓
用户填 phoneNumber(13900000001) + password → 登录
  ↓
拿到 chatToken + userId,存本地
  ↓
进入"宇宙列表"页
  ↓
调 /business/universe/list 拿列表(空数组)
  ↓
显示空状态:"还没有世界" + "新建第一个"按钮
  ↓
用户点"新建"
  ↓
跳到"新建世界"页(表单)
  ↓
用户填名称/简介/封面 → 点"创建"(作者从 token 自动取,不需要填)
  ↓
调 /business/universe/add,拿到 id=15
  ↓
自动跳到"世界 #15 详情"页
  ↓
进入"我的数据表"区块,显示空状态
  ↓
用户点"+ 新建数据表"
  ↓
输入 weapon → 创建成功
  ↓
用户点 weapon → 进入数据管理区
  ↓
用户点"+ 添加数据" → 填 倚天剑 + JSON → 调 /business/row/add
  ↓
数据展示在表格里
```

### 13.2 场景 2:已有世界,加新子表

```
进入"宇宙列表"页(直接显示已有世界)
  ↓
用户点世界卡片 → 跳详情页
  ↓
自动调 /universe/find 加载世界信息
  ↓
自动调 /table/list 加载该世界的子表
  ↓
展示"我的数据表"区块(已有 N 个子表)
  ↓
用户点"+ 新建数据表" → 输入 faqi → 调 /table/create
  ↓
列表刷新,自动选中新建的 faqi
  ↓
显示空数据状态,引导用户"添加数据"
```

### 13.3 场景 3:编辑已有数据

```
进入世界详情
  ↓
用户选 character 子表
  ↓
调 /row/list 加载所有 character 数据
  ↓
表格显示行
  ↓
用户点某行的"编辑"图标
  ↓
弹窗预填 name 和 data
  ↓
用户改 data → 点"保存"
  ↓
调 /row/update
  ↓
弹"已保存" → 表格刷新
```

### 13.4 场景 4:删除整个世界(慎用)

```
进入世界详情
  ↓
用户点"删除"按钮(红色)
  ↓
弹二次确认 Modal
  ↓
用户点"确认删除"
  ↓
调 /universe/del
  ↓
后端自动 DROP 该世界所有子表(postgres CASCADE)
  ↓
弹"已删除" → 跳回列表页
  ↓
列表刷新,该世界已消失
```

### 13.5 关键提示(必读)

⚠️ **每个接口都要带 operationID**: 不能两次请求用同一个 ID(用 `newOpId(biz)` 生成)
⚠️ **每个 /business/* 都要带 token**: 没有 token 会 401
⚠️ **删除是不可逆的**: UI 必须二次确认,文案要说清影响
⚠️ **每个世界独立**: 操作时永远带 universeId,不要缓存跨世界数据
⚠️ **data 字段不固定**: 每个世界每个子表的 data key 不同,前端不要写死字段名

---

## 14. 附录

### 14.1 Flutter 端全部接口 URL 速查表

⚠️ **本表是给 Flutter 客户端用的**,全部走 `chat.pxshe.com`,鉴权用普通用户 token(UserType=1)。

```
# 用户登录(Flutter 用 chat 域,不是 admin)
POST https://chat.pxshe.com/account/login

# 宇宙 CRUD(Flutter 用户版)
POST https://chat.pxshe.com/business/universe/list         ← 列出公开世界 + 自己的私有
POST https://chat.pxshe.com/business/universe/list_mine    ← 只列自己的
POST https://chat.pxshe.com/business/universe/find         ← 查单个(私有需作者)
POST https://chat.pxshe.com/business/universe/add         ← 创建(creatorId 自动从 token 取)
POST https://chat.pxshe.com/business/universe/update      ← 更新(只能改自己的)
POST https://chat.pxshe.com/business/universe/del         ← 删除(只能删自己的)

# 子表管理(只能操作自己的世界)
POST https://chat.pxshe.com/business/table/list
POST https://chat.pxshe.com/business/table/create
POST https://chat.pxshe.com/business/table/delete
POST https://chat.pxshe.com/business/table/rename

# 数据行管理(只能操作自己的世界)
POST https://chat.pxshe.com/business/row/list
POST https://chat.pxshe.com/business/row/add
POST https://chat.pxshe.com/business/row/update
POST https://chat.pxshe.com/business/row/delete
POST https://chat.pxshe.com/business/row/get
```

> **超管接口**(admin 后台用): `admin.pxshe.com/business/universe/search`,Flutter 端**不要**调。

### 14.2 错误码速查

完整错误码对照表见 [docs/ERROR_CODES.md](ERROR_CODES.md)。

### 14.3 字段类型参考

```
id           number      整数,系统自增
name         string      1-200 字符(世界) / 任意长度(数据行)
summary      string      1-2000 字符(世界简介)
coverUrl     string      1-500 字符(合法 URL)
creatorId    string      1-64 字符(userID)
createdAt    string      ISO 8601 格式(世界) 或 "2006-01-02 15:04:05" 格式(数据行)
universeId   number      整数,存在的世界 ID
table        string      子表名(英文/数字/下划线,1-50 字符,大小写敏感)
data         object      任意 JSON 对象
```

### 14.4 参考文档

| 文档 | 路径 |
|------|------|
| API 详细参考手册 | `chat/docs/UNIVERSE_API.md` |
| 前端 Checklist(本文档) | `docs/FRONTEND_INTEGRATION_CHECKLIST.md` |

### 14.5 找不到东西时

- API 返回字段含义不清楚 → 看 `UNIVERSE_API.md`
- 不知道怎么对接 → 看本 Checklist 对应章节
- 接口报错 → 看错误码速查表(14.2)
- 其它问题 → 联系后端 DBA / OpenIM 群

---

**文档结束。版本 v1.0,2026-07-01。**
