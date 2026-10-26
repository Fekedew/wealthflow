import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../data/store.dart';

extension Ctx on BuildContext {
  L10n get l => L10n.of(this);
  Store get store => watch<Store>();
  Store get actions => read<Store>();

  String money(double v) =>
      '${read<Store>().currency} ${NumberFormat('#,##0.##').format(v)}';

  String compactMoney(double v) => NumberFormat.compact().format(v);
}

/// Card with a title, used for every dashboard section.
class Section extends StatelessWidget {
  const Section({super.key, required this.title, required this.child, this.trailing});
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                    child: Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700))),
                if (trailing != null) trailing!,
              ]),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState(this.message, {super.key, this.icon = Icons.inbox_rounded});
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 40, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 10),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.outline)),
          ]),
        ),
      );
}

class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar(this.id, {super.key, this.size = 40});
  final String id;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = categoryColors[id] ?? Colors.grey;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          color: c.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(12)),
      child: Icon(categoryIcons[id] ?? Icons.category_rounded,
          color: c, size: size * 0.52),
    );
  }
}

class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.value, required this.color});
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: value.clamp(0, 1),
          minHeight: 9,
          color: color,
          backgroundColor: color.withValues(alpha: 0.15),
        ),
      );
}

/// Centers content with a max width so wide screens stay readable.
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children, this.maxWidth = 1100});
  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: children,
          ),
        ),
      );
}
