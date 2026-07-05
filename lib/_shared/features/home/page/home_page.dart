import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:pxshe_app/_core/theme/app_colors.dart';
import 'package:pxshe_app/_core/theme/app_radius.dart';
import 'package:pxshe_app/_core/theme/app_spacing.dart';
import 'package:pxshe_app/modules/auth/bloc/auth_bloc.dart';
import 'package:pxshe_app/modules/auth/domain/auth_repository.dart';
import 'package:pxshe_app/modules/im/bloc/connection_cubit.dart' as im;

class HomePage extends StatelessWidget {
  const HomePage({
    required this.repository,
    required this.connectionCubit,
    super.key,
  });

  final AuthRepository repository;
  final im.ConnectionCubit connectionCubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<im.ConnectionCubit>.value(
      value: connectionCubit,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: const Text(
            'Universes',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: AppColors.textPrimary),
              tooltip: 'Logout',
              onPressed: () async {
                await repository.logout();
                if (!context.mounted) return;
                context.read<AuthBloc>().add(const AuthLogoutRequested());
                if (!context.mounted) return;
                context.go('/login');
              },
            ),
          ],
        ),
        body: Column(
          children: [
            const _ConnectionBanner(),
            const Expanded(child: _EmptyState()),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Create universe (阶段 3)')),
            );
          },
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textPrimary,
          icon: const Icon(Icons.add),
          label: const Text('New universe'),
        ),
      ),
    );
  }
}

/// IM connection banner. Shows a coloured strip above the page body
/// whenever the OpenIM connection is not in the `connected` state.
/// Phase 2.6 — replaces the previous "always-hidden" state with one
/// driven by `ConnectionCubit` (IM_INTEGRATION §5.2 / AGENTS §32).
class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<im.ConnectionCubit, im.ConnectionState>(
      builder: (context, state) {
        final spec = _specFor(state.status);
        if (spec == null) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          color: spec.background,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(spec.icon, size: 16, color: spec.foreground),
              const SizedBox(width: AppSpacing.sm),
              Text(
                spec.label,
                style: TextStyle(
                  color: spec.foreground,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  _BannerSpec? _specFor(im.ConnectionStatus status) {
    switch (status) {
      case im.ConnectionStatus.connected:
      case im.ConnectionStatus.initial:
        return null;
      case im.ConnectionStatus.connecting:
        return const _BannerSpec(
          icon: Icons.cloud_sync_outlined,
          label: '重连中…',
          background: AppColors.warningBg,
          foreground: AppColors.warning,
        );
      case im.ConnectionStatus.disconnected:
        return const _BannerSpec(
          icon: Icons.cloud_off_outlined,
          label: '已断开',
          background: AppColors.errorBg,
          foreground: AppColors.error,
        );
      case im.ConnectionStatus.kickedOffline:
        return const _BannerSpec(
          icon: Icons.no_accounts_outlined,
          label: '已在其他设备登录',
          background: AppColors.errorBg,
          foreground: AppColors.error,
        );
    }
  }
}

class _BannerSpec {
  const _BannerSpec({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.public,
                size: 64,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'No universes yet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Tap the + button to create your first universe',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Text(
                    '阶段 3 待开发: 真实宇宙列表',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
