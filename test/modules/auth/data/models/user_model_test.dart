import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pxshe_app/modules/auth/data/models/user_model.dart';

class _MockBinaryReader extends Mock implements BinaryReader {}

class _MockBinaryWriter extends Mock implements BinaryWriter {}

void main() {
  setUpAll(() {
    registerFallbackValue(0);
  });

  group('UserModel', () {
    test('fromJson populates all fields', () {
      final m = UserModel.fromJson({
        'userID': 'u1',
        'nickname': 'Alice',
        'phoneNumber': '13900000001',
        'areaCode': '+86',
      });
      expect(m.id, 'u1');
      expect(m.nickname, 'Alice');
      expect(m.phoneNumber, '13900000001');
      expect(m.areaCode, '+86');
    });

    test('fromJson with missing fields uses empty defaults', () {
      final m = UserModel.fromJson({});
      expect(m.id, '');
      expect(m.nickname, '');
      expect(m.phoneNumber, '');
      expect(m.areaCode, '');
    });

    test('toJson serializes all fields', () {
      const m = UserModel(
        id: 'u2',
        nickname: 'Bob',
        phoneNumber: '139',
        areaCode: '+1',
      );
      final json = m.toJson();
      expect(json['userID'], 'u2');
      expect(json['nickname'], 'Bob');
      expect(json['phoneNumber'], '139');
      expect(json['areaCode'], '+1');
    });
  });

  group('UserModelAdapter', () {
    test('typeId is 1', () {
      expect(UserModelAdapter().typeId, 1);
    });

    test('read reconstructs UserModel from binary', () {
      final reader = _MockBinaryReader();
      when(() => reader.readByte()).thenReturn(4);
      // Field 0: id
      // Field 1: nickname
      // Field 2: phoneNumber
      // Field 3: areaCode
      final byteSequence = <int>[0, 1, 2, 3];
      int readIdx = 0;
      when(() => reader.readByte()).thenAnswer((_) {
        if (readIdx < byteSequence.length) {
          return byteSequence[readIdx++];
        }
        return 0;
      });
      when(() => reader.read()).thenAnswer((_) {
        const values = ['u1', 'Alice', '139', '+86'];
        int valIdx = 0;
        return () {
          if (valIdx < values.length) return values[valIdx++];
          return null;
        }();
      });

      // Actually the read pattern is: for each field, readByte (field id), then read (value)
      // Let me use a stateful mock
      final statefulReader = _StatefulReader();
      final adapter = UserModelAdapter();
      final result = adapter.read(statefulReader);
      expect(result.id, 'u1');
      expect(result.nickname, 'Alice');
      expect(result.phoneNumber, '139');
      expect(result.areaCode, '+86');
    });

    test('write serializes all fields', () {
      final writer = _MockBinaryWriter();
      final adapter = UserModelAdapter();
      const model = UserModel(
        id: 'u1',
        nickname: 'Alice',
        phoneNumber: '139',
        areaCode: '+86',
      );

      when(() => writer.writeByte(any())).thenReturn(null);
      when(() => writer.write(any())).thenReturn(null);

      adapter.write(writer, model);
      verify(() => writer.writeByte(4)).called(1);
      verify(() => writer.writeByte(0)).called(1);
      verify(() => writer.writeByte(1)).called(1);
      verify(() => writer.writeByte(2)).called(1);
      verify(() => writer.writeByte(3)).called(1);
      verify(() => writer.write('u1')).called(1);
      verify(() => writer.write('Alice')).called(1);
      verify(() => writer.write('139')).called(1);
      verify(() => writer.write('+86')).called(1);
    });
  });
}

class _StatefulReader extends Mock implements BinaryReader {
  int _byteCallCount = 0;
  int _readCallCount = 0;
  final List<int> _byteQueue = [4, 0, 1, 2, 3];
  final List<dynamic> _valueQueue = ['u1', 'Alice', '139', '+86'];

  @override
  int readByte() {
    if (_byteCallCount < _byteQueue.length) {
      return _byteQueue[_byteCallCount++];
    }
    return 0;
  }

  @override
  dynamic read([int? typeId]) {
    if (_readCallCount < _valueQueue.length) {
      return _valueQueue[_readCallCount++];
    }
    return null;
  }
}