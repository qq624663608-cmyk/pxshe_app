import 'dart:async';

import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pxshe_app/_core/di.dart';
import 'package:pxshe_app/modules/im/data/datasources/openim_sdk_wrapper.dart';
import 'package:pxshe_app/modules/im/data/repositories/message_repository_impl.dart';

class _MockWrapper extends Mock implements OpenIMSDKWrapper {}

class _MockManager extends Mock implements IMManager {}

class _MockMessageManager extends Mock implements MessageManager {}

class _MockLogger extends Mock implements Logger {}

void main() {
  late _MockWrapper wrapper;
  late _MockManager manager;
  late _MockMessageManager messageManager;
  late _MockLogger logger;

  setUpAll(() {
    registerFallbackValue(OnAdvancedMsgListener());
    registerFallbackValue(OfflinePushInfo(title: '', desc: ''));
    registerFallbackValue(Message());
  });

  setUp(() {
    wrapper = _MockWrapper();
    manager = _MockManager();
    messageManager = _MockMessageManager();
    logger = _MockLogger();

    when(() => wrapper.manager).thenReturn(manager);
    when(() => manager.messageManager).thenReturn(messageManager);
    if (di.isRegistered<Logger>()) {
      di.unregister<Logger>();
    }
    di.registerSingleton<Logger>(logger);
  });

  tearDown(() {
    if (di.isRegistered<Logger>()) {
      di.unregister<Logger>();
    }
  });

  group('MessageRepositoryImpl', () {
    test('loadHistory() unwraps AdvancedMessage.messageList', () async {
      when(() => messageManager.getAdvancedHistoryMessageList(
            conversationID: any(named: 'conversationID'),
            startMsg: any(named: 'startMsg'),
            count: any(named: 'count'),
          )).thenAnswer((_) async => AdvancedMessage(messageList: [
            Message(clientMsgID: 'm1'),
            Message(clientMsgID: 'm2'),
          ]));

      final repo = MessageRepositoryImpl(wrapper);
      final list = await repo.loadHistory(conversationID: 'c1');

      expect(list, hasLength(2));
      expect(list.first.clientMsgID, 'm1');
    });

    test('loadHistory() defaults to empty when messageList is null',
        () async {
      when(() => messageManager.getAdvancedHistoryMessageList(
            conversationID: any(named: 'conversationID'),
            startMsg: any(named: 'startMsg'),
            count: any(named: 'count'),
          )).thenAnswer((_) async => AdvancedMessage(messageList: null));

      final repo = MessageRepositoryImpl(wrapper);
      expect(await repo.loadHistory(conversationID: 'c1'), isEmpty);
    });

    test('sendText() single chat uses userID, not groupID', () async {
      final draft = Message(clientMsgID: 'd1');
      final sent = Message(clientMsgID: 's1', sendID: 'me');
      when(() => messageManager.createTextMessage(text: any(named: 'text')))
          .thenAnswer((_) async => draft);
      when(() => messageManager.sendMessage(
            message: any(named: 'message'),
            offlinePushInfo: any(named: 'offlinePushInfo'),
            userID: any(named: 'userID'),
            groupID: any(named: 'groupID'),
          )).thenAnswer((_) async => sent);

      final repo = MessageRepositoryImpl(wrapper);
      final result = await repo.sendText(
        recvID: 'target',
        text: 'hello',
      );

      expect(result.clientMsgID, 's1');
      verify(() => messageManager.createTextMessage(text: 'hello')).called(1);
      verify(() => messageManager.sendMessage(
            message: draft,
            offlinePushInfo: any(named: 'offlinePushInfo'),
            userID: 'target',
            groupID: null,
          )).called(1);
    });

    test('sendText() group chat uses groupID, not userID', () async {
      final draft = Message(clientMsgID: 'd1');
      final sent = Message(clientMsgID: 's1');
      when(() => messageManager.createTextMessage(text: any(named: 'text')))
          .thenAnswer((_) async => draft);
      when(() => messageManager.sendMessage(
            message: any(named: 'message'),
            offlinePushInfo: any(named: 'offlinePushInfo'),
            userID: any(named: 'userID'),
            groupID: any(named: 'groupID'),
          )).thenAnswer((_) async => sent);

      final repo = MessageRepositoryImpl(wrapper);
      await repo.sendText(
        recvID: 'groupID',
        text: 'hi all',
        type: ConversationType.group,
      );

      verify(() => messageManager.sendMessage(
            message: draft,
            offlinePushInfo: any(named: 'offlinePushInfo'),
            userID: null,
            groupID: 'groupID',
          )).called(1);
    });

    test('incoming stream registers listener exactly once', () async {
      when(() => messageManager.setAdvancedMsgListener(any()))
          .thenAnswer((_) async {});

      final repo = MessageRepositoryImpl(wrapper);
      final a = repo.incoming;
      final b = repo.incoming;

      // Each getter access must yield the same broadcast stream. We
      // verify the listener was registered at most once.
      final sub1 = a.listen((_) {});
      final sub2 = b.listen((_) {});
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await sub1.cancel();
      await sub2.cancel();
      repo.dispose();

      verify(() => messageManager.setAdvancedMsgListener(any())).called(1);
    });
  });
}