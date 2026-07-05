import 'dart:async';

import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';

import 'package:pxshe_app/_core/logger.dart';
import 'package:pxshe_app/modules/im/data/datasources/openim_sdk_wrapper.dart';
import 'package:pxshe_app/modules/im/domain/message_repository.dart';

class MessageRepositoryImpl implements MessageRepository {
  MessageRepositoryImpl(this._wrapper);

  final OpenIMSDKWrapper _wrapper;
  final _incomingController = StreamController<Message>.broadcast();
  bool _listenerRegistered = false;

  @override
  Future<List<Message>> loadHistory({
    required String conversationID,
    Message? lastMsg,
    int count = 20,
  }) async {
    final result = await _wrapper.manager.messageManager
        .getAdvancedHistoryMessageList(
      conversationID: conversationID,
      startMsg: lastMsg,
      count: count,
    );
    return result.messageList ?? const <Message>[];
  }

  @override
  Future<Message> sendText({
    required String recvID,
    required String text,
    int type = ConversationType.single,
    String? groupID,
  }) async {
    final draft = await _wrapper.manager.messageManager
        .createTextMessage(text: text);
    return _wrapper.manager.messageManager.sendMessage(
      message: draft,
      offlinePushInfo: OfflinePushInfo(
        title: '',
        desc: text,
        iOSPushSound: '',
      ),
      userID: type == ConversationType.single ? recvID : null,
      groupID: type == ConversationType.single ? null : (groupID ?? recvID),
    );
  }

  @override
  Stream<Message> get incoming async* {
    if (!_listenerRegistered) {
      _listenerRegistered = true;
      _wrapper.manager.messageManager.setAdvancedMsgListener(
        OnAdvancedMsgListener(
          onRecvNewMessage: (msg) {
            if (!_incomingController.isClosed) {
              _incomingController.add(msg);
            }
          },
          onRecvOfflineNewMessage: (msg) {
            if (!_incomingController.isClosed) {
              _incomingController.add(msg);
            }
          },
        ),
      );
      Log.i('MessageRepositoryImpl: advanced message listener registered');
    }
    yield* _incomingController.stream;
  }

  void dispose() {
    _incomingController.close();
  }
}