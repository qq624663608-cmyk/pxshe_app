import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';

import 'package:pxshe_app/_core/error/api_exception.dart';
import 'package:pxshe_app/_core/error/error_handler.dart';
import 'package:pxshe_app/_core/error/failures.dart';
import 'package:pxshe_app/_core/theme/app_colors.dart';
import 'package:pxshe_app/_core/theme/app_durations.dart';
import 'package:pxshe_app/_core/theme/app_radius.dart';
import 'package:pxshe_app/_core/theme/app_spacing.dart';
import 'package:pxshe_app/modules/auth/bloc/auth_bloc.dart';
import 'package:pxshe_app/modules/auth/domain/auth_repository.dart';
import 'package:pxshe_app/modules/registration/domain/entities/registration_config.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({
    required this.repository,
    required this.config,
    super.key,
  });

  final AuthRepository repository;
  final RegistrationConfig config;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _areaCodeCtrl = TextEditingController(text: '+86');
  final _phoneCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _verifyCodeCtrl = TextEditingController();
  bool _privacyAccepted = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _areaCodeCtrl.dispose();
    _phoneCtrl.dispose();
    _nicknameCtrl.dispose();
    _passwordCtrl.dispose();
    _verifyCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_privacyAccepted) {
      _showSnack('请先勾选隐私协议');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final result = await widget.repository.register(
        areaCode: _areaCodeCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim(),
        nickname: _nicknameCtrl.text.trim(),
        password: _passwordCtrl.text,
        verifyCode: _verifyCodeCtrl.text,
        platform: 2,
        privacyAccepted: _privacyAccepted,
        privacyPolicyVersion: widget.config.privacyPolicyVersion,
        userAgreementVersion: widget.config.userAgreementVersion,
      );
      result.fold(
        (failure) {
          if (!mounted) return;
          ErrorHandler.handle(context, _toException(failure));
        },
        (user) {
          if (!mounted) return;
          context.read<AuthBloc>().add(const AuthLoginSucceeded());
        },
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Exception _toException(Failure failure) =>
      ApiException(errorKey: ErrorKey.unknown, message: failure.getMessage());

  void _showSnack(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: AppDurations.snack,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Sign up', style: TextStyle(color: AppColors.textPrimary)),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xl),
                const Text(
                  'Create account',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Sign up to get started',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: AppSpacing.xxl),
                if (config.hasPhone) ..._buildPhoneFields(config),
                if (config.hasEmail) ..._buildEmailFields(),
                if (config.hasUsername) ..._buildUsernameFields(),
                if (config.canRegister) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _buildSubmit(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPhoneFields(RegistrationConfig config) {
    return [
      Row(
        children: [
          SizedBox(
            width: 80,
            child: TextFormField(
              controller: _areaCodeCtrl,
              decoration: _inputDecoration('Area', '+86'),
              style: const TextStyle(color: AppColors.textPrimary),
              keyboardType: TextInputType.phone,
              validator: _validateAreaCode,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: TextFormField(
              controller: _phoneCtrl,
              decoration: _inputDecoration('Phone', '13900000001'),
              style: const TextStyle(color: AppColors.textPrimary),
              keyboardType: TextInputType.phone,
              validator: _validatePhone,
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      _buildCommonFields(config),
    ];
  }

  List<Widget> _buildEmailFields() {
    return [
      TextFormField(
        decoration: _inputDecoration('Email', 'you@example.com'),
        style: const TextStyle(color: AppColors.textPrimary),
        keyboardType: TextInputType.emailAddress,
      ),
      const SizedBox(height: AppSpacing.lg),
      _buildCommonFields(_dummyConfig),
    ];
  }

  List<Widget> _buildUsernameFields() {
    return [
      TextFormField(
        decoration: _inputDecoration('Username', 'testuser01'),
        style: const TextStyle(color: AppColors.textPrimary),
        validator: _validateUsername,
      ),
      const SizedBox(height: AppSpacing.lg),
      _buildCommonFields(_dummyConfig),
    ];
  }

  Widget _buildCommonFields(RegistrationConfig config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _nicknameCtrl,
          decoration: _inputDecoration('Nickname', 'Display name'),
          style: const TextStyle(color: AppColors.textPrimary),
          validator: _validateNickname,
        ),
        const SizedBox(height: AppSpacing.lg),
        TextFormField(
          controller: _passwordCtrl,
          obscureText: true,
          decoration: _inputDecoration('Password', 'At least 6 characters'),
          style: const TextStyle(color: AppColors.textPrimary),
          validator: _validatePassword,
        ),
        const SizedBox(height: AppSpacing.lg),
        TextFormField(
          controller: _verifyCodeCtrl,
          decoration: _inputDecoration('Verify code', 'Use 666666 in test mode'),
          style: const TextStyle(color: AppColors.textPrimary),
          keyboardType: TextInputType.number,
          validator: _validateVerifyCode,
        ),
        const SizedBox(height: AppSpacing.xl),
        _buildPrivacySection(config),
      ],
    );
  }

  Widget _buildPrivacySection(RegistrationConfig config) {
    final hasPolicy = config.hasPrivacyPolicy;
    final hasAgreement = config.hasUserAgreement;

    if (!hasPolicy && !hasAgreement) {
      return CheckboxListTile(
        value: _privacyAccepted,
        onChanged: (v) =>
            setState(() => _privacyAccepted = v ?? false),
        title: const Text(
          'I agree to the terms',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        controlAffinity: ListTileControlAffinity.leading,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CheckboxListTile(
          value: _privacyAccepted,
          onChanged: (v) => setState(() => _privacyAccepted = v ?? false),
          title: const Text(
            'I agree to the terms and privacy policy',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          subtitle: _privacyHintText(hasPolicy, hasAgreement),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        if (hasPolicy) ..._buildAgreementText(
          header: 'Privacy Policy (v${config.privacyPolicyVersion})',
          body: config.privacyPolicyMarkdown,
        ),
        if (hasAgreement) ..._buildAgreementText(
          header: 'User Agreement (v${config.userAgreementVersion})',
          body: config.userAgreementMarkdown,
        ),
      ],
    );
  }

  Widget? _privacyHintText(bool hasPolicy, bool hasAgreement) {
    if (!hasPolicy && !hasAgreement) return null;
    return const Text(
      'Required',
      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
    );
  }

  List<Widget> _buildAgreementText({
    required String header,
    required String body,
  }) {
    if (body.isEmpty) return const [];
    return [
      const SizedBox(height: AppSpacing.sm),
      Container(
        constraints: const BoxConstraints(maxHeight: 200),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: SingleChildScrollView(
          child: MarkdownBody(
            data: '# $header\n\n$body',
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              h1: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildSubmit() {
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _submit,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      child: _isSubmitting
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.textPrimary),
              ),
            )
          : const Text('Sign up', style: TextStyle(fontSize: 16)),
    );
  }

  InputDecoration _inputDecoration(String label, String hint) => InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textDisabled),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      );

  String? _validateAreaCode(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    if (!v.startsWith('+')) return 'Use + prefix';
    return null;
  }

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    if (v.trim().length < 6) return 'Invalid phone';
    return null;
  }

  String? _validateNickname(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    if (v.length < 6) return 'At least 6 characters';
    return null;
  }

  String? _validateUsername(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    return null;
  }

  String? _validateVerifyCode(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    if (v.trim().length < 4) return 'Invalid code';
    return null;
  }

  static final RegistrationConfig _dummyConfig =
      RegistrationConfig(allowRegister: false, availableMethods: []);
}