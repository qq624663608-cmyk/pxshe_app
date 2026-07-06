# 宇宙模块后端架构说明书 (Backend Design Specification)

> 本文档面向**前端工程师**(Flutter / Web / 小程序)
> 目的:**完全理解后端在干什么,为什么这么设计,数据怎么流动**
> 不需要懂 Go,只需要懂 HTTP / JSON / 数据库概念

---

## ⚠️ 三域架构(版本 v2 必读)

```
https://api.pxshe.com      → openim-server  :10002  IM 核心 (被 SDK 调用,Flutter 不直连)
https://chat.pxshe.com     → chat-api       :10008  ✅ Flutter 客户端 + 普通用户用这个
https://admin.pxshe.com    → admin-api      :10009  超管用,Flutter 不应该用
```

| 客户端类型 | 走哪个域 | 鉴权方式 |
|----------|---------|---------|
| Flutter 客户端(普通用户) | `chat.pxshe.com` | 普通用户 token(UserType=1) |
| admin 后台(超管) | `admin.pxshe.com` | 超管 token(UserType=2,level=100) |
| IM SDK | 不直连,通过 openim-sdk 内部连 | SDK 自动 |

⚠️ **关键区别**:
- `admin.pxshe.com/business/*` 是**超管接口**,需要 level=100,Flutter 不能用
- `chat.pxshe.com/business/*` 是**普通用户接口**,Flutter 用这个

| 接口路径 | 在哪个域 | 谁用 |
|---------|---------|------|
| `/business/universe/search` | admin.pxshe.com | 超管 |
| `/business/universe/list` | chat.pxshe.com | Flutter 用户(返回公开+自己的私有)|
| `/business/universe/list_mine` | chat.pxshe.com | Flutter 用户(只看自己的)|
| `/business/universe/find` | 两个域都有 | 超管:看任何 / Flutter:看公开或自己的 |
| `/business/universe/add` | 两个域都有 | 超管:指定 creatorId / Flutter:creatorId 从 token 自动取 |
| `/business/universe/update` | 两个域都有 | 超管:改任何 / Flutter:只能改自己的 |
| `/business/universe/del` | 两个域都有 | 超管:删任何 / Flutter:只能删自己的 |
| `/business/table/*` | 两个域都有 | 超管:任何世界 / Flutter:只能自己的世界 |
| `/business/row/*` | 两个域都有 | 超管:任何世界 / Flutter:只能自己的世界 |

⚠️ **早期版本 v1 文档误把所有 URL 写成 admin.pxshe.com,已修正为 chat.pxshe.com**(适用于 Flutter 端)。

---

## 0. 阅读指南

- ✅ **机制**: 后端为什么这么做
- ✅ **流程**: 一个请求从进入到响应发生了什么
- ✅ **边界**: 哪些能 / 不能做
- ✅ **例子**: 实际 SQL 语句 / 真实数据
- ⚠️ **坑**: 容易踩雷的地方

---

## 1. 系统总览

### 1.1 完整请求链路

> 两个独立入口:Flutter 用 chat-api(10008),admin 后台用 admin-api(10009)。

```
=== 路径 A:Flutter 用户(走 chat-api)===

[Flutter 客户端]
    │
    │  POST https://chat.pxshe.com/business/...
    │  Header: token(chatToken,普通用户), operationID
    │  Body: { universeId, table, ... }
    │
    ↓
[nginx 反向代理 chat.pxshe.com]
    │
    │  listen 443 (HTTPS)
    │  location / → proxy_pass http://127.0.0.1:10008/
    │
    ↓
[chat-api 进程]  ← Go 二进制,路径 chat/_output/bin/platforms/linux/amd64/chat-api
    │
    │  监听 127.0.0.1:10008
    │  Gin Web 框架
    │  路由注册在 chat/internal/api/chat/start.go
    │
    │  中间件链:
    │    1. CheckUser(验 chatToken,UserType=1)
    │    2. ShouldBindJSON(解析请求体)
    │    3. ChatBusinessHandler 直接连 PostgreSQL 走 Repository
    │    4. apiresp.GinSuccess / GinError(格式化响应)
    │
    ↓
[postgres 数据库]  ← 真实数据存储(chat-api 不经过 chat-rpc)
    │
    │  监听 127.0.0.1:5432
    │  数据库名: pxshe_business
    │  用户名: chat_pg
    │  Schema: public
    │
    │  关键表:
    │    - universe (主表,11 列)
    │    - universe_{id}_{name} (动态子表,用户自建)
    │
    └── 返回数据 → chat-api → 前端

=== 路径 B:admin 后台(走 admin-api,超管场景)===

[admin 后台 Web]
    │
    │  POST https://admin.pxshe.com/business/...
    │
    ↓
[nginx 反向代理 admin.pxshe.com] → 127.0.0.1:10009 (admin-api)
    │
    ↓
[admin-api 进程]  ← Go 二进制,路径 chat/_output/bin/platforms/linux/amd64/admin-api
    │
    │  监听 127.0.0.1:10009
    │  中间件:CheckAdmin / CheckSuperAdmin(超管 token)
    │  路由在 chat/internal/api/admin/start.go
    │  Handler 直接连 PostgreSQL(同 Repository,不复用 RPC)
    │
    ↓
[postgres 数据库](同库)
    └── 返回数据 → admin-api → 前端
```

⚠️ **不要混淆**:
- Flutter 走 chat-api:10008(`chat.pxshe.com`),不需要 chat-rpc
- admin 后台走 admin-api:10009(`admin.pxshe.com`)
- 两个 api 都直接连同一 PostgreSQL,Repository 代码共用

### 1.2 4 个进程的关系

| 进程 | 端口 | 作用 | 谁调它 |
|------|------|------|--------|
| **admin-api** | 10009 | admin 后台 HTTP 接口(超管用),直接连 DB | admin 后台 Web |
| **admin-rpc** | 30200 | admin 业务逻辑(密码、改密等),gRPC 服务 | admin-api |
| **chat-api** | 10008 | 普通用户 HTTP 接口(Flutter 用),直接连 DB | Flutter 客户端 |
| **chat-rpc** | 30300 | 聊天业务逻辑 | chat-api + admin-api |

**关键点**:
- Flutter 调 Universe/Table/Row 走 **chat-api:10008**(`chat.pxshe.com`),鉴权用普通用户 token
- admin 后台调 Universe/Table/Row 走 **admin-api:10009**(`admin.pxshe.com`),鉴权用超管 token
- 两个 api 进程都直接连 PostgreSQL,**不经过 gRPC**(只用 Repository 层)
- chat-rpc / admin-rpc 仅用于聊天业务、密码、改密等 OpenIM 核心逻辑

### 1.3 数据库全景

