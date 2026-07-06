import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';

import '../app_router.dart';
import '../logger.dart';
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
    final isAuthError = apiException.errorKey.isAuthError;

    if (isAuthError) {
      onUnauthorized?.call();
    }

    if (isOnAuthPage && isAuthError) {
      return;
    }

    _showSnack(context, message);
  }

  /// Try 3 messenger sources in order:
  /// 1. local context's `ScaffoldMessenger.of` (fastest, normal case)
  /// 2. rootNavigatorKey's context (fallback if local fails)
  /// 3. log (last resort so user at least sees something in adb logcat)
  static void _showSnack(BuildContext context, String message) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final messenger = ScaffoldMessenger.maybeOf(context) ??
          _rootMessenger();
      if (messenger == null) {
        Log.e('ErrorHandler: cannot show SnackBar, no ScaffoldMessenger: $message');
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          duration: AppDurations.snack,
        ),
      );
    });
  }

  static ScaffoldMessengerState? _rootMessenger() {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return null;
    return ScaffoldMessenger.maybeOf(ctx);
  }
}
