# IM_API_MAP.md — flutter_openim_sdk 3.8.3+hotfix.12 SSOT

> **本文件是 SDK API SSOT**。所有 `lib/modules/im/` 下的代码必须基于本表调用。
> 改 SDK 前先更新本表。
>
> 来源: `F:\wx\openim\open-im-sdk-flutter-3.8.3-hotfix.12\lib\src\manager\*.dart`

---

## 入口

```dart
OpenIM.iMManager  // IMManager 单例
  ├─ conversationManager  // ConversationManager
  ├─ friendshipManager    // FriendshipManager
  ├─ groupManager         // GroupManager
  ├─ messageManager       // MessageManager
  └─ userManager          // UserManager
```

---

## IMManager(主入口)

| 方法 | 签名 | 用途 |
|---|---|---|
| `initSDK` | `Future<dynamic>({required int platformID, required String apiAddr, required String wsAddr, required String dataDir, required OnConnectListener listener, int logLevel = 6, bool isNeedEncryption = false, bool isCompression = false, ...})` | 初始化 SDK |
| `unInitSDK` | `void()` | 反初始化 |
| `login` | `Future<UserInfo>({required String userID, required String token, ...})` | 登录 |
| `logout` | `Future<dynamic>({String? operationID})` | 登出 |
| `getLoginStatus` | `Future<int?>()` | 0=logout, 1=logging, 2=logged |
| `getLoginUserID` | `Future<String>()` | 当前登录 userID |
| `getLoginUserInfo` | `Future<UserInfo>()` | 当前登录用户信息 |
| `setUploadLogsListener` | `void(OnUploadLogsListener)` | 上传日志 |
| `setUploadFileListener` | `void(OnUploadFileListener)` | 上传文件 |

---

## ConversationManager

| 方法 | 签名 | 用途 |
|---|---|---|
| `getAllConversationList` | `Future<List<ConversationInfo>>({String? operationID})` | 所有会话 |
| `getConversationListSplit` | `Future<List<ConversationInfo>>({required int offset, int count = 20, ...})` | 分页 |
| `getOneConversation` | `Future<ConversationInfo>({required String sourceID, required int sessionType, ...})` | 单个会话 |
| `getMultipleConversation` | `Future<List<ConversationInfo>>({required List<String> conversationIDList, ...})` | 多个会话 |
| `getTotalUnreadMsgCount` | `Future<dynamic>()` | 总未读数 |
| `markConversationMessageAsRead` | `Future({required String conversationID, String? operationID})` | 标记已读 |
| `deleteConversationAndDeleteAllMsg` | `Future<dynamic>({required String conversationID})` | 删会话+消息 |
| `clearConversationAndDeleteAllMsg` | `Future<dynamic>({required String conversationID})` | 清空消息 |
| `setConversationListener` | `Future(OnConversationListener)` | 注册会话监听 |

---

## MessageManager

| 方法 | 签名 | 用途 |
|---|---|---|
| `createTextMessage` | `Future<Message>({required String text, String? operationID})` | 创建文本消息草稿 |
| `createTextAtMessage` | `Future<Message>({required String text, required List<String> atUserIDList, ...})` | @消息 |
| `createImageMessage` | `Future<Message>({required String sourcePath, ...})` | 图片消息 |
| `createSoundMessage` | `Future<Message>({required String soundPath, int duration, ...})` | 语音 |
| `createVideoMessage` | `Future<Message>({required String videoPath, ...})` | 视频 |
| `createFileMessage` | `Future<Message>({required String filePath, ...})` | 文件 |
| `createLocationMessage` | `Future<Message>({required String description, double longitude, double latitude, ...})` | 位置 |
| `createCustomMessage` | `Future<Message>({required String data, String? extension, ...})` | 自定义 |
| `sendMessage` | `Future<Message>({required Message message, required OfflinePushInfo offlinePushInfo, String? userID, String? groupID, bool isOnlineOnly = false, ...})` | 发送消息(单聊 userID,群聊 groupID) |
| `getAdvancedHistoryMessageList` | `Future<AdvancedMessage>({String? conversationID, Message? startMsg, GetHistoryViewType viewType, int? count, ...})` | 历史消息(翻页向上) |
| `getAdvancedHistoryMessageListReverse` | `Future<AdvancedMessage>(...)` | 反向翻页 |
| `setAdvancedMsgListener` | `Future(OnAdvancedMsgListener)` | 注册高级消息监听 |

