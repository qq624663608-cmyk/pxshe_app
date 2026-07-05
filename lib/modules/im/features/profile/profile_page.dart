import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';

import 'package:pxshe_app/_core/theme/app_colors.dart';
import 'package:pxshe_app/modules/im/bloc/connection_cubit.dart' as im;
import 'package:pxshe_app/modules/im/bloc/group_cubit.dart';

/// Profile / "me" page — shows connection status and group list.
/// Phase 2.5 placeholder.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    context.read<GroupCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          'Profile',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: ListView(
        children: [
          const _SectionHeader('Connection'),
          BlocBuilder<im.ConnectionCubit, im.ConnectionState>(
            builder: (context, conn) => ListTile(
              title: const Text(
                'IM status',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              subtitle: Text(
                _statusLabel(conn.status),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              leading: Icon(
                _statusIcon(conn.status),
                color: AppColors.primary,
              ),
            ),
          ),
          const Divider(height: 1),
          const _SectionHeader('Groups'),
          BlocBuilder<GroupCubit, GroupState>(
            builder: (context, state) {
              if (state.status == GroupStatus.loading) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (state.status == GroupStatus.error) {
                return ListTile(
                  title: Text(state.error ?? 'unknown',
                      style: const TextStyle(color: AppColors.error)),
                );
              }
              if (state.groups.isEmpty) {
                return const ListTile(
                  title: Text(
                    'No groups yet',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }
              return Column(
                children: [
                  for (final g in state.groups) _GroupTile(info: g),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _statusLabel(im.ConnectionStatus status) {
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

  IconData _statusIcon(im.ConnectionStatus status) {
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
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({required this.info});
  final GroupInfo info;

  @override
  Widget build(BuildContext context) {
    final name = (info.groupName?.trim().isNotEmpty ?? false)
        ? info.groupName!
        : (info.groupID);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.surface,
        backgroundImage:
            (info.faceURL?.isNotEmpty ?? false) ? NetworkImage(info.faceURL!) : null,
        child: (info.faceURL?.isEmpty ?? true)
            ? Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(color: AppColors.textPrimary),
              )
            : null,
      ),
      title: Text(name, style: const TextStyle(color: AppColors.textPrimary)),
      subtitle: Text(
        '${info.memberCount ?? 0} members',
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      trailing: Text(
        info.groupID,
        style: const TextStyle(color: AppColors.textDisabled, fontSize: 12),
      ),
    );
  }
}