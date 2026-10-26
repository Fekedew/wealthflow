import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/categorizer.dart';
import '../core/insights.dart';
import '../core/theme.dart';
import 'common.dart';
import 'dashboard.dart';

// ───────── transactions ─────────

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final s = context.store;
    if (s.txns.isEmpty) return PageBody(children: [EmptyState(l.tr('no_txns'), icon: Icons.receipt_long_rounded)]);
    return PageBody(maxWidth: 760, children: [
      for (final t in s.txns)
        Dismissible(
          key: ValueKey(t.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Theme.of(context).colorScheme.errorContainer,
            child: const Icon(Icons.delete_rounded),
          ),
          onDismissed: (_) => context.actions.deleteTxn(t.id),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            leading: CategoryAvatar(t.category),
            title: Text(t.note.isEmpty ? l.cat(t.category) : t.note,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('${l.cat(t.category)} · ${DateFormat.MMMd(l.code).format(t.date)}'),
            trailing: Text(
              '${t.isIncome ? '+' : '−'}${context.money(t.amount)}',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: t.isIncome ? incomeColor : expenseColor),
            ),
          ),
        ),
    ]);
  }
}

// ───────── budgets ─────────

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  Future<void> _edit(BuildContext context) async {
    final l = context.l;
    final limit = TextEditingController();
    String cat = expenseCategories.first;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text(l.tr('add_budget')),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              initialValue: cat,
              decoration: InputDecoration(labelText: l.tr('category')),
              items: [
                for (final c in expenseCategories) DropdownMenuItem(value: c, child: Text(l.cat(c)))
              ],
              onChanged: (v) => set(() => cat = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: limit,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: l.tr('monthly_limit')),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.tr('cancel'))),
            FilledButton(
              onPressed: () {
                final v = double.tryParse(limit.text.replaceAll(',', ''));
                if (v == null || v <= 0) return;
                context.actions.setBudget(cat, v);
                Navigator.pop(ctx);
              },
              child: Text(l.tr('save')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final s = context.store;
    return PageBody(maxWidth: 760, children: [
      Align(
        alignment: Alignment.centerRight,
        child: FilledButton.tonalIcon(
            onPressed: () => _edit(context),
            icon: const Icon(Icons.add_rounded),
            label: Text(l.tr('add_budget'))),
      ),
      const SizedBox(height: 8),
      if (s.budgets.isEmpty)
        EmptyState(l.tr('no_budgets'), icon: Icons.pie_chart_outline_rounded)
      else
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(children: [
              for (final b in s.budgets)
                BudgetRow(b, spentFor(s.txns, b.category),
                    trailing: IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => context.actions.deleteBudget(b.id))),
            ]),
          ),
        ),
    ]);
  }
}

// ───────── goals ─────────

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  Future<void> _create(BuildContext context) async {
    final l = context.l;
    final name = TextEditingController();
    final target = TextEditingController();
    DateTime? deadline;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text(l.tr('add_goal')),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: name, autofocus: true, decoration: InputDecoration(labelText: l.tr('goal_name'))),
            const SizedBox(height: 12),
            TextField(
              controller: target,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: l.tr('target')),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.event_rounded),
              label: Text(deadline == null ? l.tr('deadline') : DateFormat.yMMMd(l.code).format(deadline!)),
              onPressed: () async {
                final d = await showDatePicker(
                  context: ctx,
                  initialDate: DateTime.now().add(const Duration(days: 180)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (d != null) set(() => deadline = d);
              },
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.tr('cancel'))),
            FilledButton(
              onPressed: () {
                final v = double.tryParse(target.text.replaceAll(',', ''));
                if (name.text.trim().isEmpty || v == null || v <= 0) return;
                context.actions.addGoal(name.text.trim(), v, deadline);
                Navigator.pop(ctx);
              },
              child: Text(l.tr('save')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fund(BuildContext context, String id) async {
    final l = context.l;
    final c = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.tr('add_funds')),
        content: TextField(
          controller: c,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: l.tr('amount')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.tr('cancel'))),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(c.text.replaceAll(',', ''));
              if (v == null || v <= 0) return;
              context.actions.addToGoal(id, v);
              Navigator.pop(ctx);
            },
            child: Text(l.tr('save')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final s = context.store;
    return PageBody(maxWidth: 760, children: [
      Align(
        alignment: Alignment.centerRight,
        child: FilledButton.tonalIcon(
            onPressed: () => _create(context),
            icon: const Icon(Icons.add_rounded),
            label: Text(l.tr('add_goal'))),
      ),
      const SizedBox(height: 8),
      if (s.goals.isEmpty) EmptyState(l.tr('no_goals'), icon: Icons.flag_outlined),
      for (final g in s.goals)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                      child: Text(g.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
                  Text('${(g.progress * 100).round()}%',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: brand)),
                  IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      onPressed: () => context.actions.deleteGoal(g.id)),
                ]),
                ProgressBar(value: g.progress, color: brand),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: Text(
                      '${l.tr('saved')} ${context.money(g.saved)} / ${context.money(g.target)}'
                      '${g.deadline == null ? '' : '  ·  ${DateFormat.yMMMd(l.code).format(g.deadline!)}'}',
                      style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 13),
                    ),
                  ),
                  TextButton.icon(
                      onPressed: () => _fund(context, g.id),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(l.tr('add_funds'))),
                ]),
              ]),
            ),
          ),
        ),
    ]);
  }
}

// ───────── insights ─────────

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.store;
    final items = buildInsights(txns: s.txns, budgets: s.budgets, goals: s.goals);
    return PageBody(maxWidth: 760, children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [for (final i in items) InsightTile(i)]),
        ),
      ),
    ]);
  }
}

// ───────── settings ─────────

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final s = context.store;
    return PageBody(maxWidth: 640, children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.tr('account'), style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.account_circle_rounded, size: 40),
              const SizedBox(width: 12),
              Expanded(child: Text(s.isGuest ? l.tr('guest_mode') : (s.email ?? ''))),
              OutlinedButton(onPressed: s.signOut, child: Text(l.tr('sign_out'))),
            ]),
          ]),
        ),
      ),
      const SizedBox(height: 16),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.tr('dark_mode'), style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(value: ThemeMode.system, label: Text(l.tr('system'))),
                ButtonSegment(value: ThemeMode.light, label: Text(l.tr('light'))),
                ButtonSegment(value: ThemeMode.dark, label: Text(l.tr('dark'))),
              ],
              selected: {s.themeMode},
              onSelectionChanged: (v) => s.setThemeMode(v.first),
            ),
            const SizedBox(height: 20),
            Text(l.tr('language'), style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'en', label: Text('English')),
                ButtonSegment(value: 'am', label: Text('አማርኛ')),
              ],
              selected: {s.locale.languageCode},
              onSelectionChanged: (v) => s.setLocale(v.first),
            ),
            const SizedBox(height: 20),
            Text(l.tr('currency'), style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Br', label: Text('Br')),
                ButtonSegment(value: '\$', label: Text('\$')),
                ButtonSegment(value: '€', label: Text('€')),
                ButtonSegment(value: '£', label: Text('£')),
              ],
              selected: {s.currency},
              onSelectionChanged: (v) => s.setCurrency(v.first),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 16),
      Card(
        child: ListTile(
          leading: const Icon(Icons.info_outline_rounded),
          title: Text(l.tr('about'), style: const TextStyle(fontWeight: FontWeight.w700)),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => context.push('/about'),
        ),
      ),
    ]);
  }
}
