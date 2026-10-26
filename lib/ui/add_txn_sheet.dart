import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/categorizer.dart';
import 'common.dart';

Future<void> showAddTxnSheet(BuildContext context, {bool income = false}) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (_) => _AddTxn(income: income),
    );

class _AddTxn extends StatefulWidget {
  const _AddTxn({required this.income});
  final bool income;

  @override
  State<_AddTxn> createState() => _AddTxnState();
}

class _AddTxnState extends State<_AddTxn> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late bool _income = widget.income;
  String? _picked; // user-chosen category; null = auto
  DateTime _date = DateTime.now();

  String get _auto => categorize(_note.text, isIncome: _income);
  String get _category => _picked ?? _auto;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final cats = _income ? incomeCategories : expenseCategories;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                      value: false,
                      label: Text(l.tr('expense')),
                      icon: const Icon(Icons.arrow_upward_rounded)),
                  ButtonSegment(
                      value: true,
                      label: Text(l.tr('income')),
                      icon: const Icon(Icons.arrow_downward_rounded)),
                ],
                selected: {_income},
                onSelectionChanged: (s) => setState(() {
                  _income = s.first;
                  _picked = null;
                }),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amount,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                    labelText: l.tr('amount'), prefixText: '${context.actions.currency} '),
                validator: (v) {
                  final n = double.tryParse((v ?? '').replaceAll(',', ''));
                  return n == null || n <= 0 ? l.tr('amount_invalid') : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _note,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(labelText: l.tr('note')),
              ),
              const SizedBox(height: 14),
              if (_picked == null && _note.text.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('${l.tr('auto_category')}: ${l.cat(_auto)}',
                      style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in cats)
                    ChoiceChip(
                      label: Text(l.cat(c)),
                      selected: _category == c,
                      onSelected: (_) => setState(() => _picked = c),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                icon: const Icon(Icons.event_rounded),
                label: Text(DateFormat.yMMMd(l.code).format(_date)),
                onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) setState(() => _date = d);
                },
              ),
              const SizedBox(height: 18),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                onPressed: () {
                  if (!_form.currentState!.validate()) return;
                  context.actions.addTxn(
                    isIncome: _income,
                    amount: double.parse(_amount.text.replaceAll(',', '')),
                    category: _category,
                    note: _note.text.trim(),
                    date: _date,
                  );
                  Navigator.pop(context);
                },
                child: Text(l.tr('save')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
