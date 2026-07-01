import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/app_durations.dart';
import 'api_exception.dart';

/// Unified error handling entry point.
/// All widget/UI code MUST go through this (AGENTS §6).
class ErrorHandler {
  static void handle(
    BuildContext context,
    Object error, {
    bool isOnAuthPage = false,
    void Function()? onUnauthorized,
  }) {
    final apiException = error is ApiException
        ? error
        : ApiException(
            errorKey: ErrorKey.unknown,
            message: error.toString(),
          );

    final message = apiException.message ?? apiException.errorKey.name;
    final isAuthError = _isAuthError(apiException.errorKey);

    if (isAuthError) {
      onUnauthorized?.call();
    }

    if (isOnAuthPage && isAuthError) {
      return;
    }

    _showSnack(context, message);
  }

  static bool _isAuthError(ErrorKey key) {
    return key == ErrorKey.tokenInvalid ||
        key == ErrorKey.tokenMissing ||
        key == ErrorKey.tokenExpired ||
        key == ErrorKey.kickedOffline;
  }

  static void _showSnack(BuildContext context, String message) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          duration: AppDurations.snack,
        ),
      );
    });
  }
}