`AdvancedMessage.messageList` 是 `List<Message>`。

---

## FriendshipManager

| 方法 | 签名 | 用途 |
|---|---|---|
| `getFriendList` | `Future<List<FriendInfo>>({bool filterBlack = false, ...})` | 好友列表 |
| `getFriendListPage` | `Future<List<FriendInfo>>({int offset = 0, int count = 40, ...})` | 分页 |
| `getFriendsInfo` | `Future<List<FriendInfo>>({required List<String> userIDList, ...})` | 批量查好友信息 |
| `addFriend` | `Future<dynamic>({required String userID, String? reason, ...})` | 发好友请求 |
| `acceptFriendApplication` | `Future<dynamic>({required String fromUserID, String? handleMsg, ...})` | 接受 |
| `refuseFriendApplication` | `Future<dynamic>({required String fromUserID, String? handleMsg, ...})` | 拒绝 |
| `getFriendApplicationListAsRecipient` | `Future<List<FriendApplicationInfo>>({GetFriendApplicationListAsRecipientReq? req, ...})` | 我收到的请求 |
| `getFriendApplicationListAsApplicant` | `Future<List<FriendApplicationInfo>>({GetFriendApplicationListAsApplicantReq? req, ...})` | 我发出的请求 |
| `deleteFriend` | `Future<dynamic>({required String userID, ...})` | 删好友 |
| `addBlacklist` | `Future<dynamic>({required String userID, String? ex, ...})` | 加黑 |
| `removeBlacklist` | `Future<dynamic>({required String userID, ...})` | 移出黑名单 |
| `getBlacklist` | `Future<List<BlacklistInfo>>()` | 黑名单 |
| `searchFriends` | `Future<List<SearchFriendsInfo>>({required List<String> keywordList, bool isSearchUserID = false, bool isSearchNickname = false, ...})` | 搜好友 |

⚠️ **注意**: `addFriend` 的 SDK 内部把 `userID` 映射到 `toUserID`,跟我之前猜测不一致。

---

## GroupManager

| 方法 | 签名 | 用途 |
|---|---|---|
| `getJoinedGroupList` | `Future<List<GroupInfo>>({String? operationID})` | 已加入群 |
| `getJoinedGroupListPage` | `Future<List<GroupInfo>>({int offset, int count, ...})` | 分页 |
| `getGroupsInfo` | `Future<List<GroupInfo>>({required List<String> groupIDList, ...})` | 多个群信息 |
| `createGroup` | `Future<GroupInfo>({required GroupInfo groupInfo, List<String> memberUserIDs = const [], List<String> adminUserIDs = const [], String? ownerUserID, ...})` | 建群(需要先构造 GroupInfo) |
| `setGroupInfo` | `Future<dynamic>(GroupInfo groupInfo, ...)` | 改群信息 |
| `joinGroup` | `Future<dynamic>({required String groupID, String? reason, int joinSource = 3, String? ex, ...})` | 加群 |
| `quitGroup` | `Future<dynamic>({required String groupID, ...})` | 退群 |
| `dismissGroup` | `Future<dynamic>({required String groupID, ...})` | 解散 |
| `getGroupMembersInfo` | `Future<List<GroupMembersInfo>>({required List<String> userIDList, required String groupID, ...})` | 群成员信息 |
| `getGroupMemberList` | `Future<List<GroupMembersInfo>>({required String groupID, int filter = 0, int offset = 0, int count = 200, ...})` | 群成员列表 |
| `searchGroups` | `Future<List<GroupInfo>>({required List<String> keywordList, bool isSearchGroupID = false, bool isSearchGroupName = false, ...})` | 搜群 |
| `getGroupApplicationListAsRecipient` | `Future<List<GroupApplicationInfo>>({...})` | 我收到的入群申请 |
| `getGroupApplicationListAsApplicant` | `Future<List<GroupApplicationInfo>>({...})` | 我发出的 |
| `acceptGroupApplication` | `Future<dynamic>({required String groupID, required String fromUserID, String? handleMsg, ...})` | 接受入群 |
| `refuseGroupApplication` | `Future<dynamic>({required String groupID, required String fromUserID, String? handleMsg, ...})` | 拒绝 |

