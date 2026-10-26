import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../core/categorizer.dart';
import '../core/models.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
bool get backendConfigured => supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;

const _tables = ['transactions', 'budgets', 'goals'];

/// App state. Reads always come from memory (backed by a local cache), writes
/// are applied locally first and pushed to Supabase through a persistent
/// queue, so the app is fully usable offline.
class Store extends ChangeNotifier {
  Store(this._prefs) {
    _guest = _prefs.getBool('wf.guest') ?? false;
    _themeMode = ThemeMode.values.byName(_prefs.getString('wf.theme') ?? 'system');
    _locale = Locale(_prefs.getString('wf.lang') ?? 'en');
    currency = _prefs.getString('wf.currency') ?? 'Br';
  }

  final SharedPreferences _prefs;
  static const _uuid = Uuid();

  late bool _guest;
  late ThemeMode _themeMode;
  late Locale _locale;
  late String currency;

  List<Txn> txns = [];
  List<Budget> budgets = [];
  List<Goal> goals = [];
  List<Map<String, dynamic>> _queue = [];

  bool online = true;
  bool syncing = false;
  RealtimeChannel? _channel;
  Timer? _debounce;
  StreamSubscription? _authSub, _netSub;
  bool _flushing = false;

  SupabaseClient? get _sb => backendConfigured ? Supabase.instance.client : null;
  String? get userId => _sb?.auth.currentUser?.id;
  bool get isGuest => _guest && userId == null;
  bool get authed => userId != null || _guest;
  String? get email => _sb?.auth.currentUser?.email;
  int get pendingChanges => _queue.length;
  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  String get _scope => userId ?? 'guest';

  Future<void> init() async {
    if (_sb != null) {
      _authSub = _sb!.auth.onAuthStateChange.listen((_) => _onAuthChanged());
    }
    _netSub = Connectivity().onConnectivityChanged.listen((r) {
      final now = !r.contains(ConnectivityResult.none);
      if (now != online) {
        online = now;
        notifyListeners();
        if (now) sync();
      }
    });
    await _onAuthChanged();
  }

  Future<void> _onAuthChanged() async {
    _channel?.unsubscribe();
    _channel = null;
    if (userId != null) _guest = false;
    _loadLocal();
    notifyListeners();
    if (userId != null) {
      _subscribeRealtime();
      await sync();
    }
  }

  // ───────── auth ─────────

  Future<String?> signIn(String email, String password) async {
    try {
      await _sb!.auth.signInWithPassword(email: email, password: password);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Network error';
    }
  }

  Future<String?> signUp(String email, String password) async {
    try {
      final res = await _sb!.auth.signUp(email: email, password: password);
      // With "Confirm email" disabled a session is returned straight away.
      return res.session == null ? 'check_inbox' : null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Network error';
    }
  }

  Future<void> continueAsGuest() async {
    _guest = true;
    await _prefs.setBool('wf.guest', true);
    _loadLocal();
    notifyListeners();
  }

  Future<void> signOut() async {
    _guest = false;
    await _prefs.setBool('wf.guest', false);
    if (_sb?.auth.currentUser != null) await _sb!.auth.signOut();
    txns = [];
    budgets = [];
    goals = [];
    _queue = [];
    notifyListeners();
  }

  // ───────── preferences ─────────

  void setThemeMode(ThemeMode m) {
    _themeMode = m;
    _prefs.setString('wf.theme', m.name);
    notifyListeners();
  }

  void setLocale(String code) {
    _locale = Locale(code);
    _prefs.setString('wf.lang', code);
    notifyListeners();
  }

  void setCurrency(String c) {
    currency = c.isEmpty ? 'Br' : c;
    _prefs.setString('wf.currency', currency);
    notifyListeners();
  }

  // ───────── local cache ─────────

  void _loadLocal() {
    final raw = _prefs.getString('wf.data.$_scope');
    txns = [];
    budgets = [];
    goals = [];
    if (raw != null) {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      txns = [for (final j in m['transactions'] ?? []) Txn.fromJson(j)];
      budgets = [for (final j in m['budgets'] ?? []) Budget.fromJson(j)];
      goals = [for (final j in m['goals'] ?? []) Goal.fromJson(j)];
    }
    _queue = [
      for (final s in _prefs.getStringList('wf.queue.$_scope') ?? [])
        jsonDecode(s) as Map<String, dynamic>
    ];
    _sortTxns();
  }

  void _persist() {
    _prefs.setString(
      'wf.data.$_scope',
      jsonEncode({
        'transactions': txns.map((t) => t.toJson()).toList(),
        'budgets': budgets.map((b) => b.toJson()).toList(),
        'goals': goals.map((g) => g.toJson()).toList(),
      }),
    );
    _prefs.setStringList('wf.queue.$_scope', _queue.map(jsonEncode).toList());
  }

