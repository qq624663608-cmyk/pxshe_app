import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';

import 'package:pxshe_app/_core/theme/app_colors.dart';
import 'package:pxshe_app/modules/im/bloc/friend_cubit.dart';

/// Contacts page — friends list + pending friend requests.
/// Phase 2.4.
class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  @override
  void initState() {
    super.initState();
    context.read<FriendCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          title: const Text(
            'Contacts',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [Tab(text: 'Friends'), Tab(text: 'Requests')],
          ),
        ),
        body: BlocBuilder<FriendCubit, FriendState>(
          builder: (context, state) {
            if (state.status == FriendStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            return TabBarView(
              children: [
                _FriendsList(items: state.friends),
                _RequestsList(
                  items: state.requests,
                  onAccept: (from) =>
                      context.read<FriendCubit>().accept(fromUserID: from),
                  onReject: (from) =>
                      context.read<FriendCubit>().reject(fromUserID: from),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FriendsList extends StatelessWidget {
  const _FriendsList({required this.items});
  final List<FriendInfo> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No friends yet',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final f = items[i];
        final name = (f.nickname?.trim().isNotEmpty ?? false)
            ? f.nickname!
            : (f.userID ?? '');
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.surface,
            backgroundImage:
                (f.faceURL?.isNotEmpty ?? false) ? NetworkImage(f.faceURL!) : null,
            child: (f.faceURL?.isEmpty ?? true)
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.textPrimary),
                  )
                : null,
          ),
          title: Text(name, style: const TextStyle(color: AppColors.textPrimary)),
          subtitle: f.userID != null
              ? Text(f.userID!,
                  style: const TextStyle(color: AppColors.textSecondary))
              : null,
        );
      },
    );
  }
}

class _RequestsList extends StatelessWidget {
  const _RequestsList({
    required this.items,
    required this.onAccept,
    required this.onReject,
  });
  final List<FriendApplicationInfo> items;
  final ValueChanged<String> onAccept;
  final ValueChanged<String> onReject;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No pending requests',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final r = items[i];
        final from = r.fromUserID ?? '';
        final reason = r.reqMsg ?? '';
        return ListTile(
          title: Text(from, style: const TextStyle(color: AppColors.textPrimary)),
          subtitle: Text(reason,
              style: const TextStyle(color: AppColors.textSecondary)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => onAccept(from),
                child: const Text('Accept'),
              ),
              TextButton(
                onPressed: () => onReject(from),
                child: const Text('Reject'),
              ),
            ],
          ),
        );
      },
    );
  }
}