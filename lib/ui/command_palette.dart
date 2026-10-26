import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'add_txn_sheet.dart';
import 'common.dart';

class _Cmd {
  _Cmd(this.label, this.icon, this.run);
  final String label;
  final IconData icon;
  final VoidCallback run;
}

Future<void> showCommandPalette(BuildContext context) {
  final router = GoRouter.of(context);
  final store = context.actions;
  final l = context.l;
  final root = Navigator.of(context, rootNavigator: true).context;

  final cmds = [
    _Cmd(l.tr('cmd_add_expense'), Icons.remove_circle_outline_rounded,
        () => showAddTxnSheet(root)),
    _Cmd(l.tr('cmd_add_income'), Icons.add_circle_outline_rounded,
        () => showAddTxnSheet(root, income: true)),
    for (final (path, key, icon) in const [
      ('/', 'dashboard', Icons.dashboard_rounded),
      ('/transactions', 'transactions', Icons.receipt_long_rounded),
      ('/budgets', 'budgets', Icons.pie_chart_rounded),
      ('/goals', 'goals', Icons.flag_rounded),
      ('/insights', 'insights', Icons.lightbulb_rounded),
      ('/settings', 'settings', Icons.settings_rounded),
    ])
      _Cmd(l.tr(key), icon, () => router.go(path)),
    _Cmd(l.tr('cmd_toggle_theme'), Icons.dark_mode_rounded, () {
      final dark = Theme.of(root).brightness == Brightness.dark;
      store.setThemeMode(dark ? ThemeMode.light : ThemeMode.dark);
    }),
    _Cmd(l.tr('cmd_switch_language'), Icons.translate_rounded,
        () => store.setLocale(l.code == 'en' ? 'am' : 'en')),
    _Cmd(l.tr('sign_out'), Icons.logout_rounded, store.signOut),
  ];

  return showDialog(context: context, builder: (_) => _Palette(cmds));
}

class _Palette extends StatefulWidget {
  const _Palette(this.cmds);
  final List<_Cmd> cmds;

  @override
  State<_Palette> createState() => _PaletteState();
}

class _PaletteState extends State<_Palette> {
  final _q = TextEditingController();
  int _sel = 0;

  List<_Cmd> get _hits {
    final q = _q.text.trim().toLowerCase();
    return widget.cmds.where((c) => c.label.toLowerCase().contains(q)).toList();
  }

  void _run(_Cmd c) {
    Navigator.pop(context);
    c.run();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final hits = _hits;
    if (_sel >= hits.length) _sel = 0;
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 460),
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
                setState(() => _sel = hits.isEmpty ? 0 : (_sel + 1) % hits.length),
            const SingleActivator(LogicalKeyboardKey.arrowUp): () => setState(
                () => _sel = hits.isEmpty ? 0 : (_sel - 1 + hits.length) % hits.length),
          },
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _q,
                autofocus: true,
                onChanged: (_) => setState(() => _sel = 0),
                onSubmitted: (_) {
                  if (hits.isNotEmpty) _run(hits[_sel]);
                },
                decoration: InputDecoration(
                  hintText: l.tr('search_commands'),
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
              ),
            ),
            Flexible(
              child: hits.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(l.tr('cmd_none')))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: hits.length,
                      itemBuilder: (_, i) => ListTile(
                        dense: true,
                        selected: i == _sel,
                        leading: Icon(hits[i].icon),
                        title: Text(hits[i].label),
                        onTap: () => _run(hits[i]),
                      ),
                    ),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }
}
