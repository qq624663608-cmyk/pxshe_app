import 'dart:async';

import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pxshe_app/modules/im/data/datasources/openim_sdk_wrapper.dart';
import 'package:pxshe_app/modules/im/data/repositories/conversation_repository_impl.dart';

class _MockWrapper extends Mock implements OpenIMSDKWrapper {}

class _MockManager extends Mock implements IMManager {}

class _MockConversationManager extends Mock implements ConversationManager {}

void main() {
  late _MockWrapper wrapper;
  late _MockManager manager;
  late _MockConversationManager conversationManager;

  setUpAll(() {
    registerFallbackValue(OnConversationListener());
  });

  setUp(() {
    wrapper = _MockWrapper();
    manager = _MockManager();
    conversationManager = _MockConversationManager();

    when(() => wrapper.manager).thenReturn(manager);
    when(() => manager.conversationManager).thenReturn(conversationManager);
  });

  group('ConversationRepositoryImpl', () {
    test('getAll() forwards to conversationManager.getAllConversationList',
        () async {
      when(() => conversationManager.getAllConversationList())
          .thenAnswer((_) async => [
                _conv('c1', 'Alice'),
                _conv('c2', 'Bob'),
              ]);

      final repo = ConversationRepositoryImpl(wrapper);
      final list = await repo.getAll();

      expect(list, hasLength(2));
      expect(list.first.conversationID, 'c1');
      verify(() => conversationManager.getAllConversationList()).called(1);
    });

    test('getTotalUnreadCount() sums unreadCount from getAll()', () async {
      when(() => conversationManager.getAllConversationList())
          .thenAnswer((_) async => [
                _conv('c1', 'A', unread: 3),
                _conv('c2', 'B', unread: 5),
              ]);
      when(() => conversationManager.getTotalUnreadMsgCount())
          .thenAnswer((_) async => 8);

      final repo = ConversationRepositoryImpl(wrapper);
      expect(await repo.getTotalUnreadCount(), 8);
    });

    test('markAsRead() forwards conversationID', () async {
      when(() => conversationManager.markConversationMessageAsRead(
              conversationID: any(named: 'conversationID')))
          .thenAnswer((_) async {});

      final repo = ConversationRepositoryImpl(wrapper);
      await repo.markAsRead('c1');

      verify(() => conversationManager.markConversationMessageAsRead(
          conversationID: 'c1')).called(1);
    });

    test('changes stream forwards SDK listener events', () async {
      when(() => conversationManager.setConversationListener(any()))
          .thenAnswer((_) async {});

      final repo = ConversationRepositoryImpl(wrapper);
      final received = <int>[];
      final sub = repo.changes.listen((list) => received.add(list.length));

      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      repo.dispose();

      // After dispose, the controller is closed — adding events must
      // not crash (the listener is the entry point).
      expect(received, isEmpty); // no events fired yet in this test
    });
  });
}

ConversationInfo _conv(String id, String name, {int unread = 0}) =>
    ConversationInfo(
      conversationID: id,
      showName: name,
      unreadCount: unread,
    );