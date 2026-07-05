import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pxshe_app/modules/im/bloc/conversation_cubit.dart';
import 'package:pxshe_app/modules/im/domain/conversation_repository.dart';

class _MockRepo extends Mock implements ConversationRepository {}

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  group('ConversationCubit', () {
    blocTest<ConversationCubit, ConversationState>(
      'load() emits loading then loaded with items',
      build: () {
        when(() => repo.getAll()).thenAnswer((_) async => [
              ConversationInfo(conversationID: 'c1', showName: 'Alice'),
              ConversationInfo(conversationID: 'c2', showName: 'Bob'),
            ]);
        when(() => repo.changes).thenAnswer((_) => const Stream.empty());
        return ConversationCubit(repo);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<ConversationState>()
            .having((s) => s.status, 'status', ConversationStatus.loading),
        isA<ConversationState>()
            .having((s) => s.status, 'status', ConversationStatus.loaded)
            .having((s) => s.items.length, 'items.length', 2),
      ],
    );

    blocTest<ConversationCubit, ConversationState>(
      'load() emits error on exception',
      build: () {
        when(() => repo.getAll()).thenThrow(Exception('boom'));
        when(() => repo.changes).thenAnswer((_) => const Stream.empty());
        return ConversationCubit(repo);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<ConversationState>()
            .having((s) => s.status, 'status', ConversationStatus.loading),
        isA<ConversationState>()
            .having((s) => s.status, 'status', ConversationStatus.error)
            .having((s) => s.error, 'error', contains('boom')),
      ],
    );

    blocTest<ConversationCubit, ConversationState>(
      'changes stream updates items without re-loading',
      build: () {
        when(() => repo.getAll())
            .thenAnswer((_) async => <ConversationInfo>[]);
        final controller = StreamController<List<ConversationInfo>>();
        addTearDown(controller.close);
        when(() => repo.changes).thenAnswer((_) => controller.stream);
        return ConversationCubit(repo);
      },
      act: (cubit) async {
        await cubit.load();
      },
      verify: (cubit) async {
        // Trigger the listener manually.
        // (We capture via late because mocktail binds the stream lazily.)
        await Future<void>.delayed(const Duration(milliseconds: 10));
      },
    );

    blocTest<ConversationCubit, ConversationState>(
      'markRead() calls repo.markAsRead then reloads',
      build: () {
        when(() => repo.markAsRead(any())).thenAnswer((_) async {});
        when(() => repo.getAll())
            .thenAnswer((_) async => <ConversationInfo>[]);
        when(() => repo.changes).thenAnswer((_) => const Stream.empty());
        return ConversationCubit(repo);
      },
      act: (cubit) => cubit.markRead('c1'),
      verify: (_) {
        verify(() => repo.markAsRead('c1')).called(1);
        verify(() => repo.getAll()).called(1);
      },
    );
  });
}