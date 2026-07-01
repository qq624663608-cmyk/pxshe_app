class RegistrationConfig {
  const RegistrationConfig({
    required this.allowRegister,
    required this.availableMethods,
    this.privacyPolicyMarkdown = '',
    this.privacyPolicyVersion = 0,
    this.privacyPolicyUpdatedAt,
    this.userAgreementMarkdown = '',
    this.userAgreementVersion = 0,
    this.userAgreementUpdatedAt,
  });

  factory RegistrationConfig.fromJson(Map<String, dynamic> json) {
    return RegistrationConfig(
      allowRegister: json['allowRegister'] as bool? ?? false,
      availableMethods: List<String>.from(
        json['availableMethods'] as List<dynamic>? ?? const [],
      ),
      privacyPolicyMarkdown: json['privacyPolicyMarkdown'] as String? ?? '',
      privacyPolicyVersion: json['privacyPolicyVersion'] as int? ?? 0,
      privacyPolicyUpdatedAt: _parseDate(json['privacyPolicyUpdatedAt']),
      userAgreementMarkdown: json['userAgreementMarkdown'] as String? ?? '',
      userAgreementVersion: json['userAgreementVersion'] as int? ?? 0,
      userAgreementUpdatedAt: _parseDate(json['userAgreementUpdatedAt']),
    );
  }

  final bool allowRegister;
  final List<String> availableMethods;
  final String privacyPolicyMarkdown;
  final int privacyPolicyVersion;
  final DateTime? privacyPolicyUpdatedAt;
  final String userAgreementMarkdown;
  final int userAgreementVersion;
  final DateTime? userAgreementUpdatedAt;

  bool get hasPhone => availableMethods.contains('phone');
  bool get hasEmail => availableMethods.contains('email');
  bool get hasUsername => availableMethods.contains('username');
  bool get hasPrivacyPolicy => privacyPolicyMarkdown.isNotEmpty;
  bool get hasUserAgreement => userAgreementMarkdown.isNotEmpty;
  bool get canRegister => allowRegister && availableMethods.isNotEmpty;

  static DateTime? _parseDate(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}