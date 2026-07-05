import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pxshe_app/_core/theme/app_colors.dart';
import 'package:pxshe_app/modules/im/bloc/connection_cubit.dart' as im;

/// Placeholder page for phase 2.1 — only shows the current connection
/// status. Subsequent phases replace this with the chat list / chat page
/// / contacts / profile (see docs/PHASE2_PLAN.md).
///
/// `connection_cubit.dart` is imported with the `im.` prefix because
/// `ConnectionState` also exists in `package:flutter/widgets/async.dart`
/// (Conflict with `AnimatedState` / `State` superclass).
class ConnectionStatusPage extends StatelessWidget {
  const ConnectionStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          'IM',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: BlocBuilder<im.ConnectionCubit, im.ConnectionState>(
        builder: (context, state) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_iconFor(state.status),
                      size: 64, color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(_labelFor(state.status),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                      )),
                  const SizedBox(height: 8),
                  const Text(
                    'Phase 2.1 placeholder — see docs/PHASE2_PLAN.md',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _iconFor(im.ConnectionStatus status) {
    switch (status) {
      case im.ConnectionStatus.connected:
        return Icons.cloud_done_outlined;
      case im.ConnectionStatus.connecting:
        return Icons.cloud_sync_outlined;
      case im.ConnectionStatus.disconnected:
        return Icons.cloud_off_outlined;
      case im.ConnectionStatus.kickedOffline:
        return Icons.no_accounts_outlined;
      case im.ConnectionStatus.initial:
        return Icons.hourglass_empty_outlined;
    }
  }

  String _labelFor(im.ConnectionStatus status) {
    switch (status) {
      case im.ConnectionStatus.connected:
        return 'Connected';
      case im.ConnectionStatus.connecting:
        return 'Connecting…';
      case im.ConnectionStatus.disconnected:
        return 'Disconnected';
      case im.ConnectionStatus.kickedOffline:
        return 'Kicked offline';
      case im.ConnectionStatus.initial:
        return 'Initial';
    }
  }
}