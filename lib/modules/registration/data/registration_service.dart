import '../../../_core/network/api_client.dart';
import '../domain/entities/registration_config.dart';

class RegistrationService {
  RegistrationService({required this.apiClient});

  final ApiClient apiClient;
  RegistrationConfig? _cachedConfig;

  Future<RegistrationConfig> fetchConfig() async {
    final res = await apiClient.post('/business/public/registration/config/get');
    final data = res.data;
    if (data is Map<String, dynamic> && data['errCode'] == 0) {
      final config = RegistrationConfig.fromJson(
        Map<String, dynamic>.from(data['data'] as Map),
      );
      _cachedConfig = config;
      return config;
    }
    throw Exception('Failed to load registration config');
  }

  RegistrationConfig? get cachedConfig => _cachedConfig;

  void clearCache() {
    _cachedConfig = null;
  }
}