```
postgres pxshe_business
└── public schema
    ├── universe                          ← 主表(所有世界)
    ├── universe_1_weapon                 ← 世界 1 的武器子表(动态建)
    ├── universe_1_character              ← 世界 1 的人物子表
    ├── universe_2_faqi                   ← 世界 2 的法器子表
    └── universe_2_level                  ← 世界 2 的等级子表
```

**关键点**:
- 只有 `universe` 表是手动建的(schema 固定)
- `universe_X_xxx` 是用户调用 `/business/table/create` 时**后端自动执行 CREATE TABLE**
- 物理表名 = `universe_` 前缀 + `universeId` + `_` + 用户起的名字

---

## 1.5 OpenIM Server 端 13 个二进制

> 本节说明 OpenIM server 端有哪些服务、Flutter/前端只需关心其中 2 个。

### 1.5.1 二进制列表

| # | 二进制 | 端口 | 类型 | 职责 | Flutter/前端用吗 |
|---|--------|------|------|------|----------------|
| 1 | `openim-api` | **10002** | HTTPS | IM 核心 REST API | ⚠️ SDK 内部调，不要直连 |
| 2 | `openim-msggateway` | **10001** | **WSS** | IM WebSocket 长连接 | ✅ SDK 自动连 |
| 3 | `openim-msgtransfer` | 12020-12035 | RPC | 消息投递（16 实例负载均衡） | ❌ 后端内部 |
| 4 | `openim-push` | 10170-10185 | RPC | 离线推送（APNS/小米/华为） | ❌ 后端内部 |
| 5 | `openim-rpc-auth` | 10200 | RPC | token 鉴权 | ❌ 后端内部 |
| 6 | `openim-rpc-user` | 10320 | RPC | 用户账号 | ❌ 后端内部 |
| 7 | `openim-rpc-friend` | 10240 | RPC | 好友关系 | ❌ 后端内部 |
| 8 | `openim-rpc-group` | 10260 | RPC | 群组管理 | ❌ 后端内部 |
| 9 | `openim-rpc-conversation` | 10220 | RPC | 会话列表 | ❌ 后端内部 |
| 10 | `openim-rpc-msg` | 10110 | RPC | 消息存储 | ❌ 后端内部 |
| 11 | `openim-rpc-third` | 10300 | RPC | 第三方（SMS/邮件） | ❌ 后端内部 |
| 12 | `openim-crontask` | （无） | Cron | 定时任务（清理过期） | ❌ 后端内部 |

Flutter 实际只需要：
- **业务接口** → `chat.pxshe.com` (chat-api:10008)
- **IM 接口** → `wss://ws.pxshe.com` + `https://api.pxshe.com`（openim-sdk-flutter SDK 内部搞定）

### 1.5.2 完整 15 个二进制清单

> 全部 15 个二进制 + 端口 + 调用关系图见 [SERVICE_INVENTORY.md](SERVICE_INVENTORY.md)。

### 1.5.3 Flutter ↔ 后端的真实通信流

```
Flutter 普通用户
   │
   │ (1) HTTP POST https://chat.pxshe.com/account/login
   │    [返回 chatToken + imToken + userID]
   ▼
chat-api:10008 ──gRPC──> chat-rpc:30300 ──HTTP──> openim-api:10002
                                                         │
                                                         ├─> openim-rpc-user    (建账号)
                                                         └─> openim-rpc-auth    (发 token)

Flutter IM 收发
   │
   │ (1) OpenIMClient.login(userID, imToken)  // SDK 内部
   │
   │ (2) [SDK 自动] WSS 长连 → wss://ws.pxshe.com (openim-msggateway:10001)
   │       [自动收发消息、心跳、重连]
   ▼
openim-msggateway ──gRPC──> openim-rpc-msg       (收消息)
openim-msggateway ──gRPC──> openim-msgtransfer   (异步投递)
openim-msggateway ──gRPC──> openim-push          (离线推送)
```

---

## 2. Universe 业务模型

### 2.1 表结构详解

```
postgres=# \d universe
```

| 列 | 类型 | 长度 | 必填 | 默认 | 说明 |
|----|------|------|------|------|------|
| **id** | bigint | - | ✅ | 自增 | 系统主键,自增序列 universe_id_seq |
| **name** | varchar | 200 | ✅ | - | 世界名称,如"武侠江湖" |
| **description** | text | 无 | - | - | 简介(前端叫 `summary`,后端叫 `description`,它们是同一字段) |
| **creator_id** | varchar | 64 | ✅ | - | 作者 userID(注意下划线命名,JSON 字段名是 `creatorId`) |
| contributors | text[] | - | - | NULL | 共建者数组(前端未使用,保留字段) |
| tags | text[] | - | - | NULL | 标签数组(前端未使用,保留字段) |
| **cover_url** | varchar | 500 | - | - | 封面 URL(下划线命名,JSON 是 `coverUrl`) |
| visibility | varchar | 20 | - | 'public' | 可见性(目前只有 'public',Flutter 准备做 private 时用) |
| status | smallint | - | - | 1 | 状态(1=启用 0=禁用,前端未使用) |
| **created_at** | timestamptz | - | - | now() | 创建时间(前端 ISO 8601 字符串) |
| updated_at | timestamptz | - | - | now() | 更新时间(trigger 自动更新,前端未使用) |

**加粗的 5 列**是前端真正在用的字段,其它 6 列保留字段供未来扩展。

### 2.2 字段名映射(后端 → 前端 JSON)

后端 Go 用下划线命名(`creator_id`),JSON 输出时自动转成驼峰(`creatorId`):

```
postgres 列名          →  JSON 字段名       →  前端变量名
─────────────────────────────────────────────────────────
id                     →  id               →  universe.id
name                   →  name             →  universe.name
description            →  description      →  universe.summary (前端叫 summary)
creator_id             →  creatorId        →  universe.creatorId
cover_url              →  coverUrl         →  universe.coverUrl
created_at             →  createdAt        →  universe.createdAt
```

⚠️ **前后端命名不一致的地方**:
- 后端 `description` ↔ 前端 `summary`(同一字段)
- 这是早期 OpenIM 模板用 description,前端重命名为 summary 更友好

### 2.3 时间字段详解

#### createdAt 格式

**后端 postgres**:`TIMESTAMP WITH TIME ZONE`(带时区)
**返回给前端的格式**:
- 世界列表 / 详情接口:ISO 8601 字符串
  ```json
  "createdAt": "2026-07-01T10:30:00+08:00"
  ```
- 数据行接口:"2006-01-02 15:04:05" 格式
  ```json
  "createdAt": "2026-07-01 10:30:00"
  ```

⚠️ **两种格式不一样**:世界用 ISO 格式,数据行用简洁格式。前端要分别处理:
- Flutter 世界:`DateTime.parse(universe['createdAt'])` 能正确解析
- Flutter 数据行:`row['createdAt']` 是字符串,直接显示即可

