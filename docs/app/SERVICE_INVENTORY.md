# 服务清单（SSOT）

> 全部后端服务的权威来源。修改此文件后，请同步检查其他文档是否引用过时信息。

---

## 1. 访问入口

| 域名 | 后端服务 | 端口 | 协议 | 用途 | 谁用 |
|------|---------|------|------|------|------|
| `https://api.pxshe.com` | `openim-api` | 10002 | HTTPS | IM 核心 REST API | openim-sdk-flutter 内部调用 |
| `wss://ws.pxshe.com` | `openim-msggateway` | 10001 | **WebSocket** | IM 实时消息长连接 | Flutter SDK 内部连接 |
| `https://chat.pxshe.com` | `chat-api` | 10008 | HTTPS | chat 业务 REST API | Flutter 普通用户（注册/登录/业务） |
| `https://admin.pxshe.com` | `admin-api` | 10009 | HTTPS | admin 后台 + 超管业务 | admin 后台 Web |

⚠️ **Flutter 客户端的 4 个域**：
```
1. chat.pxshe.com       ← 业务（注册/登录/宇宙/通知配置等）
2. ws.pxshe.com         ← SDK 长连接（openim-sdk-flutter 自动连）
3. api.pxshe.com        ← SDK 内部 HTTP 调用（Flutter 不要直连）
4. admin.pxshe.com      ← ❌ Flutter 不该碰
```

---

## 2. OpenIM Server 端二进制（13 个）

> 路径：`/www/wwwroot/openim-stack/server/_output/bin/platforms/linux/amd64/`
> 启动方式：`./<binary> -i 0 -c /www/wwwroot/openim-stack/server/config/`

| # | 二进制 | 端口 | 类型 | 职责 | 被谁调 |
|---|--------|------|------|------|--------|
| 1 | `openim-api` | **10002** | HTTP | IM 核心 REST API（用户/消息/群/好友/会话） | openim-sdk-flutter |
| 2 | `openim-msggateway` | **10001** | **WebSocket** | IM 长连接网关（消息收发/在线状态/推送） | openim-sdk-flutter |
| 3 | `openim-msgtransfer` | 12020 ~ 12035 | RPC | 消息投递/同步（16 实例负载均衡） | openim-msggateway, openim-api |
| 4 | `openim-push` | 10170 ~ 10185 | RPC | 离线推送（APNS/小米/华为/FCM） | openim-msggateway |
| 5 | `openim-rpc-auth` | 10200 | RPC | token 鉴权 | openim-api |
| 6 | `openim-rpc-user` | 10320 | RPC | 用户账号 CRUD | openim-api |
| 7 | `openim-rpc-friend` | 10240 | RPC | 好友关系 | openim-api |
| 8 | `openim-rpc-group` | 10260 | RPC | 群组管理 | openim-api |
| 9 | `openim-rpc-conversation` | 10220 | RPC | 会话列表/已读 | openim-api |
| 10 | `openim-rpc-msg` | 10110 ~ 10111 | RPC | 消息存储/历史 | openim-api |
| 11 | `openim-rpc-third` | 10300 | RPC | 第三方接入（SMS/邮件/对象存储） | openim-api, chat-rpc |
| 12 | `openim-crontask` | （无端口） | Cron | 定时任务（清理过期 token 等） | 自调度 |

> 💡 **Flutter 客户端只和 `openim-api` (10002) + `openim-msggateway` (10001) 通信**。
> 其他 10 个 RPC 都是 server 内部服务，通过 etcd 服务发现相互调用，Flutter/前端无需关心。

---

## 3. Chat 二进制（4 个）

> 路径：`/www/wwwroot/openim-stack/chat/_output/bin/platforms/linux/amd64/`
> 启动方式：`./<binary> -i 0 -c /www/wwwroot/openim-stack/chat/config/`

| # | 二进制 | 端口 | 类型 | 职责 | 调谁 |
|---|--------|------|------|------|------|
| 13 | `chat-api` | **10008** | HTTP | chat 普通用户 REST API | Flutter |
| 14 | `chat-rpc` | **30300** | gRPC | chat 业务逻辑（注册/登录/密码/VerifyCode） | chat-api, admin-api |
| 15 | `admin-api` | **10009** | HTTP | admin 后台 REST API + 整合管理 UI | admin Web |
| 16 | `admin-rpc` | **30200** | gRPC | admin 业务逻辑（密码/改密/token） | admin-api, chat-api |

