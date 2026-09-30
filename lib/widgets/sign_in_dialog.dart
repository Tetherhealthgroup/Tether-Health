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
  final _confirmPassword = TextEditingController();
  bool _creatingAccount = false;
  String? _confirmationEmail;
  bool _confirmationResent = false;
  bool _recoveryRequested = false;

  @override
  void initState() {
    super.initState();
    widget.account.addListener(_accountChanged);
  }

  void _accountChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.account.removeListener(_accountChanged);
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_creatingAccount) {
      final success = await widget.account.signIn(
        email: _email.text,
        password: _password.text,
      );
      if (success && mounted) Navigator.pop(context, true);
      if (mounted) setState(() {});
      return;
    }

    final outcome = await widget.account.signUp(
      email: _email.text,
      password: _password.text,
    );
    if (!mounted) return;
    if (outcome == AccountSignUpOutcome.authenticated) {
      Navigator.pop(context, true);
      return;
    }
    if (outcome == AccountSignUpOutcome.emailConfirmationRequired) {
      setState(() {
        _confirmationEmail = _email.text.trim();
        _confirmationResent = false;
        _password.clear();
        _confirmPassword.clear();
      });
      return;
    }
    if (outcome == AccountSignUpOutcome.accountCreatedSignInRequired) {
      setState(() {
        _creatingAccount = false;
        _password.clear();
        _confirmPassword.clear();
      });
      return;
    }
    setState(() {});
  }

  Future<void> _resendConfirmation() async {
    final email = _confirmationEmail;
    if (email == null) return;
    final sent = await widget.account.resendSignUpConfirmation(email: email);
    if (!mounted) return;
    setState(() => _confirmationResent = sent);
  }

  Future<void> _requestPasswordReset() async {
    final email = _email.text.trim();
    if (!email.contains('@') || !email.contains('.')) {
      _formKey.currentState?.validate();
      return;
    }
    final requested = await widget.account.requestPasswordReset(email: email);
    if (mounted) setState(() => _recoveryRequested = requested);
  }

  void _showSignIn() {
    widget.account.clearError();
    setState(() {
      _creatingAccount = false;
      _confirmationEmail = null;
      _confirmationResent = false;
    });
  }

  void _toggleMode() {
    widget.account.clearError();
    setState(() {
      _creatingAccount = !_creatingAccount;
      _confirmationEmail = null;
      _confirmationResent = false;
      _password.clear();
      _confirmPassword.clear();
      _formKey.currentState?.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final confirmationEmail = _confirmationEmail;
    return AlertDialog(
      key: const ValueKey('account-dialog'),
      scrollable: true,
      title: Text(
        confirmationEmail != null
            ? 'Check your email'
            : _creatingAccount
                ? 'Create your BreatheFree account'
                : 'Sign in to BreatheFree',
      ),
      content: confirmationEmail == null
          ? _buildAccountForm(context)
          : _buildConfirmation(context, confirmationEmail),
      actions: confirmationEmail == null
          ? _buildFormActions()
          : _buildConfirmationActions(),
    );
  }

  Widget _buildAccountForm(BuildContext context) => Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!widget.account.enabled)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Account services are not configured for this build.',
                ),
              ),
            TextFormField(
              key: const ValueKey('sign-in-email'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (value) => value != null &&
                      value.trim().contains('@') &&
                      value.trim().contains('.')
                  ? null
                  : 'Enter a valid email.',
            ),
            TextFormField(
              key: const ValueKey('sign-in-password'),
              controller: _password,
              obscureText: true,
              autofillHints: [
                _creatingAccount
                    ? AutofillHints.newPassword
                    : AutofillHints.password,
              ],
              textInputAction: _creatingAccount
                  ? TextInputAction.next
                  : TextInputAction.done,
              decoration: InputDecoration(
                labelText: _creatingAccount ? 'Create password' : 'Password',
                helperText:
                    _creatingAccount ? 'Use at least 8 characters.' : null,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return _creatingAccount
                      ? 'Create a password.'
                      : 'Enter your password.';
                }
                if (_creatingAccount && value.length < 8) {
                  return 'Use at least 8 characters.';
                }
                return null;
              },
              onFieldSubmitted: (_) {
                if (!_creatingAccount) _submit();
              },
            ),
            if (!_creatingAccount)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  key: const ValueKey('forgot-password'),
                  onPressed: widget.account.busy ? null : _requestPasswordReset,
                  child: const Text('Forgot password?'),
                ),
              ),
            if (_recoveryRequested)
              Semantics(
                liveRegion: true,
                child: const Text(
                  'If an account exists for that address, a recovery link was requested.',
                  key: ValueKey('password-recovery-requested'),
                ),
              ),
            if (_creatingAccount)
              TextFormField(
                key: const ValueKey('sign-up-confirm-password'),
                controller: _confirmPassword,
                obscureText: true,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.done,
                decoration:
                    const InputDecoration(labelText: 'Confirm password'),
                validator: (value) =>
                    value == _password.text ? null : 'Passwords do not match.',
                onFieldSubmitted: (_) => _submit(),
              ),
            if (widget.account.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  widget.account.errorMessage!,
                  key: const ValueKey('account-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      );

  Widget _buildConfirmation(BuildContext context, String email) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Open the confirmation link sent to $email, then return and sign in. '
            'If an account already exists for this address, no new account is created.',
            key: const ValueKey('sign-up-confirmation-message'),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            key: const ValueKey('sign-up-resend'),
            onPressed: widget.account.busy ? null : _resendConfirmation,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Resend confirmation email'),
          ),
          if (_confirmationResent)
            Text(
              'Confirmation email requested.',
              key: const ValueKey('sign-up-resend-success'),
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          if (widget.account.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                widget.account.errorMessage!,
                key: const ValueKey('account-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      );

  List<Widget> _buildFormActions() => [
        TextButton(
          onPressed: widget.account.busy ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          key: const ValueKey('account-toggle-mode'),
          onPressed: !widget.account.enabled || widget.account.busy
              ? null
              : _toggleMode,
          child: Text(_creatingAccount
              ? 'I already have an account'
              : 'Create account'),
        ),
        FilledButton(
          key: ValueKey(_creatingAccount ? 'sign-up-submit' : 'sign-in-submit'),
          onPressed:
              !widget.account.enabled || widget.account.busy ? null : _submit,
          child: widget.account.busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_creatingAccount ? 'Create account' : 'Sign in'),
        ),
      ];

  List<Widget> _buildConfirmationActions() => [
        TextButton(
          onPressed: widget.account.busy ? null : () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        FilledButton(
          key: const ValueKey('sign-up-return-to-sign-in'),
          onPressed: widget.account.busy ? null : _showSignIn,
          child: const Text('Return to sign in'),
        ),
      ];
}
