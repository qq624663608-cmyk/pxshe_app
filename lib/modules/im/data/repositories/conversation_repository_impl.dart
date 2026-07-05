import 'dart:async';

import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';

import 'package:pxshe_app/_core/logger.dart';
import 'package:pxshe_app/modules/im/data/datasources/openim_sdk_wrapper.dart';
import 'package:pxshe_app/modules/im/domain/conversation_repository.dart';

class ConversationRepositoryImpl implements ConversationRepository {
  ConversationRepositoryImpl(this._wrapper);

  final OpenIMSDKWrapper _wrapper;
  final _changesController =
      StreamController<List<ConversationInfo>>.broadcast();
  bool _listenerRegistered = false;

  @override
  Future<List<ConversationInfo>> getAll() {
    return _wrapper.manager.conversationManager.getAllConversationList();
  }

  @override
  Future<int> getTotalUnreadCount() async {
    final result =
        await _wrapper.manager.conversationManager.getTotalUnreadMsgCount();
    // SDK returns int but typed as `dynamic` for forward-compat.
    return result is int ? result : 0;
  }

  @override
  Future<void> markAsRead(String conversationID) async {
    await _wrapper.manager.conversationManager
        .markConversationMessageAsRead(conversationID: conversationID);
  }

  @override
  Stream<List<ConversationInfo>> get changes async* {
    if (!_listenerRegistered) {
      _listenerRegistered = true;
      _wrapper.manager.conversationManager.setConversationListener(
        OnConversationListener(
          onConversationChanged: (list) {
            if (!_changesController.isClosed) {
              _changesController.add(list);
            }
          },
          onNewConversation: (list) {
            if (!_changesController.isClosed) {
              _changesController.add(list);
            }
          },
          onSyncServerFailed: (_) {
            Log.w('ConversationRepository: server sync failed');
          },
          onSyncServerFinish: (_) {
            // one-shot — ignored
          },
          onSyncServerStart: (_) {
            Log.i('ConversationRepository: server sync started');
          },
        ),
      );
    }
    yield* _changesController.stream;
  }

  void dispose() {
    _changesController.close();
  }
}