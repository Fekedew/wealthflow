import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/insights.dart';
import '../core/models.dart';
import '../core/theme.dart';
import 'common.dart';

bool _sameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final s = context.store;
    final now = DateTime.now();
    final month = s.txns.where((t) => _sameMonth(t.date, now));
    final inc = month.where((t) => t.isIncome).fold(0.0, (a, t) => a + t.amount);
    final exp = month.where((t) => !t.isIncome).fold(0.0, (a, t) => a + t.amount);
    final balance = s.txns.fold(0.0, (a, t) => a + (t.isIncome ? t.amount : -t.amount));
    final insights =
        buildInsights(txns: s.txns, budgets: s.budgets, goals: s.goals).take(3).toList();

    final cards = <Widget>[
      Section(title: l.tr('cash_flow'), trailing: _Hint(l.tr('last_6_months')), child: _CashFlow(s.txns)),
      Section(title: l.tr('spending_trend'), trailing: _Hint(l.tr('last_30_days')), child: _Trend(s.txns)),
      Section(title: l.tr('spending_by_category'), trailing: _Hint(l.tr('this_month')), child: _Donut(s.txns)),
      Section(title: l.tr('budget_progress'), child: _BudgetBars(s.txns, s.budgets)),
      Section(title: l.tr('savings_progress'), child: _GoalBars(s.goals)),
      Section(
        title: l.tr('insights'),
        trailing: TextButton(onPressed: () => context.go('/insights'), child: const Icon(Icons.arrow_forward_rounded)),
        child: Column(children: [
          for (final i in insights) InsightTile(i),
          if (insights.isEmpty) EmptyState(l.tr('ins_empty'), icon: Icons.lightbulb_outline_rounded),
        ]),
      ),
    ];

    return PageBody(children: [
      LayoutBuilder(builder: (context, c) {
        final tiles = [
          _Stat(l.tr('balance'), balance, Icons.account_balance_wallet_rounded, brand),
          _Stat(l.tr('income'), inc, Icons.south_west_rounded, incomeColor),
          _Stat(l.tr('expense'), exp, Icons.north_east_rounded, expenseColor),
        ];
        if (c.maxWidth < 560) {
          return Column(children: [
            tiles[0],
            const SizedBox(height: 12),
            Row(children: [Expanded(child: tiles[1]), const SizedBox(width: 12), Expanded(child: tiles[2])]),
          ]);
        }
        return Row(children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: tiles[i]),
          ]
        ]);
      }),
      const SizedBox(height: 16),
      LayoutBuilder(builder: (context, c) {
        final cols = c.maxWidth >= 760 ? 2 : 1;
        final w = (c.maxWidth - 16 * (cols - 1)) / cols;
        return Wrap(spacing: 16, runSpacing: 16, children: [
          for (final card in cards) SizedBox(width: w, child: card),
        ]);
      }),
    ]);
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline));
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.icon, this.color);
  final String label;
  final double value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 12.5)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(context.money(value),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                ),
              ]),
            ),
          ]),
        ),
      );
}

FlTitlesData _titles(Widget Function(double, TitleMeta) bottom, {double? interval}) => FlTitlesData(
      leftTitles: const AxisTitles(),
      topTitles: const AxisTitles(),
      rightTitles: const AxisTitles(),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: true, reservedSize: 26, interval: interval, getTitlesWidget: bottom),
      ),
    );

FlGridData _grid(BuildContext c) => FlGridData(
      drawVerticalLine: false,
      getDrawingHorizontalLine: (_) =>
          FlLine(color: Theme.of(c).colorScheme.outlineVariant.withValues(alpha: 0.5), strokeWidth: 1),
    );

Widget _chartBox(Widget child, {double h = 200}) => SizedBox(height: h, child: child);

class _CashFlow extends StatelessWidget {
  const _CashFlow(this.txns);
  final List<Txn> txns;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = [for (var i = 5; i >= 0; i--) DateTime(now.year, now.month - i)];
    double sum(DateTime m, bool inc) => txns
        .where((t) => t.isIncome == inc && _sameMonth(t.date, m))
        .fold(0.0, (a, t) => a + t.amount);
    if (txns.isEmpty) return EmptyState(context.l.tr('no_data'), icon: Icons.bar_chart_rounded);
    final locale = context.l.code;
    return Column(children: [
      _chartBox(BarChart(BarChartData(
        gridData: _grid(context),
        borderData: FlBorderData(show: false),
        titlesData: _titles((v, meta) => SideTitleWidget(
            meta: meta,
            child: Text(DateFormat.MMM(locale).format(months[v.toInt()]),
                style: const TextStyle(fontSize: 11)))),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (g, gi, rod, ri) => BarTooltipItem(
                context.money(rod.toY),
                TextStyle(color: rod.color, fontWeight: FontWeight.w700)),
          ),
        ),
        barGroups: [
          for (var i = 0; i < months.length; i++)
            BarChartGroupData(x: i, barsSpace: 4, barRods: [
              BarChartRodData(
                  toY: sum(months[i], true),
                  color: incomeColor,
                  width: 9,
                  borderRadius: BorderRadius.circular(4)),
              BarChartRodData(
                  toY: sum(months[i], false),
                  color: expenseColor,
                  width: 9,
                  borderRadius: BorderRadius.circular(4)),
            ]),
        ],
      ))),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _Dot(incomeColor, context.l.tr('income')),
        const SizedBox(width: 18),
        _Dot(expenseColor, context.l.tr('expense')),
      ]),
    ]);
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.color, this.label);
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ]);
}

