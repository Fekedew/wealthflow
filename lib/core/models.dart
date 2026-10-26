class Txn {
  Txn({
    required this.id,
    required this.isIncome,
    required this.amount,
    required this.category,
    required this.note,
    required this.date,
  });

  final String id;
  final bool isIncome;
  final double amount;
  final String category;
  final String note;
  final DateTime date;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': isIncome ? 'income' : 'expense',
        'amount': amount,
        'category': category,
        'note': note,
        'occurred_at': date.toUtc().toIso8601String(),
      };

  factory Txn.fromJson(Map<String, dynamic> j) => Txn(
        id: j['id'] as String,
        isIncome: j['type'] == 'income',
        amount: _num(j['amount']),
        category: j['category'] as String,
        note: (j['note'] ?? '') as String,
        date: DateTime.parse(j['occurred_at'] as String).toLocal(),
      );
}

class Budget {
  Budget({required this.id, required this.category, required this.limit});

  final String id;
  final String category;
  final double limit;

  Map<String, dynamic> toJson() =>
      {'id': id, 'category': category, 'monthly_limit': limit};

  factory Budget.fromJson(Map<String, dynamic> j) => Budget(
        id: j['id'] as String,
        category: j['category'] as String,
        limit: _num(j['monthly_limit']),
      );
}

class Goal {
  Goal({
    required this.id,
    required this.name,
    required this.target,
    required this.saved,
    this.deadline,
  });

  final String id;
  final String name;
  final double target;
  final double saved;
  final DateTime? deadline;

  double get progress => target <= 0 ? 0 : (saved / target).clamp(0, 1);

  Goal copyWith({double? saved}) => Goal(
        id: id,
        name: name,
        target: target,
        saved: saved ?? this.saved,
        deadline: deadline,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'target': target,
        'saved': saved,
        'deadline': deadline == null
            ? null
            : '${deadline!.year.toString().padLeft(4, '0')}-'
                '${deadline!.month.toString().padLeft(2, '0')}-'
                '${deadline!.day.toString().padLeft(2, '0')}',
      };

  factory Goal.fromJson(Map<String, dynamic> j) => Goal(
        id: j['id'] as String,
        name: j['name'] as String,
        target: _num(j['target']),
        saved: _num(j['saved']),
        deadline:
            j['deadline'] == null ? null : DateTime.parse(j['deadline'] as String),
      );
}

double _num(Object? v) => double.parse('$v');
