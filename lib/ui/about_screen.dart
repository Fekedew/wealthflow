import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'common.dart';

const _phone = '+251948309006';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _copy(BuildContext context) async {
    final msg = context.l.tr('copied');
    await Clipboard.setData(const ClipboardData(text: _phone));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          // Deep links have nothing to pop, so fall back to Settings.
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/settings'),
        ),
        title: Text(
          l.tr('about'),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: PageBody(
        maxWidth: 640,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: cs.primaryContainer,
                        child: Text(
                          'F',
                          style: text.headlineMedium?.copyWith(
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.tr('about_hello'),
                              style: text.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(l.tr('about_role'), style: text.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l.tr('about_body'),
                    style: text.bodyLarge?.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Section(
            title: l.tr('about_mission'),
            child: Text(
              l.tr('about_mission_body'),
              style: text.bodyMedium?.copyWith(height: 1.5),
            ),
          ),
          const SizedBox(height: 16),
          Section(
            title: l.tr('about_contact'),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.phone_rounded),
              title: const SelectableText(_phone),
              trailing: IconButton(
                tooltip: l.tr('copy_number'),
                icon: const Icon(Icons.copy_rounded),
                onPressed: () => _copy(context),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: cs.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.volunteer_activism_rounded,
                        color: cs.onPrimaryContainer,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l.tr('about_tip_title'),
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l.tr('about_tip_body'),
                    style: text.bodyMedium?.copyWith(
                      color: cs.onPrimaryContainer,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () => _copy(context),
                    icon: const Icon(Icons.copy_rounded),
                    label: Text('${l.tr('about_telebirr')} · $_phone'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
