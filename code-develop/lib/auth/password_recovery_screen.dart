import 'package:flutter/material.dart';

import 'account_controller.dart';

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({required this.account, super.key});

  final AccountController account;

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.account.updateRecoveredPassword(_password.text);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        key: const ValueKey('password-recovery-screen'),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          'Choose a new password',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Your recovery link was verified. Use at least 8 '
                        'characters for the new password.',
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        key: const ValueKey('recovery-new-password'),
                        controller: _password,
                        obscureText: true,
                        autofillHints: const [AutofillHints.newPassword],
                        decoration:
                            const InputDecoration(labelText: 'New password'),
                        validator: (value) => (value?.length ?? 0) >= 8
                            ? null
                            : 'Use at least 8 characters.',
                      ),
                      TextFormField(
                        key: const ValueKey('recovery-confirm-password'),
                        controller: _confirmation,
                        obscureText: true,
                        autofillHints: const [AutofillHints.newPassword],
                        decoration: const InputDecoration(
                          labelText: 'Confirm new password',
                        ),
                        validator: (value) => value == _password.text
                            ? null
                            : 'Passwords do not match.',
                        onFieldSubmitted: (_) => _save(),
                      ),
                      if (widget.account.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          widget.account.errorMessage!,
                          key: const ValueKey('recovery-error'),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        key: const ValueKey('recovery-save-password'),
                        onPressed: widget.account.busy ? null : _save,
                        child: const Text('Save new password'),
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