#### updatedAt 自动更新机制

```sql
CREATE TRIGGER update_universe_updated_at
  BEFORE UPDATE ON public.universe
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

每次 `UPDATE universe` 自动把 `updated_at` 改成 now()。前端不用管。

### 2.4 保留字段(6 个)的来源和未来用途

| 字段 | 当前状态 | 计划用途 |
|------|---------|---------|
| contributors | NULL | 未来:多作者共同编辑(类似 GitHub collaborators) |
| tags | NULL | 未来:给世界打标签(武侠/都市/科幻) |
| visibility | 'public' | 未来:private 世界(只有创建者可见) |
| status | 1 | 未来:禁用世界(下架/归档) |
| updated_at | now | 未来:前端展示"最近修改时间" |
| id_seq | 序列 | 系统管理用 |

**为什么保留**:
- OpenIM 模板自带这 6 列
- 改 schema 需要 ALTER TABLE,有锁表风险
- 现在没用但加字段方便(只加代码不改表)

---

## 3. 动态子表机制 (核心)

### 3.1 什么是动态子表

**用户每调一次 `/business/table/create`,后端就执行一次 `CREATE TABLE`**。

物理表名 = `universe_{universeId}_{userGivenName}`,例如:
- 用户在 id=15 的世界建 `weapon` 子表 → 后端执行:
  ```sql
  CREATE TABLE universe_15_weapon (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    data JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
  );
  ```
- 用户在 id=16 的世界建 `faqi` 子表:
  ```sql
  CREATE TABLE universe_16_faqi (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    data JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
  );
  ```

⚠️ **每个世界都有自己的子表,同名也不冲突**(`universe_15_weapon` 和 `universe_16_weapon` 是两张不同的物理表)。

### 3.2 子表的物理结构

所有子表结构完全一致,**只有 4 列**:

| 列 | 类型 | 说明 |
|----|------|------|
| **id** | bigserial | 系统自增主键 |
| **name** | text NOT NULL | 数据行名称(用户填,必填) |
| **data** | jsonb | 用户自定义字段(可以是任意 JSON 对象) |
| created_at | timestamptz | 创建时间 |

**没有外键约束**:`data` 字段是 JSONB 而不是独立字段,所以**不需要外键**。

### 3.3 jsonb 字段详解

#### 什么是 jsonb

PostgreSQL 的 JSONB = 二进制存储的 JSON。比 text 更高效(支持索引和 JSON 内部查询)。

#### 存储示例

```
用户在前端填:
{
  "name": "倚天剑",
  "data": {
    "attack": 999,
    "skill": "独孤九剑",
    "rarity": "传说"
  }
}

后端存到 postgres universe_15_weapon.data 列:
{
  "attack": 999,
  "skill": "独孤九剑",
  "rarity": "传说"
}

返回给前端时:
{
  "id": 1,
  "name": "倚天剑",
  "data": {
    "attack": 999,
    "skill": "独孤九剑",
    "rarity": "传说"
  },
  "createdAt": "2026-07-01 10:35:00"
}
```

#### 为什么用 jsonb 而不是 text

| 方案 | 优点 | 缺点 |
|------|------|------|
| **jsonb** ✅ | 自动校验 JSON 合法、支持内部查询(`data->>'skill'`)、存得紧凑 | 不能直接按任意字段排序 |
| text | 最简单,直接存字符串 | 不能 JSON 校验、查询要每次 parse |
| 每个子表固定字段 | 类型严格 | 每建子表要 ALTER TABLE |

我们选 jsonb 因为:
- 用户字段自由,不用 ALTER TABLE
- postgres 原生支持,性能 OK
- 前端不需要处理 JSON 字符串(后端自动 marshal/unmarshal)

#### jsonb 怎么查

后端代码目前不支持按 data 内部字段查询,只支持全表列出。如未来要加(例:按 attack > 900 查武器):

```sql
SELECT * FROM universe_15_weapon
WHERE (data->>'attack')::int > 900;
```

但**现在没做**,因为前端每次都拉全部数据,在前端做过滤就够了。

### 3.4 子表生命周期:5 个阶段

```
阶段 1: CREATE
  ↓  用户调 /business/table/create
  ↓  后端执行 CREATE TABLE universe_X_xxx
  ↓
阶段 2: INSERT DATA
  ↓  用户调 /business/row/add
  ↓  后端执行 INSERT INTO universe_X_xxx (name, data) VALUES (?, ?::jsonb)
  ↓  返回新行 ID
  ↓
阶段 3: RENAME (可选)
  ↓  用户调 /business/table/rename
  ↓  后端执行 ALTER TABLE universe_X_weapon RENAME TO universe_X_weapons
  ↓  数据保留,只是改了物理表名
  ↓
阶段 4: DELETE TABLE
  ↓  用户调 /business/table/delete
  ↓  后端执行 DROP TABLE universe_X_xxx CASCADE
  ↓  数据全丢
  ↓
阶段 5: WORLD DELETE (清理)
  ↓  用户调 /business/universe/del (删世界)
  ↓  后端先列出该世界所有子表:
     SELECT tablename FROM pg_tables WHERE tablename LIKE 'universe_X_%'
  ↓  然后 DROP 全部:
     DROP TABLE universe_X_weapon CASCADE
     DROP TABLE universe_X_character CASCADE
     ...
  ↓  最后 DROP 主表
```

### 3.5 同一世界不能同名子表(虽然物理上允许)

postgres 区分大小写,所以 `Weapon` 和 `weapon` 在 postgres 里是不同的表。但**前端必须限制**:

```dart
// 推荐:前端限制同名
if (tables.contains(newName)) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('已存在同名子表,换个名字')),
  );
  return;
}
```

**为什么物理上允许但实际限制**:
- 用户体验:避免混乱(武器 vs Weapon 不直观)
- 后端代码:`ListDynamicTables` 用 `LIKE 'universe_X_%'` 查,会同时返回 Weapon 和 weapon,前端分不清

### 3.6 查询子表元数据的 SQL

后端用这条 SQL 列出某个世界的所有子表:

```sql
SELECT tablename FROM pg_tables
WHERE schemaname = 'public'
  AND tablename LIKE 'universe_15_%';
