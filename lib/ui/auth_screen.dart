import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/store.dart';
import 'common.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _signUp = false, _busy = false, _obscure = true;
  String? _message;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final store = context.actions;
    setState(() {
      _busy = true;
      _message = null;
    });
    final err = _signUp
        ? await store.signUp(_email.text.trim(), _password.text)
        : await store.signIn(_email.text.trim(), _password.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = err == 'check_inbox' ? context.l.tr('check_inbox') : err;
      if (err == 'check_inbox') _signUp = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final store = context.store;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => store.setLocale(
                          store.locale.languageCode == 'en' ? 'am' : 'en',
                        ),
                        icon: const Icon(Icons.translate_rounded, size: 18),
                        label: Text(
                          store.locale.languageCode == 'en'
                              ? 'አማርኛ'
                              : 'English',
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 64,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: brand,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.waves_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      l.tr('app_name'),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      l.tr('tagline'),
                      style: TextStyle(color: scheme.outline),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(
                        labelText: l.tr('email'),
                        prefixIcon: const Icon(Icons.mail_outline_rounded),
                      ),
                      validator: (v) =>
                          (v == null || !v.contains('@') || !v.contains('.'))
                          ? l.tr('email_invalid')
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: l.tr('password'),
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6)
                          ? l.tr('password_short')
                          : null,
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 12),
                      Text(_message!, style: TextStyle(color: scheme.error)),
                    ],
                    if (!backendConfigured) ...[
                      const SizedBox(height: 12),
                      Text(
                        l.tr('backend_missing'),
                        style: TextStyle(color: scheme.outline),
                      ),
                    ],
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: _busy || !backendConfigured ? null : _submit,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l.tr(_signUp ? 'sign_up' : 'sign_in')),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _signUp = !_signUp),
                      child: Text(
                        l.tr(_signUp ? 'have_account' : 'no_account'),
                      ),
                    ),
                    const Divider(height: 28),
                    OutlinedButton(
                      onPressed: store.continueAsGuest,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: Text(l.tr('continue_guest')),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.tr('guest_note'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.outline, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
