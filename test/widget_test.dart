import 'package:flutter_test/flutter_test.dart';
import 'package:wealthflow/core/categorizer.dart';
import 'package:wealthflow/core/insights.dart';
import 'package:wealthflow/core/models.dart';

Txn tx(String id, double amt, String cat, DateTime d, {bool income = false}) =>
    Txn(id: id, isIncome: income, amount: amt, category: cat, note: 'n$id', date: d);

void main() {
  test('categorizes English and Amharic notes', () {
    expect(categorize('Lunch at cafe', isIncome: false), 'food');
    expect(categorize('ታክሲ ወደ ቢሮ', isIncome: false), 'transport');
    expect(categorize('Monthly salary', isIncome: true), 'salary');
    expect(categorize('???', isIncome: false), 'other');
  });

  test('flags unusual expense and overspending', () {
    final now = DateTime(2026, 10, 20);
    final txns = [
      for (var i = 0; i < 5; i++) tx('f$i', 100, 'food', DateTime(2026, 9, 1 + i)),
      tx('big', 900, 'food', DateTime(2026, 10, 10)),
      tx('inc', 500, 'salary', DateTime(2026, 10, 1), income: true),
    ];
    final keys = buildInsights(txns: txns, budgets: [], goals: [], now: now)
        .map((i) => i.key)
        .toList();
    expect(keys, containsAll(['ins_unusual', 'ins_overspend', 'ins_top']));
  });

  test('budget over limit is reported', () {
    final now = DateTime(2026, 10, 20);
    final txns = [tx('a', 300, 'food', DateTime(2026, 10, 2))];
    final b = [Budget(id: 'b', category: 'food', limit: 200)];
    final keys = buildInsights(txns: txns, budgets: b, goals: [], now: now).map((i) => i.key);
    expect(keys, contains('ins_budget_over'));
  });
}