```

返回:`weapon`, `character`, `city` 等(去掉 `universe_15_` 前缀)。

⚠️ **这条 SQL 是核心机制**:前端调 `/business/table/list` 时,后端就执行这条 SQL 拿到所有子表名。

### 3.7 子表名校验规则

后端用正则 `^[A-Za-z0-9_]+$` 校验,长度 1-50:

```
✅ 允许:  weapon, faqi, my_table, city_01, level_99
❌ 拒绝:  武器, my table, fa-qi, my.table, my+table, "" (空), 超长字符串
```

**为什么这样限制**:
- postgres 表名允许特殊字符,但需要引号包裹(`"my-table"`)
- 引号包裹的表名在所有 SQL 操作里都得加引号,容易出错
- 限制英文/数字/下划线 → 不需要引号 → SQL 更简洁 → 性能更好
- 限制长度 → 避免过长表名(性能 + 可读性)
---

## 4. 数据隔离原理

### 4.1 为什么"完全独立"

**核心机制**:每个世界的子表物理上是不同的 postgres 表,根本不在同一个表里。

```
世界 15 的"weapon"子表: universe_15_weapon
世界 16 的"weapon"子表: universe_16_weapon
```

这两张表在 postgres 里是 **2 个独立的物理文件**(虽然都在 pxshe_business 库的 public schema 下),互不干扰。

### 4.2 SQL 层的隔离

后端代码在 `chat/pkg/common/db/business/repository.go` 里实现隔离:

```go
// 关键代码:动态表名生成
func dynamicTablePrefix(universeID int64) string {
    return fmt.Sprintf("universe_%d_", universeID)
}
```

**每次操作都拼上 universeId 前缀**:

```go
// 例:查世界 15 的 weapon 子表的所有行
full := dynamicTablePrefix(15) + "weapon"  // = "universe_15_weapon"
db.Raw("SELECT * FROM " + full + " WHERE id = ?", rowID)
```

⚠️ **这意味着**:如果前端漏传 universeId 或传错,会操作到错误的子表(或操作不存在 → 报错)。前端必须保证 universeId 准确。

### 4.3 列表隔离

```go
// 列世界 15 的所有子表
prefix := dynamicTablePrefix(15)  // = "universe_15_"
db.Raw(`SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename LIKE ?`, prefix+"%")
```

返回结果:
```
weapon
character
city
```

然后去掉前缀 `universe_15_`,得到 `["weapon", "character", "city"]` 返回给前端。

⚠️ **如果用户传了 universeId=16**,这条 SQL 只会返回 `universe_16_*` 开头的表,**绝对不会**出现 `universe_15_*` 的表。前端拿到的列表就是完全隔离的。

### 4.4 CASCADE 删除机制

删除世界时,后端代码(`DeleteUniverse` 函数)会:

```go
func (r *Repository) DeleteUniverse(ctx, id int64) error {
    // 1. 先列出该世界所有子表
    tables, _ := r.ListDynamicTables(ctx, id)

    // 2. 逐个 DROP 子表(带 CASCADE 清理索引/约束)
    for _, t := range tables {
        full := dynamicTablePrefix(id) + t  // "universe_15_weapon"
        r.db.Exec("DROP TABLE IF EXISTS " + full + " CASCADE")
    }

    // 3. 最后删主表
    return r.db.Delete(&Universe{}, id).Error
}
```

⚠️ **CASCADE 关键词**:确保如果有其它表引用了该子表(虽然现在没有外键约束,但可能未来加),也会一起删。

### 4.5 删除世界的事务性

⚠️ **当前实现没有用事务**(没 `db.Transaction()` 包)。这意味着:
- 如果 DROP 子表过程中断了,可能部分子表已删,部分未删
- 主表最后删,所以失败时主表还在,部分子表丢了
- 实际场景下 DELETE 几乎不会失败,影响小

**如果前端担心,可以加 Retry 机制**:删除失败时再次调用 /universe/del 重试。

### 4.6 不需要担心的事

- ❌ admin-api:不需要查权限(chatAdmin 是超管,可以操作任何世界)
- ✅ chat-api:需要查权限!每个 Universe/Table/Row 接口都校验 creatorId == 当前登录用户
- ❌ 不需要担心跨世界数据污染(物理隔离)
- ❌ 不需要担心死锁(每个操作都是单表单事务,极短)
- ❌ 不需要担心并发(虽然可能两个用户同时操作同一子表,但 DDL 是串行的)

**chat-api 鉴权视角**:
- Handler 第一步:从 token 解出 `opUserID`,写入上下文
- 改/删前:`SELECT creator_id FROM universe WHERE id=?`,不相等返回 403
- 新建时:creator_id 自动 = opUserID(不接受前端传值,防止伪造)
- `list_mine` 自动过滤:`WHERE creator_id=?`

---

## 5. 14 个 RPC 全景图

### 5.1 RPC 分类

| 类别 | 接口数 | 涉及 SQL 操作 |
|------|--------|----------------|
| **宇宙 CRUD** | 5 | INSERT/SELECT/UPDATE/DELETE FROM universe |
| **动态子表管理** | 4 | SELECT pg_tables / CREATE TABLE / DROP TABLE / ALTER TABLE RENAME |
| **动态子表数据** | 5 | INSERT/SELECT/UPDATE/DELETE FROM universe_X_xxx |

### 5.2 每个 RPC 触发的 SQL

⚠️ 本节讲 14 个底层 RPC(两个 api 进程共用 Repository,只是鉴权不同)。
超管用 `/universe/search` 查所有世界;Flutter 用 `/universe/list`(过滤公开 + 自己的私有)+ `/universe/list_mine`(只看自己的)。

#### universe 系列

```
POST /business/universe/add
  → INSERT INTO universe (name, description, creator_id, cover_url, visibility, status) VALUES (?, ?, ?, ?, 'public', 1) RETURNING id
  → 数据库返回新行 id
  → 后端把 id 通过 {data: {id: N}} 返回

POST /business/universe/del
  → SELECT tablename FROM pg_tables WHERE tablename LIKE 'universe_X_%'
  → DROP TABLE universe_X_xxx CASCADE  (对每个子表)
  → DELETE FROM universe WHERE id = ?

POST /business/universe/update
  → UPDATE universe SET field1=?, field2=? WHERE id = ?
  → trigger 自动更新 updated_at

POST /business/universe/find
  → SELECT * FROM universe WHERE id = ?

POST /business/universe/search            ← 超管用
  → SELECT count(*) FROM universe  (算 total)
  → SELECT * FROM universe WHERE name LIKE '%keyword%' OR description LIKE '%keyword%' ORDER BY id DESC LIMIT ? OFFSET ?

POST /business/universe/list              ← Flutter 用
  → SELECT count(*) FROM universe WHERE visibility='public' OR creator_id=?  (算 total,opUserID=当前用户)
  → SELECT * FROM universe WHERE visibility='public' OR creator_id=? ORDER BY id DESC LIMIT ? OFFSET ?

POST /business/universe/list_mine         ← Flutter 用
  → SELECT count(*) FROM universe WHERE creator_id=?  (算 total)
  → SELECT * FROM universe WHERE creator_id=? ORDER BY id DESC LIMIT ? OFFSET ?
```

#### table 系列

```
POST /business/table/list
  → SELECT tablename FROM pg_tables WHERE tablename LIKE 'universe_X_%'

