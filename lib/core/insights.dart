import 'dart:math';

import 'l10n.dart';
import 'models.dart';

enum InsightLevel { good, info, warn }

class Insight {
  Insight(this.key, this.level, [this.args = const {}]);
  final String key;
  final InsightLevel level;

  /// `cat` is a category id and `amt` a double; [text] localizes both.
  final Map<String, Object> args;

  String text(L10n l, String Function(double) money) {
    final out = <String, Object>{};
    args.forEach((k, v) {
      out[k] = switch (k) {
        'cat' => l.cat(v as String),
        'amt' => money(v as double),
        _ => v,
      };
    });
    return l.tr(key, out);
  }
}

bool _sameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;

List<Insight> buildInsights({
  required List<Txn> txns,
  required List<Budget> budgets,
  required List<Goal> goals,
  DateTime? now,
}) {
  now ??= DateTime.now();
  final lastMonth = DateTime(now.year, now.month - 1);
  final month = txns.where((t) => _sameMonth(t.date, now!)).toList();
  final prev = txns.where((t) => _sameMonth(t.date, lastMonth)).toList();
  final out = <Insight>[];
  if (txns.isEmpty) return [Insight('ins_empty', InsightLevel.info)];

  double sum(Iterable<Txn> l, bool income) =>
      l.where((t) => t.isIncome == income).fold(0.0, (a, t) => a + t.amount);

  final income = sum(month, true);
  final spent = sum(month, false);
  final prevSpent = sum(prev, false);

  // Where the money goes.
  final byCat = <String, double>{};
  for (final t in month.where((t) => !t.isIncome)) {
    byCat[t.category] = (byCat[t.category] ?? 0) + t.amount;
  }
  if (byCat.isNotEmpty) {
    final top = byCat.entries.reduce((a, b) => a.value >= b.value ? a : b);
    out.add(Insight('ins_top', InsightLevel.info,
        {'cat': top.key, 'pct': (top.value / spent * 100).round()}));
    if (!budgets.any((b) => b.category == top.key)) {
      out.add(Insight('ins_no_budget', InsightLevel.info, {'cat': top.key}));
    }
  }

  // Month-over-month change.
  if (prevSpent > 0 && spent > 0) {
    final change = ((spent - prevSpent) / prevSpent * 100).round();
    if (change >= 10) {
      out.add(Insight('ins_up', InsightLevel.warn, {'pct': change}));
    } else if (change <= -10) {
      out.add(Insight('ins_down', InsightLevel.good, {'pct': -change}));
    }
  }

  // Unusual expenses: > mean + 2σ of the category history (min 4 samples),
  // otherwise > 3x the category median.
  final unusual = <Txn>[];
  for (final t in month.where((t) => !t.isIncome)) {
    final hist = txns
        .where((o) => !o.isIncome && o.category == t.category && o.id != t.id)
        .map((o) => o.amount)
        .toList()
      ..sort();
    if (hist.length < 3) continue;
    final mean = hist.reduce((a, b) => a + b) / hist.length;
    final sd = sqrt(
        hist.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / hist.length);
    final median = hist[hist.length ~/ 2];
    final isOutlier =
        hist.length >= 4 ? t.amount > mean + 2 * sd && t.amount > 1.5 * mean : t.amount > 3 * median;
    if (isOutlier) unusual.add(t);
  }
  unusual.sort((a, b) => b.amount.compareTo(a.amount));
  for (final t in unusual.take(2)) {
    out.add(Insight('ins_unusual', InsightLevel.warn, {
      'amt': t.amount,
      'cat': t.category,
      'note': t.note.isEmpty ? '—' : t.note,
    }));
  }

  // Budgets.
  for (final b in budgets) {
    final used = byCat[b.category] ?? 0;
    if (used > b.limit) {
      out.add(Insight('ins_budget_over', InsightLevel.warn,
          {'cat': b.category, 'amt': used - b.limit}));
    } else if (used >= b.limit * 0.8) {
      out.add(Insight('ins_budget_near', InsightLevel.warn,
          {'cat': b.category, 'pct': (used / b.limit * 100).round()}));
    }
  }

  // Savings rate.
  if (income > 0) {
    final rate = ((income - spent) / income * 100).round();
    if (spent > income) {
      out.add(Insight('ins_overspend', InsightLevel.warn));
    } else if (rate < 20) {
      out.add(Insight('ins_savings_low', InsightLevel.warn, {'pct': rate}));
    } else {
      out.add(Insight('ins_savings_good', InsightLevel.good, {'pct': rate}));
    }
  }

  // Goals with a deadline: monthly amount needed.
  for (final g in goals) {
    if (g.deadline == null || g.saved >= g.target) continue;
    final months = max(
        1, (g.deadline!.difference(now).inDays / 30).ceil());
    out.add(Insight('ins_goal', InsightLevel.info,
        {'amt': (g.target - g.saved) / months, 'name': g.name}));
  }

  return out;
}