**关系图**：
```
[Flutter SDK] ──HTTP──> api.pxshe.com (openim-api:10002)
                 └─WS──> ws.pxshe.com (openim-msggateway:10001)

[Flutter 业务] ──HTTP──> chat.pxshe.com (chat-api:10008)
                              └─gRPC─> chat-rpc:30300
                                          └─HTTP─> openim-api:10002
                                          └─调用─> openim-rpc-* (10 个 RPC)

[admin Web]   ──HTTP──> admin.pxshe.com (admin-api:10009)
                              └─gRPC─> admin-rpc:30200
                              └─gRPC─> chat-rpc:30300
                              └─HTTP─> openim-api:10002
```

---

## 4. 数据存储层

| 服务 | 端口 | 用途 | 谁用 |
|------|------|------|------|
| `mongodb` | 27017 | OpenIM 业务数据（user/account/attribute/admin） | openim-msggateway, openim-api, chat-rpc |
| `postgres` pxshe_business | 5432 | chat 业务数据（universe/registration_config/notification_config） | chat-api, admin-api, chat-rpc |
| `redis` | 6379 | token 缓存 | openim-api, openim-rpc-auth, openim-msggateway |
| `etcd` | 2379 | 服务发现+配置中心 | 所有服务 |
| `kafka` | 9092 | 消息队列（msgtransfer ↔ msggateway） | openim-msggateway, openim-msgtransfer |
| `minio` | 9000 | 对象存储（文件/头像/语音/视频） | openim-api |

---

## 5. nginx 反向代理

| 域名 | 后端目标 | 配置文件 |
|------|---------|----------|
| `api.pxshe.com` | `127.0.0.1:10002` (openim-api) | `/www/server/panel/vhost/nginx/proxy/api.pxshe.com/` |
| `ws.pxshe.com` | `127.0.0.1:10001` (openim-msggateway) | `/www/server/panel/vhost/nginx/proxy/ws.pxshe.com/` |
| `chat.pxshe.com` | `127.0.0.1:10008` (chat-api) | `/www/server/panel/vhost/nginx/proxy/chat.pxshe.com/` |
| `admin.pxshe.com` | `127.0.0.1:10009` (admin-api) | `/www/server/panel/vhost/nginx/proxy/admin.pxshe.com/` |

WS 代理关键配置（`proxy/ws.pxshe.com/*.conf`）：
```nginx
location ^~ / {
    proxy_pass http://192.168.1.56:10001;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $connection_upgrade;
    proxy_http_version 1.1;
    proxy_read_timeout 86400s;   # 24 小时长连接
    proxy_buffering off;
}
```

---

## 6. 进程 PID 速查

> 实时查询命令：`rtk ps -ef | grep openim`

**Server 端（13 个二进制，13~30+ 个进程）**：
```
openim-api            PID 3169754
openim-msggateway     PID 3169712
openim-rpc-auth       PID 3169751
openim-rpc-user       PID 3169730
openim-rpc-friend     PID 3169713
openim-rpc-group      PID 3169849
openim-rpc-conversation PID 3169733
openim-rpc-msg        PID 3169714
openim-rpc-third      PID 3169711
openim-msgtransfer    × 16 实例
openim-push           × 16 实例
openim-crontask       （后台）
```

**Chat 端（4 个进程）**：
```
chat-api      PID 3581831 → :10008
chat-rpc      PID 3576362 → :30300
admin-api     PID 3630130 → :10009
admin-rpc     PID 3576157 → :30200
```

---

## 7. 端口总览图

```
外部域名          内部端口      后端二进制
─────────────────────────────────────────────
api.pxshe.com    :10002     openim-api            (HTTPS)
ws.pxshe.com     :10001     openim-msggateway     (WSS)
chat.pxshe.com   :10008     chat-api              (HTTPS)
admin.pxshe.com  :10009     admin-api             (HTTPS)

(内部 gRPC / RPC)
openim-rpc-auth           :10200
openim-rpc-user           :10320
openim-rpc-friend         :10240
openim-rpc-group          :10260
openim-rpc-conversation   :10220
openim-rpc-msg            :10110-10111
openim-rpc-third          :10300
openim-msgtransfer        :12020-12035  (16 instances)
openim-push               :10170-10185  (16 instances)

chat-rpc                  :30300
admin-rpc                 :30200

(基础设施)
mongodb       :27017
postgres      :5432
redis         :6379
etcd          :2379
kafka         :9092
minio         :9000
```

---

**文档版本**: v1.0 | 创建于 2026-07-06
**维护**: 任一服务二进制/端口变更时，必须更新本文件并同步通知前端
