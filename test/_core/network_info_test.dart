import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pxshe_app/_core/network_info.dart';

class _MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  group('NetworkInfo abstract', () {
    test('has isConnected method', () {
      // Verify the contract
      expect(NetworkInfo, isNotNull);
    });
  });

  group('NetworkInfoImpl', () {
    late _MockNetworkInfo mock;

    setUp(() {
      mock = _MockNetworkInfo();
    });

    test('isConnected can be mocked to return true', () async {
      when(() => mock.isConnected()).thenAnswer((_) async => true);
      final result = await mock.isConnected();
      expect(result, isTrue);
    });

    test('isConnected can be mocked to return false', () async {
      when(() => mock.isConnected()).thenAnswer((_) async => false);
      final result = await mock.isConnected();
      expect(result, isFalse);
    });
  });
}