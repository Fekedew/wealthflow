import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/l10n.dart';
import 'core/theme.dart';
import 'data/store.dart';
import 'ui/about_screen.dart';
import 'ui/auth_screen.dart';
import 'ui/dashboard.dart';
import 'ui/screens.dart';
import 'ui/shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(isOptional: true);
  await initializeDateFormatting();
  if (backendConfigured) {
    await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);
  }
  final store = Store(await SharedPreferences.getInstance());
  await store.init();
  runApp(ChangeNotifierProvider.value(value: store, child: const WealthFlowApp()));
}

class WealthFlowApp extends StatefulWidget {
  const WealthFlowApp({super.key});

  @override
  State<WealthFlowApp> createState() => _WealthFlowAppState();
}

class _WealthFlowAppState extends State<WealthFlowApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final store = context.read<Store>();
    _router = GoRouter(
      refreshListenable: store,
      redirect: (context, state) {
        final onAuth = state.uri.path == '/auth';
        if (!store.authed) return onAuth ? null : '/auth';
        return onAuth ? '/' : null;
      },
      routes: [
        GoRoute(path: '/auth', builder: (_, _) => const AuthScreen()),
        GoRoute(path: '/about', builder: (_, _) => const AboutScreen()),
        ShellRoute(
          builder: (_, __, child) => Shell(child: child),
          routes: [
            GoRoute(path: '/', builder: (_, _) => const DashboardScreen()),
            GoRoute(path: '/transactions', builder: (_, _) => const TransactionsScreen()),
            GoRoute(path: '/budgets', builder: (_, _) => const BudgetsScreen()),
            GoRoute(path: '/goals', builder: (_, _) => const GoalsScreen()),
            GoRoute(path: '/insights', builder: (_, _) => const InsightsScreen()),
            GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<Store>();
    return MaterialApp.router(
      title: 'WealthFlow',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      themeMode: store.themeMode,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      locale: store.locale,
      supportedLocales: L10n.supported,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