  void _sortTxns() => txns.sort((a, b) => b.date.compareTo(a.date));

  void _commit(String table, {Map<String, dynamic>? upsert, String? delete}) {
    if (userId != null) {
      // Collapse earlier queued ops for the same row.
      final id = upsert?['id'] ?? delete;
      _queue.removeWhere((q) => q['t'] == table && q['id'] == id);
      _queue.add({'t': table, 'id': id, if (upsert != null) 'row': upsert});
    }
    _persist();
    notifyListeners();
    if (userId != null) flush();
  }

  // ───────── mutations ─────────

  void addTxn({
    required bool isIncome,
    required double amount,
    required String category,
    required String note,
    required DateTime date,
  }) {
    final t = Txn(
        id: _uuid.v4(),
        isIncome: isIncome,
        amount: amount,
        category: category,
        note: note,
        date: date);
    txns.add(t);
    _sortTxns();
    _commit('transactions', upsert: t.toJson());
  }

  void deleteTxn(String id) {
    txns.removeWhere((t) => t.id == id);
    _commit('transactions', delete: id);
  }

  void setBudget(String category, double limit) {
    final existing = budgets.where((b) => b.category == category).firstOrNull;
    final b = Budget(
        id: existing?.id ?? _uuid.v4(), category: category, limit: limit);
    budgets
      ..removeWhere((x) => x.id == b.id)
      ..add(b);
    _commit('budgets', upsert: b.toJson());
  }

  void deleteBudget(String id) {
    budgets.removeWhere((b) => b.id == id);
    _commit('budgets', delete: id);
  }

  void addGoal(String name, double target, DateTime? deadline) {
    final g = Goal(
        id: _uuid.v4(),
        name: name,
        target: target,
        saved: 0,
        deadline: deadline);
    goals.add(g);
    _commit('goals', upsert: g.toJson());
  }

  void addToGoal(String id, double amount) {
    final i = goals.indexWhere((g) => g.id == id);
    if (i < 0) return;
    goals[i] = goals[i].copyWith(saved: goals[i].saved + amount);
    _commit('goals', upsert: goals[i].toJson());
  }

  void deleteGoal(String id) {
    goals.removeWhere((g) => g.id == id);
    _commit('goals', delete: id);
  }

  // ───────── sync ─────────

  Future<void> flush() async {
    final sb = _sb;
    if (sb == null || userId == null || _flushing) return;
    _flushing = true;
    try {
      while (_queue.isNotEmpty) {
        final op = _queue.first;
        final table = sb.from(op['t'] as String);
        if (op['row'] != null) {
          await table.upsert(op['row'] as Map<String, dynamic>);
        } else {
          await table.delete().eq('id', op['id'] as String);
        }
        _queue.removeAt(0);
        _persist();
      }
      if (!online) {
        online = true;
        notifyListeners();
      }
    } catch (_) {
      // Keep the queue; retried on reconnect or next sync.
      online = false;
      notifyListeners();
    } finally {
      _flushing = false;
    }
  }

  /// Pushes pending writes, then replaces local data with the server copy.
  Future<void> sync() async {
    final sb = _sb;
    if (sb == null || userId == null) return;
    syncing = true;
    notifyListeners();
    try {
      await flush();
      if (_queue.isEmpty) {
        final results = await Future.wait([
          for (final t in _tables) sb.from(t).select(),
        ]);
        txns = [for (final j in results[0]) Txn.fromJson(j)];
        budgets = [for (final j in results[1]) Budget.fromJson(j)];
        goals = [for (final j in results[2]) Goal.fromJson(j)];
        _sortTxns();
        _persist();
        online = true;
      }
    } catch (_) {
      online = false;
    } finally {
      syncing = false;
      notifyListeners();
    }
  }

  void _subscribeRealtime() {
    final sb = _sb!;
    final ch = sb.channel('wf-${userId!}');
    for (final t in _tables) {
      ch.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: t,
        filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId!),
        callback: (_) {
          _debounce?.cancel();
          _debounce = Timer(const Duration(milliseconds: 400), sync);
        },
      );
    }
    ch.subscribe();
    _channel = ch;
  }

  // ───────── derived helpers ─────────

  String suggestCategory(String note, bool isIncome) =>
      categorize(note, isIncome: isIncome);

  @override
  void dispose() {
    _authSub?.cancel();
    _netSub?.cancel();
    _debounce?.cancel();
    _channel?.unsubscribe();
    super.dispose();
  }
}
