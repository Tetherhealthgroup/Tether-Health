import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../account/account_data_api_client.dart';
import '../auth/account_controller.dart';

Future<void> showAccountExportDialog(
  BuildContext context,
  AccountController account,
) =>
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AccountExportDialog(account: account),
    );

Future<AccountDeletionReceipt?> showAccountDeletionDialog(
  BuildContext context,
  AccountController account, {
  Future<void> Function(String accountId)? afterDeletionAcknowledged,
}) =>
    showDialog<AccountDeletionReceipt>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AccountDeletionDialog(
        account: account,
        afterDeletionAcknowledged: afterDeletionAcknowledged,
      ),
    );

class _AccountExportDialog extends StatefulWidget {
  const _AccountExportDialog({required this.account});

  final AccountController account;

  @override
  State<_AccountExportDialog> createState() => _AccountExportDialogState();
}

class _AccountExportDialogState extends State<_AccountExportDialog> {
  final _password = TextEditingController();
  AccountDataExport? _export;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _prepare() async {
    if (_password.text.isEmpty) return;
    final result = await widget.account.exportData(password: _password.text);
    _password.clear();
    if (mounted) setState(() => _export = result);
  }

  @override
  Widget build(BuildContext context) {
    final data = _export;
    return AlertDialog(
      key: const ValueKey('account-export-dialog'),
      scrollable: true,
      title: const Text('Download a copy of your data'),
      content: SizedBox(
        width: 520,
        child: data == null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'For your privacy, enter your password again. The copy '
                    'contains your profile and saved quit plan as JSON.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const ValueKey('account-export-password'),
                    controller: _password,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    decoration:
                        const InputDecoration(labelText: 'Current password'),
                    onSubmitted: (_) => _prepare(),
                  ),
                  if (widget.account.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      widget.account.errorMessage!,
                      key: const ValueKey('account-export-error'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              )
            : Semantics(
                label: 'Your BreatheFree data copy in JSON format',
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      data.formattedJson,
                      key: const ValueKey('account-export-json'),
                    ),
                  ),
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: widget.account.busy ? null : () => Navigator.pop(context),
          child: Text(data == null ? 'Cancel' : 'Close'),
        ),
        if (data == null)
          FilledButton(
            key: const ValueKey('account-export-confirm'),
            onPressed: widget.account.busy ? null : _prepare,
            child: const Text('Prepare JSON copy'),
          )
        else
          FilledButton.icon(
            key: const ValueKey('account-export-copy'),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: data.formattedJson));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data copy copied securely.')),
              );
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy JSON'),
          ),
      ],
    );
  }
}

class _AccountDeletionDialog extends StatefulWidget {
  const _AccountDeletionDialog({
    required this.account,
    this.afterDeletionAcknowledged,
  });

  final AccountController account;
  final Future<void> Function(String accountId)? afterDeletionAcknowledged;

  @override
  State<_AccountDeletionDialog> createState() => _AccountDeletionDialogState();
}

class _AccountDeletionDialogState extends State<_AccountDeletionDialog> {
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  AccountDeletionReceipt? _receipt;
  String? _deletedAccountId;
  bool _deleting = false;
  bool _finishing = false;
  String? _finishError;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_deleting || _password.text.isEmpty || _confirmation.text != 'DELETE') {
      return;
    }
    setState(() => _deleting = true);
    final receipt = await widget.account.deleteAppData(
      password: _password.text,
    );
    _password.clear();
    _confirmation.clear();
    if (!mounted) return;
    setState(() {
      _deleting = false;
      _receipt = receipt;
      if (receipt != null) _deletedAccountId = widget.account.accountId;
    });
  }

  Future<void> _finish() async {
    final receipt = _receipt;
    final accountId = _deletedAccountId;
    if (receipt == null || accountId == null || _finishing) return;
    setState(() {
      _finishing = true;
      _finishError = null;
    });
    try {
      await widget.afterDeletionAcknowledged?.call(accountId);
      await widget.account.signOut();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _finishing = false;
        _finishError =
            'Local data cleanup could not finish. Tap Done to try again.';
      });
      return;
    }
    if (mounted) Navigator.pop(context, receipt);
  }

  @override
  Widget build(BuildContext context) {
    final receipt = _receipt;
    return PopScope(
      canPop: receipt == null && !_deleting,
      child: AlertDialog(
        key: const ValueKey('account-delete-dialog'),
        scrollable: true,
        title: Text(
          receipt == null ? 'Delete BreatheFree app data?' : 'App data deleted',
        ),
        content: receipt == null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This permanently deletes your BreatheFree profile, saved quit '
                    'plan, and avatar. Your sign-in identity cannot be deleted by '
                    'this service yet and remains an external account action.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const ValueKey('account-delete-password'),
                    controller: _password,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    decoration:
                        const InputDecoration(labelText: 'Current password'),
                  ),
                  TextField(
                    key: const ValueKey('account-delete-confirmation'),
                    controller: _confirmation,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      labelText: 'Type DELETE to confirm',
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _delete(),
                  ),
                  if (widget.account.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      widget.account.errorMessage!,
                      key: const ValueKey('account-delete-error'),
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Deletion receipt ${receipt.requestId}. Your BreatheFree '
                    'profile and quit plan were deleted. Deleting the Supabase '
                    'sign-in identity requires the separately approved '
                    'privileged account service.',
                  ),
                  if (_finishError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _finishError!,
                      key: const ValueKey('account-delete-finish-error'),
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                ],
              ),
        actions: receipt == null
            ? [
                TextButton(
                  onPressed: _deleting ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  key: const ValueKey('account-delete-confirm'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: _deleting || _confirmation.text != 'DELETE'
                      ? null
                      : _delete,
                  child: Text(
                    _deleting
                        ? 'Deleting app data…'
                        : 'Permanently delete app data',
                  ),
                ),
              ]
            : [
                FilledButton(
                  key: const ValueKey('account-delete-done'),
                  onPressed: _finishing ? null : _finish,
                  child: const Text('Done'),
                ),
              ],
      ),
    );
  }
}