POST /business/table/create
  → CREATE TABLE IF NOT EXISTS universe_X_name (
      id BIGSERIAL PRIMARY KEY,
      name TEXT NOT NULL,
      data JSONB,
      created_at TIMESTAMPTZ DEFAULT NOW()
    )

POST /business/table/delete
  → DROP TABLE IF EXISTS universe_X_name CASCADE

POST /business/table/rename
  → ALTER TABLE universe_X_oldName RENAME TO universe_X_newName
  → 数据保留(只是改了物理表名)
```

#### row 系列

```
POST /business/row/list
  → SELECT count(*) FROM universe_X_table  (算 total)
  → SELECT id, name, data, created_at FROM universe_X_table ORDER BY id DESC LIMIT ? OFFSET ?
  → 后端把 data JSONB 反序列化成 map 返回

POST /business/row/add
  → INSERT INTO universe_X_table (name, data) VALUES (?, ?::jsonb)
  → 返回新行 id

POST /business/row/update
  → UPDATE universe_X_table SET name=?, data=?::jsonb WHERE id=?
  → 若 0 行受影响 → 返回 404

POST /business/row/delete
  → DELETE FROM universe_X_table WHERE id=?
  → 若 0 行受影响 → 返回 404

POST /business/row/get
  → SELECT id, name, data, created_at FROM universe_X_table WHERE id=?
  → 若 0 行 → 返回 404
```

### 5.3 SQL 的事务性

| 操作 | 是否单事务 | 失败时状态 |
|------|----------|----------|
| universe/add | ✅ 单 INSERT | 主表无变化 |
| universe/del | ❌ 多步,无事务 | 部分子表可能残留(可重试) |
| table/create | ✅ 单 CREATE | 物理表不存在 |
| row/add | ✅ 单 INSERT | 子表无新行 |
| row/update | ✅ 单 UPDATE | 行未变 |
| row/delete | ✅ 单 DELETE | 行未变 |

⚠️ **唯一多步无事务的是 universe/del**。如果担心,可以前端做幂等重试。

---

## 6. 接口依赖图

### 6.1 必须先调什么后调什么

```
                       ┌──────────────────────────────────────┐
                       │ 1. POST https://chat.pxshe.com        │  ← 必须最先调
                       │    /account/login                      │
                       │    传 areaCode + phoneNumber + password│
                       │    拿到 chatToken + userID             │
                       └────────────┬──────────────────────────┘
                                    ↓
                       ┌──────────────────────────────────────┐
                       │ 2. POST /business/universe/add       │  ← 创建世界
                       │    拿到 universeId(creatorId 自动从   │
                       │    token 取,前端不需要传)              │
                       └────────────┬──────────────────────────┘
                                    ↓
                       ┌──────────────────────────────────────┐
                       │ 3. POST /business/table/create       │  ← 在世界下建子表
                       │    传 universeId + tableName         │
                       └────────────┬──────────────────────────┘
                                    ↓
                       ┌──────────────────────────────────────┐
                       │ 4. POST /business/row/add            │  ← 加数据
                       │    传 universeId + table              │
                       │    + name + data                      │
                       └────────────┬──────────────────────────┘
                                    ↓
                       ┌──────────────────────────────────────┐
                       │ 5. POST /business/row/list           │  ← 列出数据
                       │    传 universeId + table             │
                       └──────────────────────────────────────┘
```

### 6.2 错误依赖:不能顺序反过来

| 错误顺序 | 后果 |
|---------|------|
| 没登录直接调 /business/* | 返回 401(token 缺失) |
| 没 universeId 调 /table/create | 返回 400(参数缺失) |
| 没 universeId 调 /row/add | 返回 400 |
| 不存在的 universeId | 400 错误 |
| 不存在的子表名 | /table/delete 静默成功(IF EXISTS),/row/* 返回 404 |

### 6.3 同一接口可以重复调

大部分接口都是**幂等**或**安全重复**:
- universe/add 重复调 → 创建多个世界(不是幂等,但语义清晰)
- universe/update 重复调相同内容 → 后端无变化(updated_at 会更新)
- table/create 重复同名字 → 用 `IF NOT EXISTS` 不会报错(但建议前端检查重名)
- row/update 重复相同内容 → 后端无变化

### 6.4 关键调用顺序约束

| 前置 | 后置 |
|------|------|
| /account/login | 所有 /business/* |
| /business/universe/add | /business/table/* 或 /business/universe/del |
| /business/table/create | /business/row/* 或 /business/table/rename |
| /business/row/add | /business/row/update / /business/row/delete |
| /business/table/delete | 不需要(子表没了,row 操作会 404) |
| /business/universe/del | 不需要(世界没了,table/row 操作会 404) |


---

## 7. 鉴权机制详解

### 7.1 整体流程(Flutter 客户端视角)

```
1. Flutter 调 POST https://chat.pxshe.com/account/login
   传 areaCode, phoneNumber, password
        ↓
2. chat-api 调用内部逻辑(走 chat-rpc.Login 或直接 mongo 查询)
   chat-rpc 从 mongo 的 openim_v3.user 集合查账号
        ↓
3. 比对 password(明文比对,后端代码在 chat/internal/rpc/chat/login.go)
   if user.Password != req.Password → return ErrPassword
        ↓
4. 密码对了,生成 token:
   token = JWT with payload { UserID, UserType, PlatformID, exp, nbf, iat }
   token 存到 mongo(可选,做幂等去重)
        ↓
5. 返回 {chatToken, userID, imToken} 给前端
        ↓
6. 前端把 chatToken + userID 存到本地(SharedPreferences / localStorage)
        ↓
