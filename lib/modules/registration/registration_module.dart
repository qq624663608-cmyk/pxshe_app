import '../../_core/di.dart';
import 'data/registration_service.dart';

/// Module facade for registration. (pxshe_app DI convention)
void registerRegistrationModule() {
  di.registerLazySingleton<RegistrationService>(
    () => RegistrationService(apiClient: di()),
  );
}