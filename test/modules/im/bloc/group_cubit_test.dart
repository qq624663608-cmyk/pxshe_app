import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pxshe_app/modules/im/bloc/group_cubit.dart';
import 'package:pxshe_app/modules/im/domain/group_repository.dart';

class _MockRepo extends Mock implements GroupRepository {}

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  group('GroupCubit', () {
    blocTest<GroupCubit, GroupState>(
      'load() emits loading then loaded with items',
      build: () {
        when(() => repo.getJoinedGroups()).thenAnswer(
          (_) async => [GroupInfo(groupID: 'g1', groupName: 'G1')],
        );
        when(() => repo.changes).thenAnswer((_) => const Stream.empty());
        return GroupCubit(repo);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<GroupState>()
            .having((s) => s.status, 'status', GroupStatus.loading),
        isA<GroupState>()
            .having((s) => s.status, 'status', GroupStatus.loaded)
            .having((s) => s.groups.length, 'groups.length', 1)
            .having((s) => s.groups.first.groupName, 'first.name', 'G1'),
      ],
    );

    blocTest<GroupCubit, GroupState>(
      'load() emits error on exception',
      build: () {
        when(() => repo.getJoinedGroups()).thenThrow(Exception('boom'));
        when(() => repo.changes).thenAnswer((_) => const Stream.empty());
        return GroupCubit(repo);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<GroupState>()
            .having((s) => s.status, 'status', GroupStatus.loading),
        isA<GroupState>()
            .having((s) => s.status, 'status', GroupStatus.error),
      ],
    );

    blocTest<GroupCubit, GroupState>(
      'create() appends new group to items',
      build: () {
        when(() => repo.create(
              groupName: any(named: 'groupName'),
              memberUserIDs: any(named: 'memberUserIDs'),
              introduction: any(named: 'introduction'),
            )).thenAnswer((_) async => GroupInfo(groupID: 'g_new'));
        when(() => repo.changes).thenAnswer((_) => const Stream.empty());
        return GroupCubit(repo);
      },
      act: (cubit) => cubit.create(name: 'New', memberUserIDs: ['u1']),
      verify: (cubit) {
        expect(cubit.state.groups.length, 1);
        expect(cubit.state.groups.first.groupID, 'g_new');
      },
    );

    blocTest<GroupCubit, GroupState>(
      'quit() calls repo and reloads',
      build: () {
        when(() => repo.quit(any())).thenAnswer((_) async {});
        when(() => repo.getJoinedGroups())
            .thenAnswer((_) async => <GroupInfo>[]);
        when(() => repo.changes).thenAnswer((_) => const Stream.empty());
        return GroupCubit(repo);
      },
      act: (cubit) => cubit.quit('g1'),
      verify: (_) {
        verify(() => repo.quit('g1')).called(1);
        verify(() => repo.getJoinedGroups()).called(1);
      },
    );
  });
}