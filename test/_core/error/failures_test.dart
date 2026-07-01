import 'package:flutter_test/flutter_test.dart';
import 'package:pxshe_app/_core/error/failures.dart';
import 'package:pxshe_app/modules/auth/domain/user.dart';

void main() {
  group('ServerFailure', () {
    test('default message', () {
      final f = ServerFailure();
      expect(f.getMessage(), 'Oops something went wrong');
    });

    test('custom message', () {
      final f = ServerFailure('custom');
      expect(f.getMessage(), 'custom');
    });

    test('equality based on message', () {
      final a = ServerFailure('same');
      final b = ServerFailure('same');
      final c = ServerFailure('diff');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('props contains message', () {
      final f = ServerFailure('msg');
      expect(f.props, ['msg']);
    });
  });

  group('CacheFailure', () {
    test('returns provided message', () {
      final f = CacheFailure('cache msg');
      expect(f.getMessage(), 'cache msg');
    });

    test('equality', () {
      final a = CacheFailure('m');
      final b = CacheFailure('m');
      expect(a, equals(b));
    });
  });

  group('ConnectionFailure', () {
    test('returns No Internet', () {
      final f = ConnectionFailure();
      expect(f.getMessage(), 'No Internet Connection');
    });

    test('equality', () {
      expect(ConnectionFailure(), ConnectionFailure());
    });
  });

  group('User.empty', () {
    test('all fields are empty', () {
      expect(User.empty.id, '');
      expect(User.empty.nickname, '');
      expect(User.empty.phoneNumber, '');
      expect(User.empty.areaCode, '');
    });

    test('props includes all fields', () {
      final u1 = User.empty;
      final u2 = User.empty;
      expect(u1, equals(u2));
    });

    test('props are not empty', () {
      expect(User.empty.props, isNotEmpty);
    });

    test('User equality works', () {
      const u1 = User(id: '1', nickname: 'a', phoneNumber: 'p', areaCode: '+86');
      const u2 = User(id: '1', nickname: 'a', phoneNumber: 'p', areaCode: '+86');
      expect(u1, equals(u2));
    });
  });
}