class _Trend extends StatelessWidget {
  const _Trend(this.txns);
  final List<Txn> txns;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = [for (var i = 29; i >= 0; i--) DateTime(today.year, today.month, today.day - i)];
    final spots = <FlSpot>[
      for (var i = 0; i < days.length; i++)
        FlSpot(
            i.toDouble(),
            txns
                .where((t) =>
                    !t.isIncome &&
                    t.date.year == days[i].year &&
                    t.date.month == days[i].month &&
                    t.date.day == days[i].day)
                .fold(0.0, (a, t) => a + t.amount))
    ];
    if (spots.every((p) => p.y == 0)) {
      return EmptyState(context.l.tr('no_data'), icon: Icons.show_chart_rounded);
    }
    final locale = context.l.code;
    final color = Theme.of(context).colorScheme.primary;
    return _chartBox(LineChart(LineChartData(
      gridData: _grid(context),
      borderData: FlBorderData(show: false),
      minY: 0,
      titlesData: _titles(
          (v, meta) => v > 26
              ? const SizedBox.shrink()
              : SideTitleWidget(
                  meta: meta,
                  child: Text(DateFormat.Md(locale).format(days[v.toInt()]), style: const TextStyle(fontSize: 10))),
          interval: 7),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (spots) => [
            for (final s in spots)
              LineTooltipItem(context.money(s.y), TextStyle(color: color, fontWeight: FontWeight.w700))
          ],
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.2,
          preventCurveOverShooting: true,
          color: color,
          barWidth: 3,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.12)),
        ),
      ],
    )));
  }
}

class _Donut extends StatelessWidget {
  const _Donut(this.txns);
  final List<Txn> txns;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final by = <String, double>{};
    for (final t in txns.where((t) => !t.isIncome && _sameMonth(t.date, now))) {
      by[t.category] = (by[t.category] ?? 0) + t.amount;
    }
    if (by.isEmpty) return EmptyState(context.l.tr('no_data'), icon: Icons.donut_large_rounded);
    final total = by.values.fold(0.0, (a, b) => a + b);
    final entries = by.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Row(children: [
      SizedBox(
        width: 150,
        height: 150,
        child: PieChart(PieChartData(
          centerSpaceRadius: 44,
          sectionsSpace: 2,
          sections: [
            for (final e in entries)
              PieChartSectionData(
                  value: e.value, color: categoryColors[e.key], title: '', radius: 24),
          ],
        )),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(children: [
          for (final e in entries.take(5))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: categoryColors[e.key], shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Text(context.l.cat(e.key), overflow: TextOverflow.ellipsis)),
                Text('${(e.value / total * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w700)),
              ]),
            ),
        ]),
      ),
    ]);
  }
}

class _BudgetBars extends StatelessWidget {
  const _BudgetBars(this.txns, this.budgets);
  final List<Txn> txns;
  final List<Budget> budgets;

  @override
  Widget build(BuildContext context) {
    if (budgets.isEmpty) return EmptyState(context.l.tr('no_budgets'), icon: Icons.pie_chart_outline_rounded);
    return Column(children: [for (final b in budgets) BudgetRow(b, spentFor(txns, b.category))]);
  }
}

double spentFor(List<Txn> txns, String category) {
  final now = DateTime.now();
  return txns
      .where((t) => !t.isIncome && t.category == category && _sameMonth(t.date, now))
      .fold(0.0, (a, t) => a + t.amount);
}

class BudgetRow extends StatelessWidget {
  const BudgetRow(this.b, this.spent, {super.key, this.trailing});
  final Budget b;
  final double spent;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ratio = spent / b.limit;
    final color = ratio > 1 ? expenseColor : (ratio >= 0.8 ? const Color(0xFFF59E0B) : brand);
    final l = context.l;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        CategoryAvatar(b.category, size: 38),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(l.cat(b.category), style: const TextStyle(fontWeight: FontWeight.w600))),
              Text('${context.money(spent)} ${l.tr('of')} ${context.money(b.limit)}',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline)),
            ]),
            const SizedBox(height: 6),
            ProgressBar(value: ratio, color: color),
          ]),
        ),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

class _GoalBars extends StatelessWidget {
  const _GoalBars(this.goals);
  final List<Goal> goals;

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) return EmptyState(context.l.tr('no_goals'), icon: Icons.flag_outlined);
    return Column(children: [
      for (final g in goals)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(g.name, style: const TextStyle(fontWeight: FontWeight.w600))),
              Text('${(g.progress * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 6),
            ProgressBar(value: g.progress, color: brand),
          ]),
        ),
    ]);
  }
}

class InsightTile extends StatelessWidget {
  const InsightTile(this.insight, {super.key});
  final Insight insight;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (insight.level) {
      InsightLevel.good => (Icons.trending_up_rounded, incomeColor),
      InsightLevel.warn => (Icons.warning_amber_rounded, const Color(0xFFF59E0B)),
      InsightLevel.info => (Icons.lightbulb_rounded, Theme.of(context).colorScheme.primary),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(insight.text(context.l, context.money), style: const TextStyle(height: 1.35)),
        )),
      ]),
    );
  }
}
