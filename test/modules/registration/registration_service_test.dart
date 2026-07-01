import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pxshe_app/_core/network/api_client.dart';
import 'package:pxshe_app/modules/registration/data/registration_service.dart';
import 'package:pxshe_app/modules/registration/domain/entities/registration_config.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  setUpAll(() {
    registerFallbackValue(RequestOptions(path: '/'));
  });

  group('RegistrationConfig.fromJson', () {
    test('parses allowRegister', () {
      final config = RegistrationConfig.fromJson({'allowRegister': true});
      expect(config.allowRegister, isTrue);
    });

    test('defaults allowRegister to false', () {
      final config = RegistrationConfig.fromJson({});
      expect(config.allowRegister, isFalse);
    });

    test('parses availableMethods list', () {
      final config = RegistrationConfig.fromJson({
        'availableMethods': ['phone', 'email'],
      });
      expect(config.availableMethods, ['phone', 'email']);
    });

    test('defaults availableMethods to empty', () {
      final config = RegistrationConfig.fromJson({});
      expect(config.availableMethods, isEmpty);
    });

    test('parses privacy policy', () {
      final config = RegistrationConfig.fromJson({
        'privacyPolicyMarkdown': '# Privacy',
        'privacyPolicyVersion': 3,
        'privacyPolicyUpdatedAt': '2026-07-01T00:00:00Z',
      });
      expect(config.privacyPolicyMarkdown, '# Privacy');
      expect(config.privacyPolicyVersion, 3);
      expect(config.privacyPolicyUpdatedAt, isNotNull);
    });

    test('parses user agreement', () {
      final config = RegistrationConfig.fromJson({
        'userAgreementMarkdown': '# Terms',
        'userAgreementVersion': 2,
      });
      expect(config.userAgreementMarkdown, '# Terms');
      expect(config.userAgreementVersion, 2);
    });

    test('handles null privacyPolicyUpdatedAt', () {
      final config = RegistrationConfig.fromJson({});
      expect(config.privacyPolicyUpdatedAt, isNull);
    });

    test('hasPhone / hasEmail / hasUsername helpers', () {
      final config = RegistrationConfig.fromJson({
        'availableMethods': ['phone', 'username'],
      });
      expect(config.hasPhone, isTrue);
      expect(config.hasEmail, isFalse);
      expect(config.hasUsername, isTrue);
    });

    test('hasPrivacyPolicy / hasUserAgreement helpers', () {
      final config = RegistrationConfig.fromJson({
        'privacyPolicyMarkdown': '# Privacy',
        'userAgreementMarkdown': '# Terms',
      });
      expect(config.hasPrivacyPolicy, isTrue);
      expect(config.hasUserAgreement, isTrue);
    });

    test('canRegister is true when allowed and has methods', () {
      final config = RegistrationConfig.fromJson({
        'allowRegister': true,
        'availableMethods': ['phone'],
      });
      expect(config.canRegister, isTrue);
    });

    test('canRegister is false when not allowed', () {
      final config = RegistrationConfig.fromJson({
        'allowRegister': false,
        'availableMethods': ['phone'],
      });
      expect(config.canRegister, isFalse);
    });

    test('canRegister is false when no methods', () {
      final config = RegistrationConfig.fromJson({
        'allowRegister': true,
      });
      expect(config.canRegister, isFalse);
    });

    test('handles invalid date gracefully', () {
      final config = RegistrationConfig.fromJson({
        'privacyPolicyUpdatedAt': 'not-a-date',
      });
      expect(config.privacyPolicyUpdatedAt, isNull);
    });
  });

  group('RegistrationService', () {
    late _MockApiClient api;
    late RegistrationService service;

    setUp(() {
      api = _MockApiClient();
      service = RegistrationService(apiClient: api);
    });

    test('fetchConfig returns parsed config on success', () async {
      when(() => api.post(any(), data: any(named: 'data')))
          .thenAnswer((_) async => Response<dynamic>(
                requestOptions: RequestOptions(path: '/x'),
                statusCode: 200,
                data: {
                  'errorCode': 0,
                  'data': {
                    'allowRegister': true,
                    'availableMethods': ['phone', 'email'],
                    'privacyPolicyVersion': 1,
                    'userAgreementVersion': 1,
                  },
                },
              ));

      final config = await service.fetchConfig();
      expect(config.allowRegister, isTrue);
      expect(config.availableMethods, ['phone', 'email']);
    });

    test('fetchConfig caches result', () async {
      when(() => api.post(any(), data: any(named: 'data')))
          .thenAnswer((_) async => Response<dynamic>(
                requestOptions: RequestOptions(path: '/x'),
                statusCode: 200,
                data: {
                  'errorCode': 0,
                  'data': {'allowRegister': true, 'availableMethods': ['phone']},
                },
              ));

      await service.fetchConfig();
      expect(service.cachedConfig, isNotNull);
      expect(service.cachedConfig!.allowRegister, isTrue);
    });

    test('fetchConfig throws on errorCode != 0', () async {
      when(() => api.post(any(), data: any(named: 'data')))
          .thenAnswer((_) async => Response<dynamic>(
                requestOptions: RequestOptions(path: '/x'),
                statusCode: 200,
                data: {'errorCode': 500, 'errMsg': 'server error'},
              ));

      expect(service.fetchConfig(), throwsA(isA<Exception>()));
    });

    test('fetchConfig throws when data is not Map', () async {
      when(() => api.post(any(), data: any(named: 'data')))
          .thenAnswer((_) async => Response<dynamic>(
                requestOptions: RequestOptions(path: '/x'),
                statusCode: 200,
                data: 'not a map',
              ));

      expect(service.fetchConfig(), throwsA(isA<Exception>()));
    });

    test('clearCache removes cached config', () async {
      when(() => api.post(any(), data: any(named: 'data')))
          .thenAnswer((_) async => Response<dynamic>(
                requestOptions: RequestOptions(path: '/x'),
                statusCode: 200,
                data: {
                  'errorCode': 0,
                  'data': {'allowRegister': true, 'availableMethods': ['phone']},
                },
              ));

      await service.fetchConfig();
      expect(service.cachedConfig, isNotNull);
      service.clearCache();
      expect(service.cachedConfig, isNull);
    });
  });
}