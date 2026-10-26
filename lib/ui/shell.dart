import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'add_txn_sheet.dart';
import 'command_palette.dart';
import 'common.dart';

const _tabs = [
  ('/', 'dashboard', Icons.dashboard_outlined, Icons.dashboard_rounded),
  ('/transactions', 'transactions', Icons.receipt_long_outlined, Icons.receipt_long_rounded),
  ('/budgets', 'budgets', Icons.pie_chart_outline_rounded, Icons.pie_chart_rounded),
  ('/goals', 'goals', Icons.flag_outlined, Icons.flag_rounded),
  ('/insights', 'insights', Icons.lightbulb_outline_rounded, Icons.lightbulb_rounded),
  ('/settings', 'settings', Icons.settings_outlined, Icons.settings_rounded),
];

class Shell extends StatelessWidget {
  const Shell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final store = context.store;
    final loc = GoRouterState.of(context).uri.path;
    final index = _tabs.indexWhere((t) => t.$1 == loc).clamp(0, _tabs.length - 1);
    final wide = MediaQuery.sizeOf(context).width >= 840;
    void openPalette() => showCommandPalette(context);

    final banner = (!store.online || store.pendingChanges > 0)
        ? Material(
            color: Theme.of(context).colorScheme.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(store.online ? Icons.sync_rounded : Icons.cloud_off_rounded, size: 16),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    store.online
                        ? l.tr('pending', {'n': store.pendingChanges})
                        : l.tr('offline'),
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ),
              ]),
            ),
          )
        : const SizedBox.shrink();

    final body = Column(children: [banner, Expanded(child: child)]);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): openPalette,
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): openPalette,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            title: Text(l.tr(_tabs[index].$2),
                style: const TextStyle(fontWeight: FontWeight.w800)),
            actions: [
              if (!wide)
                IconButton(
                  tooltip: l.tr('settings'),
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => context.go('/settings'),
                ),
              IconButton(
                tooltip: '${l.tr('commands')} (Ctrl/⌘ K)',
                icon: const Icon(Icons.search_rounded),
                onPressed: openPalette,
              ),
              const SizedBox(width: 4),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => showAddTxnSheet(context),
            icon: const Icon(Icons.add_rounded),
            label: Text(l.tr('add')),
          ),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: index.clamp(0, 4),
                  onDestinationSelected: (i) => context.go(_tabs[i].$1),
                  labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
                  destinations: [
                    for (final t in _tabs.take(5))
                      NavigationDestination(
                          icon: Icon(t.$3),
                          selectedIcon: Icon(t.$4),
                          label: l.tr(t.$2)),
                  ],
                ),
          body: wide
              ? Row(children: [
                  NavigationRail(
                    selectedIndex: index,
                    extended: MediaQuery.sizeOf(context).width >= 1100,
                    onDestinationSelected: (i) => context.go(_tabs[i].$1),
                    destinations: [
                      for (final t in _tabs)
                        NavigationRailDestination(
                            icon: Icon(t.$3),
                            selectedIcon: Icon(t.$4),
                            label: Text(l.tr(t.$2))),
                    ],
                  ),
                  Expanded(child: body),
                ])
              : body,
        ),
      ),
    );
  }
}
