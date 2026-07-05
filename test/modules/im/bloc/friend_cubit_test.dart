import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pxshe_app/modules/im/bloc/friend_cubit.dart';
import 'package:pxshe_app/modules/im/domain/friend_repository.dart';

class _MockRepo extends Mock implements FriendRepository {}

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  group('FriendCubit', () {
    blocTest<FriendCubit, FriendState>(
      'load() emits loading then loaded with items',
      build: () {
        when(() => repo.getFriendList()).thenAnswer(
          (_) async => [FriendInfo(userID: 'u1', nickname: 'Alice')],
        );
        when(() => repo.getReceivedFriendRequests())
            .thenAnswer((_) async => <FriendApplicationInfo>[]);
        when(() => repo.changes).thenAnswer((_) => const Stream.empty());
        return FriendCubit(repo);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<FriendState>()
            .having((s) => s.status, 'status', FriendStatus.loading),
        isA<FriendState>()
            .having((s) => s.status, 'status', FriendStatus.loaded)
            .having((s) => s.friends.length, 'friends.length', 1)
            .having((s) => s.friends.first.nickname, 'first.nickname', 'Alice')
            .having((s) => s.requests, 'requests', isEmpty),
      ],
    );

    blocTest<FriendCubit, FriendState>(
      'load() emits error on exception',
      build: () {
        when(() => repo.getFriendList()).thenThrow(Exception('boom'));
        when(() => repo.getReceivedFriendRequests())
            .thenAnswer((_) async => <FriendApplicationInfo>[]);
        when(() => repo.changes).thenAnswer((_) => const Stream.empty());
        return FriendCubit(repo);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<FriendState>()
            .having((s) => s.status, 'status', FriendStatus.loading),
        isA<FriendState>()
            .having((s) => s.status, 'status', FriendStatus.error),
      ],
    );

    blocTest<FriendCubit, FriendState>(
      'accept() calls acceptRequest and reloads',
      build: () {
        when(() => repo.acceptRequest(fromUserID: any(named: 'fromUserID')))
            .thenAnswer((_) async {});
        when(() => repo.getFriendList())
            .thenAnswer((_) async => <FriendInfo>[]);
        when(() => repo.getReceivedFriendRequests())
            .thenAnswer((_) async => <FriendApplicationInfo>[]);
        when(() => repo.changes).thenAnswer((_) => const Stream.empty());
        return FriendCubit(repo);
      },
      act: (cubit) => cubit.accept(fromUserID: 'alice'),
      verify: (_) {
        verify(() => repo.acceptRequest(fromUserID: 'alice')).called(1);
        verify(() => repo.getFriendList()).called(1);
        verify(() => repo.getReceivedFriendRequests()).called(1);
      },
    );

    blocTest<FriendCubit, FriendState>(
      'reject() calls rejectRequest and reloads',
      build: () {
        when(() => repo.rejectRequest(fromUserID: any(named: 'fromUserID')))
            .thenAnswer((_) async {});
        when(() => repo.getFriendList())
            .thenAnswer((_) async => <FriendInfo>[]);
        when(() => repo.getReceivedFriendRequests())
            .thenAnswer((_) async => <FriendApplicationInfo>[]);
        when(() => repo.changes).thenAnswer((_) => const Stream.empty());
        return FriendCubit(repo);
      },
      act: (cubit) => cubit.reject(fromUserID: 'eve'),
      verify: (_) {
        verify(() => repo.rejectRequest(fromUserID: 'eve')).called(1);
      },
    );
  });
}