---

## UserManager

| 方法 | 签名 | 用途 |
|---|---|---|
| `getSelfUserInfo` | `Future<UserInfo>(...)` | 当前用户信息 |
| `getUsersInfo` | `Future<List<PublicUserInfo>>({required List<String> userIDList, ...})` | 批量查用户 |
| `setSelfInfo` | `Future<String?>({String? nickname, String? faceURL, ...})` | 改自己信息 |
| `subscribeUsersStatus` | `Future<List<UserStatusInfo>>({required List<String> userIDList, ...})` | 订阅在线状态 |
| `getUserStatus` | `Future<List<UserStatusInfo>>({required List<String> userIDList, ...})` | 查状态 |

---

## Listener 类型

| Listener | 触发时机 |
|---|---|
| `OnConnectListener` | 连接状态变化 / 踢下线 / token 失效 |
| `OnConversationListener` | 会话变更 / 新会话 / 同步失败 |
| `OnAdvancedMsgListener` | 收到新消息 / 已读回执 / 撤回 / 离线消息 |
| `OnFriendshipListener` | 好友请求 / 好友变更 |
| `OnGroupListener` | 群成员变动 / 群解散 / 入群申请 |
| `OnUserListener` | 用户信息变更 |

---

## 关键枚举

⚠️ 注意: `flutter_openim_sdk` 的枚举是 **class with static const int**,不是 Dart enum:

```dart
// ConversationType (class, not enum)
ConversationType.single = 1;       // 单聊
ConversationType.group = 2;        // 群聊 (Deprecated in v3, 用 superGroup)
ConversationType.superGroup = 3;   // 超级群
ConversationType.notification = 4; // 通知

// MessageType
MessageType.text = 101;
// ...

// LoginStatus (enum)
enum LoginStatus { logout, logging, logged }
```

**注意**: `Message` 类**没有** `conversationID` getter — 通过 `sendID` / `recvID` / `sessionType` 组合推断。

---

## 常见调用模式

### 登录 + 进会话
```dart
await OpenIM.iMManager.initSDK(
  platformID: 2,                          // Android
  apiAddr: 'api.pxshe.com:10002',
  wsAddr: 'wss://api.pxshe.com:10002',
  dataDir: appDocs.path,
  listener: OnConnectListener(...),
);
final userInfo = await OpenIM.iMManager.login(
  userID: 'userID',
  token: 'imToken',
);
```

### 发文本消息
```dart
final draft = await OpenIM.iMManager.messageManager.createTextMessage(text: 'hi');
final sent = await OpenIM.iMManager.messageManager.sendMessage(
  message: draft,
  offlinePushInfo: OfflinePushInfo(title: '', desc: 'hi'),
  userID: 'targetUserID',     // 单聊
  // groupID: 'groupID',     // 群聊
);
```

### 拉历史消息
```dart
final result = await OpenIM.iMManager.messageManager
  .getAdvancedHistoryMessageList(
    conversationID: 'si_userA_userB',
    count: 20,
  );
final messages = result.messageList;  // List<Message>
```

---

*创建: 2026-07-06 — 阶段 2.0 前置交付物*
*SDK 版本: flutter_openim_sdk 3.8.3+hotfix.12*