7. 后续所有 /business/* 请求:
   Header: token: <chatToken>
   chat-api 的 CheckUser 中间件验 token(从 token 拿 opUserID)
   每个写操作再 SELECT 校验 universe.creator_id == opUserID
        ↓
8. token 过期(默认 30 天) → 返回 401 → 前端跳登录页
```

> ⚠️ **admin 路径**(admin 后台视角)是另一套流程:用 chatAdmin + OpenIM123,中间件是 CheckAdmin / CheckSuperAdmin,鉴权更宽松(超管可不校验 creator_id)。
```

### 7.2 Token 详解

#### JWT 格式

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJVc2VySUQiOiJpbUFkbWluIiwiVXNlclR5cGUiOjIsIlBsYXRmb3JtSUQiOjAsImV4cCI6MTc5MDU5NDM2NCwibmJmIjoxNzgyODE4MzA0LCJpYXQiOjE3ODI4MTgzNjR9.LqpRaOCHVmVEY-YOmqg_dR0D6XtjGiSVy_gVduGP1Ec
```

3 段用 `.` 分隔:
- 第 1 段:Header (alg=HS256, typ=JWT)
- 第 2 段:Payload (UserID, UserType, exp, nbf, iat)
- 第 3 段:Signature (用 secret 签的)

#### Payload 字段

| 字段 | 类型 | 说明 |
|------|------|------|
| UserID | string | 用户 ID(如 `imAdmin`) |
| UserType | int | 1=普通用户,2=管理员 |
| PlatformID | int | 0=admin |
| exp | int | 过期时间(unix 秒) |
| nbf | int | 生效时间(unix 秒) |
| iat | int | 签发时间(unix 秒) |

⚠️ **前端可以解码 payload 看到 exp,但不能伪造(签名校验)**

### 7.3 Token 过期时间

`config/admin-rpc.yml` 里配置:

```yaml
admin:
  tokenPolicy:
    expire: 43200   # 单位:分钟 = 30 天
```

30 天后自动过期,前端必须处理 401 → 跳登录。

### 7.4 Token 存储位置

**后端**:不持久化(JWT 自带 exp,不需要查库校验)
**前端**:`localStorage` / `SharedPreferences` / `AsyncStorage`

⚠️ **不建议**存 cookie(可能被 CSRF 攻击)。

### 7.5 权限分级

| Level | 含义 | 能做什么 |
|-------|------|---------|
| **100** | 超管(super admin) | 所有 /business/* 接口 + 改密码 + 加管理员 |
| 80 | 普通管理员 | 大部分 /business/*,但不能改密码 / 加管理员 |
| <80 | 只读 | 看,不能改 |

当前默认 `chatAdmin` 是 level=100,**前端只需要支持这一种**。

### 7.6 401 触发场景

| 场景 | 后端返回 |
|------|---------|
| 没带 token header | 401 (header must have token) |
| token 格式错误 | 401 |
| token 过期(exp < now) | 401 |
| token 签名错误 | 401 |
| level 不足调超管接口 | 403 |

**前端处理**:
- 401 → 清本地 token + 跳登录页
- 403 → 提示"权限不足"(通常不会遇到,除非 token 不是超管)

### 7.7 安全建议

⚠️ **不要把 adminToken 暴露给第三方**(日志/截图/分享)
⚠️ **不要在客户端硬编码 token**(每次启动重新登录)
⚠️ **HTTPS 必须启用**(否则 token 在网络传输中是明文)

---

## 8. operationID 机制

### 8.1 为什么必须传

每个 /business/* 请求必须带 `operationID` header,后端用这个做:

1. **幂等去重**:同一 operationID 的请求只处理一次(避免用户手抖双击创建多个世界)
2. **日志追踪**:出问题后,后端日志可以 grep operationID 找到完整请求链
3. **链路追踪**:从 admin-api → chat-rpc → postgres 全链路用同一 ID

### 8.2 命名规范

后端不强制格式,但建议:

```
<业务前缀>-<时间戳>-<随机数>

例:
  uni-add-1719846000-a3f2
  tbl-create-1719846010-b7d1
  row-list-1719846020-c9e4
```

**业务前缀**:可选(`uni` / `tbl` / `row` / `misc`)
**时间戳**:unix 毫秒
**随机数**:2-4 位字母数字,避免同一毫秒内冲突

### 8.3 重复 operationID 会怎样

后端目前**没做严格去重**(代码里 operationID 是 required 但没去重逻辑)。但:
- 日志会记录,出问题能定位
- 业务逻辑会执行(不会因为重复而跳过)

⚠️ **前端应该保证每个请求 operationID 唯一**(后端信任前端)。

### 8.4 后端代码位置

`chat/internal/api/mw/mw.go:100` 处检查 token 和 operationID:

```go
if operationID == "" {
    return error("operationID is required")
}
```

---

## 9. 错误码来源

完整错误码对照表见 [docs/ERROR_CODES.md](ERROR_CODES.md)。

### 9.1 错误响应统一格式

所有接口统一返回 HTTP 200 + JSON body，错误码在 `errCode` 字段：

```json
{
  "errCode": 0,
  "errMsg": "",
  "errDlt": "",
  "data": {}
}
```

`errCode=0` 表示成功，非 0 为错误。前端应看 body `errCode` 决定处理方式，不看 HTTP status。

⚠️ **errDlt 是可选的**,只在某些错误里填充详细原因。前端可以拿 errDlt 显示给开发者,但不应该显示给最终用户(errMsg 已经够了)。


---

## 10. 数据库迁移说明

### 10.1 universe 表的 6 个保留列

详见第 2.4 节。当前**不主动删**,因为:
1. ALTER TABLE DROP COLUMN 需要锁表(虽然很快)
2. 未来可能用到,删了再加更麻烦
3. 不影响业务(数据 NULL,前端不显示)

### 10.2 子表结构不会变

所有 universe_X_xxx 子表的结构都是固定 4 列:
```sql
id BIGSERIAL PRIMARY KEY
name TEXT NOT NULL
data JSONB
created_at TIMESTAMPTZ DEFAULT NOW()
```

**为什么不变**:
- 用户自定义的字段全在 `data` JSONB 里
- 加新功能不需要 ALTER 子表
- 删子表直接 DROP,数据丢失是用户主动选择

### 10.3 数据迁移策略

#### 场景 1:子表结构要加列(目前不需要)

如果未来要在子表加新字段(比如 `updated_at`):
```sql
ALTER TABLE universe_15_weapon ADD COLUMN updated_at TIMESTAMPTZ;
```
**会一次性给所有现有子表加**。但因为子表可能很多(用户建的),需要遍历所有 `universe_*_*` 表执行 ALTER。

**当前没这需求**。

#### 场景 2:某世界的数据要迁移

**没有迁移工具**(也没有需求)。如果用户要把世界 1 的数据移到世界 2:
1. 列出世界 1 的所有子表
2. 对每行数据,在世界 2 重新创建
3. 删除世界 1

**当前通过 API 一行一行复制**。

#### 场景 3:整个 universe 系统迁移

数据库整体备份/恢复通过 postgres 工具:
```bash
pg_dump -U chat_pg pxshe_business > backup.sql
psql -U chat_pg pxshe_business < backup.sql
```

### 10.4 不会自动做的事

⚠️ **数据库不会自动**:
- 自动清理长时间没用的世界
- 自动优化子表(没有 VACUUM 调度,虽然 postgres 会自动)
- 自动备份(需要 DBA 自己配)

⚠️ **当前没有**:定期删除空子表 / 删除空世界 / 压缩 JSONB 数据。

---

## 11. 子表名校验规则详解

### 11.1 正则: `^[A-Za-z0-9_]+$`

后端代码 `chat/pkg/common/db/business/repository.go`:

```go
var tableNamePattern = regexp.MustCompile(`^[A-Za-z0-9_]+$`)

func IsValidTableName(name string) bool {
    if len(name) == 0 || len(name) > 50 {
        return false
    }
    return tableNamePattern.MatchString(name)
}
```

### 11.2 为什么限制这么死

postgres 表名规则其实允许:
```
✅ postgres 原生支持:任何字符,只要用双引号包裹
   CREATE TABLE "my-special.table" (...);
   SELECT * FROM "my-special.table";
❌ 但代码里要到处加引号,容易出错
```

我们的限制让所有 SQL 都不需要引号:
```sql
CREATE TABLE universe_15_weapon (...);   -- ✅ 不需要引号
DROP TABLE universe_15_weapon;             -- ✅ 不需要引号
SELECT * FROM universe_15_weapon;          -- ✅ 不需要引号
```

### 11.3 长度限制: 1-50

postgres 表名实际最长是 63 字节(NAMEDATALEN-1)。我们限制 50 是因为:
- 物理表名 = `universe_` (10) + universeId (最多 19 位) + `_` (1) + 用户名 (50) = 80 字符
- 超过 80 会爆掉 postgres 限制

⚠️ 当前 universeId 是 int64,理论最大 19 位数字,所以 **用户子表名最多 50** 是安全边界。

### 11.4 大小写敏感

postgres 表名区分大小写(默认情况下)。所以:
- `Weapon` 和 `weapon` 是不同的物理表
- 前端调用 `/business/table/list` 会同时返回两个(都 LIKE `universe_15_%` 命中)
- 前端必须**避免**重名(推荐前端检查)

### 11.5 禁止的字符

```
❌ 空格:  my table
❌ 中横线: my-table
❌ 点号:  my.table
❌ 加号:  my+table
❌ 中文:  武器 / 法器
❌ emoji: 🗡️
❌ 特殊符号: / \ ? # & % $ @ !
✅ 允许: 英文/数字/下划线
```

### 11.6 前端校验时机

**前端必须在调 API 前做正则校验**,不要等后端报错:

```dart
// 前端正则校验
if (!RegExp(r'^[A-Za-z0-9_]+$').hasMatch(name)) {
  showToast('表名只能英文/数字/下划线');
  return;
}
if (name.length > 50) {
  showToast('表名最长 50 字符');
  return;
}
```

---

## 12. data JSONB 字段设计详解

### 12.1 三种方案的对比

| 方案 | 优点 | 缺点 | 我们选了吗 |
|------|------|------|-----------|
| **JSONB** | 自动校验、灵活、内部查询支持 | 不能强类型 | ✅ 选了 |
| TEXT (存 JSON 字符串) | 最简单 | 每次查询要 parse、不能校验 | ❌ |
| 固定字段(每子表 ALTER) | 强类型 | 每建子表要 DDL、慢 | ❌ |

### 12.2 JSONB 查询能力(目前没用到但未来可加)

postgres jsonb 支持以下查询(后端代码目前没做,但前端可以期待):

```sql
-- 按 data 内的字段精确查
SELECT * FROM universe_15_weapon
WHERE data->>'rarity' = '传说';

-- 按 data 内的数字字段范围查
SELECT * FROM universe_15_weapon
WHERE (data->>'attack')::int > 900;

-- 检查 data 是否包含某个 key
SELECT * FROM universe_15_weapon
WHERE data ? 'skill';

-- 创建索引(如果某字段常用)
CREATE INDEX idx_weapon_attack ON universe_15_weapon ((data->>'attack'));
```

**当前没做**,因为:
1. 前端目前总是拉全部数据,前端做过滤
2. 性能上 N 小(<1000)时不需要
3. 加 jsonb 内部查询后端代码要改

### 12.3 data 字段的写入路径

```
前端发送 JSON object:
{
  "name": "倚天剑",
  "data": {"attack": 999, "skill": "独孤九剑"}
}

    ↓ 后端 Go 代码 marshalJSON

bytes: {"attack":999,"skill":"独孤九剑"}

    ↓ 后端 INSERT INTO ... ?::jsonb

postgres 解析成二进制 JSONB,索引化存储

    ↓ 读出时反序列化

后端 parseJSONRaw:
map[string]interface{}{"attack": 999, "skill": "独孤九剑"}

    ↓ JSON 响应

{"id":1, "name":"倚天剑", "data":{"attack":999,"skill":"独孤九剑"}, "createdAt":"..."}
```

⚠️ **关键**:后端代码做了 2 次序列化/反序列化,前端不需要手动 JSON.stringify,直接传对象即可。

### 12.4 data 字段的限制

| 限制 | 值 |
|------|-----|
| 最大嵌套深度 | 没有限制,但建议 ≤5 层 |
| 最大 key 长度 | 63 字节(类似 postgres 标识符) |
| 最大字符串值 | 1GB(不要这样做) |
| 推荐单个 data 大小 | ≤100KB(超过考虑单独建表) |

### 12.5 data 字段的典型用法

**场景 A:固定结构的 schema**

```
// 武侠的"武器"子表
{ "attack": 999, "skill": "独孤九剑", "rarity": "传说" }
```

前端可以做个"武器编辑器"表单(预设这几个字段),后端不管,直接存。

**场景 B:用户自定义字段**

```
// 用户随便加
{ "出厂年份": "1985", "材质": "玄铁", "主人": "杨过" }
```

前端给用户一个 JSON TextArea,自由填。

**两种场景都用同一个 data 字段**,灵活切换。

---

## 13. 完整数据生命周期

### 13.1 一个"武器"从无到有的完整旅程

> 走 Flutter 客户端路径(chat-api),登录用 chatToken。
> admin 后台路径相同,只是把 `CheckUser` 换成 `CheckAdmin`,调用域名换成 `admin.pxshe.com`。

```
[用户操作]                   [前端请求]                                    [后端处理]                          [数据库变化]
─────────                   ─────────                                    ─────────                          ─────────────

Flutter 登录
   ↓
用户已登录(chatToken 已存)
   ↓
用户点"+ 新建武器"
   ↓
打开弹窗,填 weapon
   ↓
点"创建"
   ↓
                       POST https://chat.pxshe.com/business/table/create
                       Header: token=chatToken, operationID=...
                       { universeId: 15, name: "weapon" }
                                                                    ↓
                                                                    CheckUser(验 chatToken,UserType=1)
                                                                     → opUserID = "3370159211"
                                                                    ↓
                                                                    SELECT creator_id FROM universe WHERE id=15
                                                                     → creator_id == opUserID?(是 → 继续 / 否 → 403)
                                                                    ↓
                                                                    IsValidTableName("weapon") = true
                                                                    ↓
                                                                    Repository.CreateDynamicTable(15, "weapon")
                                                                    ↓
                                                                    拼接 SQL:
                                                                    CREATE TABLE IF NOT EXISTS universe_15_weapon (
                                                                      id BIGSERIAL PRIMARY KEY,
                                                                      name TEXT NOT NULL,
                                                                      data JSONB,
                                                                      created_at TIMESTAMPTZ DEFAULT NOW()
                                                                    )
                                                                                            ↓
                                                                                            新建物理表 universe_15_weapon
                                                                                            (在 postgres pxshe_business.public)
                                                                                            ↓
                                                                    返 { data: {name: "weapon"} }
                       前端弹"创建成功" +
                       刷新子表列表
   ↓
用户切到 weapon 子表
                       GET /business/table/list {universeId:15}
                                                                    ↓
                                                                    CheckUser(验 chatToken)
                                                                     ↓
                                                                    SELECT tablename FROM pg_tables
                                                                    WHERE tablename LIKE 'universe_15_%'
                                                                                            ↓
                                                                                            查 pg_tables 元数据表
                                                                                            ↓
                                                                    返回 ["weapon", "character", ...]
                       前端显示子表按钮组
   ↓
用户点"+ 添加数据"
   ↓
填名称 + data JSON
   ↓
                       POST /business/row/add
                       { universeId: 15, table: "weapon", name: "倚天剑", data: {attack:999, skill:"独孤九剑"} }
                                                                    ↓
                                                                    CheckUser(验 chatToken)
                                                                     ↓
                                                                    校验 universe.creator_id == opUserID
                                                                     ↓
                                                                    DynamicTableExists(15, "weapon") = true
                                                                     ↓
                                                                    marshalJSON({attack:999, ...})
                                                                     ↓
                                                                    INSERT INTO universe_15_weapon (name, data)
                                                                    VALUES ('倚天剑', '{"attack":999,...}'::jsonb)
                                                                    RETURNING id
                                                                                            ↓
                                                                                            在 universe_15_weapon 表插入新行
                                                                                            (id=1, name="倚天剑", data={...}, created_at=now())
                                                                                            ↓
                                                                    返 { data: {id: 1} }
                       前端弹"添加成功" + 刷新列表
   ↓
用户看列表看到"倚天剑"
                       GET /business/row/list {universeId:15, table:"weapon"}
                                                                    ↓
                                                                    CheckUser(验 chatToken)
                                                                     ↓
                                                                    校验 universe 属于 opUserID(列表不看权限,只校验存在)
                                                                     ↓
                                                                    SELECT id, name, data, created_at
                                                                    FROM universe_15_weapon
                                                                    ORDER BY id DESC
                                                                                            ↓
                                                                                            读出所有行
                                                                                            ↓
                                                                    parseJSONRaw([]byte) → map
                                                                     ↓
                                                                    返 { data: {total: 1, list: [{...}]} }
                       前端表格显示
   ↓
用户点删除
                       POST /business/row/delete {universeId:15, table:"weapon", id:1}
                                                                    ↓
                                                                    CheckUser(验 chatToken)
                                                                     ↓
                                                                    校验 universe.creator_id == opUserID(否则 403)
                                                                     ↓
                                                                    DELETE FROM universe_15_weapon WHERE id=1
                                                                                            ↓
                                                                                            删 1 行
                                                                                            ↓
                                                                    返 { errorCode: 0 }
                       前端刷新列表,空状态
```

⚠️ **关键差异**:chat-api 路径下,每个写操作都要校验 `universe.creator_id == opUserID`,否则 403。Flutter 用户只能操作自己创建的世界。

### 13.2 数据删除的完整流程(删除整个世界)

```
[用户操作]                   [前端请求]                       [后端处理]                          [数据库变化]
─────────                   ─────────                       ─────────                          ─────────────

用户点"删除世界"
   ↓
二次确认弹窗
   ↓
点"确认删除"
   ↓
                       POST /business/universe/del {id: 15}
                                                 ↓
                                                Repository.DeleteUniverse(15)
                                                 ↓
                                                ListDynamicTables(15)
                                                 ↓
                                                SELECT tablename FROM pg_tables
                                                WHERE tablename LIKE 'universe_15_%'
                                                                                            ↓
                                                                                            返回 ['universe_15_weapon', 'universe_15_character', ...]
                                                                                            ↓
                                                对每个子表 DROP:
                                                DROP TABLE universe_15_weapon CASCADE
                                                DROP TABLE universe_15_character CASCADE
                                                ...
                                                                                            ↓
                                                                                            所有 universe_15_* 子表被 DROP
                                                                                            ↓
                                                DELETE FROM universe WHERE id = 15
                                                                                            ↓
                                                                                            主表 world 15 记录被删
                                                                                            ↓
                                                返 { errorCode: 0 }
                       前端弹"已删除" + 跳列表页
```

### 13.3 并发场景考虑

#### 场景 1:两个前端同时编辑同一行

```
用户 A:POST /business/row/update {id:1, name:"A", data:{...}}
用户 B:POST /business/row/update {id:1, name:"B", data:{...}}
```

**结果**:后端串行处理两个 UPDATE,A 的修改先生效,B 的修改覆盖 A。**最后保存的是 B**。

⚠️ **没有乐观锁**(没有 version 字段)。如果要防止覆盖,需要前端加 version 字段。

#### 场景 2:两个前端同时删除世界

```
用户 A:POST /business/universe/del {id: 15}
用户 B:POST /business/universe/del {id: 15}
```

**结果**:两个都执行 DeleteUniverse。A 先执行完(删了所有子表+主表),B 再执行时:
- ListDynamicTables(15) 返回空
- DELETE FROM universe WHERE id=15 影响 0 行(因为 A 已删)
- 返 errorCode=0(不算错误,只是删了个空操作)

⚠️ **第二次返回"成功"但实际啥都没干**。前端应该检查响应体,确认世界真的删了。

#### 场景 3:删世界时正在加数据

```
时间线:
  T1: 用户 A 调 /business/universe/del {id:15}
  T2: 用户 A 后端开始 DROP universe_15_weapon CASCADE
  T3: 用户 B 调 /business/row/add {universeId:15, table:"weapon", ...}
```

**结果**:A 先 DROP 完,B 后调 add 时:
- DynamicTableExists(15, "weapon") = false
- 返 ErrNotFound
- B 收到 404

⚠️ **不会出现"孤儿数据"**(postgres 保证原子性,DROP 完后再 INSERT 会失败)。

---

## 14. 文档结束

**版本**: v1.0
**日期**: 2026-07-01
**作者**: Admin 后端团队

### 相关文档

| 文档 | 路径 | 用途 |
|------|------|------|
| 前端 Checklist | `docs/FRONTEND_INTEGRATION_CHECKLIST.md` | 前端分步骤对接清单 |
| API 字段参考 | `chat/docs/UNIVERSE_API.md` | 接口字段详细说明 |
| 后端架构说明书(本文档) | `docs/BACKEND_DESIGN_SPEC.md` | 后端机制与设计思路 |

### 联系

- 接口报错查日志:`grep <operationID> /var/log/openim-chat/`
- 数据库报错查日志:`tail -f /tmp/postgres.log`
- 其它问题:找后端 DBA
