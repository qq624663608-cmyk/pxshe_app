# docs/API.md — 全部 API 端点

> **本文件是后端对接 SSOT。**
> 任何新增/修改 API 端点, 同步这里。

---

## 4 域架构 (硬约束,后端 SSOT: `docs/app/SERVICE_INVENTORY.md`)

| 域 | 客户端地址 (无端口,反代) | 用途 | Flutter 端调用 |
|---|---|---|---|
| `chat.pxshe.com` | `https://chat.pxshe.com` | chat-api (反代到 10008) | ✅ **Flutter 唯一业务域** |
| `api.pxshe.com` | `https://api.pxshe.com` | openim-api (反代到 10002) | OpenIM SDK 内部 (AGENTS §15 禁直连) |
| `ws.pxshe.com` | `wss://ws.pxshe.com` | openim-msggateway (反代到 10001 WSS) | OpenIM SDK 内部 |
| `admin.pxshe.com` | `https://admin.pxshe.com` | admin-api (反代到 10009) | ❌ **不调用** (超管用) |

**重要**: 客户端**不带端口** (跟 `chat.pxshe.com` 同样模式),反代在 443 上转发。直接写 `:10002` / `:10001` 不会走反代。

详见 [backend-integration.md](./backend-integration.md) (旧版) 或 [IM_INTEGRATION.md](./IM_INTEGRATION.md)。

---

## 1. 公开端点 (无 token)

| 方法 | 路径 | 用途 |
|---|---|---|
| POST | `/business/public/registration/config/get` | 拉注册策略 (启动时) |

### `POST /business/public/registration/config/get`

**请求**:
```json
{}
```

**响应**:
```json
{
  "errorCode": 0,
  "data": {
    "allowRegister": true,
    "availableMethods": ["phone", "email", "username"],
    "privacyPolicyMarkdown": "# 隐私政策...",
    "privacyPolicyVersion": 1,
    "userAgreementMarkdown": "# 用户协议...",
    "userAgreementVersion": 1
  }
}
```

详见 [modules/registration/](../../pxshe_app/lib/modules/registration/) (阶段 1.5)。

---

## 2. Auth (普通用户)

| 方法 | 路径 | 用途 | 是否需 token |
|---|---|---|---|
| POST | `/account/login` | 普通用户登录 | ❌ |
| POST | `/account/register` | 普通用户注册 | ❌ |

### `POST /account/login`

**请求**:
```json
{
  "areaCode": "+86",
  "phoneNumber": "13900000001",
  "password": "Test123456",
  "platform": 2
}
```

**响应**:
```json
{
  "errorCode": 0,
  "data": {
    "chatToken": "eyJ...",
    "userID": "3370159211",
    "imToken": "eyJ..."
  }
}
```

3 个字段缺一不可, **imToken 不要单独再调 SDK 拿**。

### `POST /account/register`

**请求**:
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

**响应**: 同 login (注册成功自动登录, autoLogin: true)

---

## 3. Universe (阶段 3)

| 方法 | 路径 | 用途 |
|---|---|---|
| POST | `/business/universe/list` | 列表 (公开 + 自己的) |
| POST | `/business/universe/list_mine` | 列表 (只自己的) |
| POST | `/business/universe/find` | 详情 |
| POST | `/business/universe/add` | 创建 |
| POST | `/business/universe/update` | 编辑 |
| POST | `/business/universe/del` | 删除 |

### `POST /business/universe/list`

**请求**:
```json
{
  "keyword": "",
  "page": 1,
  "size": 20
}
```

**响应**:
```json
{
  "errorCode": 0,
  "data": {
    "total": 5,
    "currentUid": "3370159211",
    "list": [
      {
        "id": 15,
        "name": "武侠江湖",
        "summary": "...",
        "coverUrl": "https://...",
        "creatorId": "3370159211",
        "visibility": "public",
        "createdAt": "2026-07-01T10:30:00+08:00"
      }
    ]
  }
}
```

### `POST /business/universe/add`

**请求**:
```json
{
  "name": "武侠江湖",
  "summary": "...",
  "coverUrl": "https://...",
  "visibility": "public"
}
```

⚠️ **不传 `creatorId`**, 后端从 token 自动取当前 userID。

---

## 4. Table (阶段 3)

| 方法 | 路径 | 用途 |
|---|---|---|
| POST | `/business/table/list` | 列出某个世界的子表 |
| POST | `/business/table/create` | 创建子表 |
| POST | `/business/table/rename` | 重命名 |
| POST | `/business/table/delete` | 删除 |

### `POST /business/table/list`

**请求**:
```json
{ "universeId": 15 }
```

**响应**:
```json
{
  "errorCode": 0,
  "data": {
    "tables": ["weapon", "character", "city"]
  }
}
```

### `POST /business/table/create`

**请求**:
```json
{
  "universeId": 15,
  "name": "weapon"
}
```

⚠️ `name` 必须英文/数字/下划线, 1-50 字符。

---

## 5. Row (阶段 3)

| 方法 | 路径 | 用途 |
|---|---|---|
| POST | `/business/row/list` | 列表 |
| POST | `/business/row/add` | 添加 |
| POST | `/business/row/update` | 编辑 |
| POST | `/business/row/delete` | 删除 |
| POST | `/business/row/get` | 详情 |

### `POST /business/row/list`

**请求**:
```json
{
  "universeId": 15,
  "table": "weapon",
  "page": 1,
  "size": 20
}
```

**响应**:
```json
{
  "errorCode": 0,
  "data": {
    "total": 8,
    "list": [
      {
        "id": 1,
        "name": "倚天剑",
        "data": { "attack": 999, "skill": "独孤九剑" },
        "createdAt": "2026-07-01 10:35:00"
      }
    ]
  }
}
```

### `POST /business/row/add`

**请求**:
```json
{
  "universeId": 15,
  "table": "weapon",
  "name": "倚天剑",
  "data": { "attack": 999, "skill": "独孤九剑" }
}
```

⚠️ `data` 是 JSON 对象, 不是字符串。

---

## 6. HTTP Header 规范

每个请求必须带 2 个 header:

| Header | 值 | 说明 |
|---|---|---|
| `token` | `<chatToken>` | 业务鉴权 (除公开端点) |
| `operationID` | `<biz>-<ts>-<rand>` | 全局唯一, 例 `uni-add-1690812345000-1234` |
| `Content-Type` | `application/json` | 默认 |

详见 [ARCHITECTURE.md §6](./ARCHITECTURE.md) 数据流示例。

---

## 7. 错误码 (6 段)

详见 [ERROR_HANDLING.md](./ERROR_HANDLING.md) 完整表。

| 段位 | 含义 | HTTP |
|---|---|---|
| 0 | 成功 | 200 |
| 1xxx | 参数/校验 | 400 |
| 2xxx | 鉴权 | 401 |
| 3xxx | 资源/文件 | 400/404 |
| 4xxx | OpenIM | 401/403/500/503 |
| 5xxx | 业务逻辑 | 400/409 |
| 6xxx | 服务异常 | 500 |

---

*最后更新: 2026-07-01*