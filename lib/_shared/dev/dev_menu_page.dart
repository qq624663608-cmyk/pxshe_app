import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'dev_routes.dart';

/// Dev menu page. Lists every route in the app so we can manually
/// verify navigation during end-to-end testing (阶段 2.13).
///
/// **dev-only**: registered in `devRoutes()` only when `kDebugMode` is
/// true, so production builds don't ship this page. See AGENTS §55.
class DevMenuPage extends StatelessWidget {
  const DevMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final byGroup = <String, List<DevRouteEntry>>{};
    for (final e in devRouteEntries) {
      byGroup.putIfAbsent(e.group, () => []).add(e);
    }

    final body = <Widget>[];
    for (final group in byGroup.keys) {
      body.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            group,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      );
      final entries = byGroup[group]!;
      for (final e in entries) {
        body.add(
          ListTile(
            leading: Icon(e.icon),
            title: Text(e.label),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.path,
                    style: const TextStyle(
                        fontFamily: 'monospace', fontSize: 12)),
                Text(e.description, style: const TextStyle(fontSize: 12)),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(e.path),
          ),
        );
      }
    }
    body.add(
      const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          '⚠️ 仅 kDebugMode 可见 (release build 不含此页)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dev Menu'),
        actions: [
          IconButton(
            tooltip: 'Reload',
            icon: const Icon(Icons.refresh),
            onPressed: () => context.go('/dev'),
          ),
        ],
      ),
      body: ListView(children: body),
    );
  }
}
