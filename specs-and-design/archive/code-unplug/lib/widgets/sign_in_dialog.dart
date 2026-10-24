import 'package:flutter/material.dart';
import '../auth/account_controller.dart';

class SignInDialog extends StatefulWidget {
  const SignInDialog({required this.account, super.key});
  final AccountController account;

  @override
  State<SignInDialog> createState() => _SignInDialogState();
}

class _SignInDialogState extends State<SignInDialog> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await widget.account
        .signIn(email: _email.text, password: _password.text);
    if (success && mounted) {
      Navigator.pop(context, true);
      return;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Sign in to BreatheFree'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!widget.account.enabled)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                      'Account services are not configured for this build.'),
                ),
              TextFormField(
                key: const ValueKey('sign-in-email'),
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) => value != null && value.contains('@')
                    ? null
                    : 'Enter a valid email.',
              ),
              TextFormField(
                key: const ValueKey('sign-in-password'),
                controller: _password,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (value) => value != null && value.isNotEmpty
                    ? null
                    : 'Enter your password.',
              ),
              if (widget.account.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(widget.account.errorMessage!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed:
                  widget.account.busy ? null : () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            key: const ValueKey('sign-in-submit'),
            onPressed:
                !widget.account.enabled || widget.account.busy ? null : _submit,
            child: widget.account.busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Sign in'),
          ),
        ],
      );
}
