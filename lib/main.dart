import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'config/contact_info.dart';
import 'models/screen_spec.dart';
import 'models/tap_target.dart';
import 'screens/approved_screen_player.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android)) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations(
      const [DeviceOrientation.portraitUp],
    );
  }

  runApp(const BreatheFreeApp());
}

class BreatheFreeApp extends StatefulWidget {
  const BreatheFreeApp({this.initialScreen = 0, super.key});

  final int initialScreen;

  @override
  State<BreatheFreeApp> createState() => _BreatheFreeAppState();
}

class _BreatheFreeAppState extends State<BreatheFreeApp> {
  late int _currentIndex;
  final List<int> _history = <int>[];

  /// Gives dialogs a context that sits below [MaterialApp].
  ///
  /// This State builds the MaterialApp, so its own `context` is *above* it and
  /// has neither a Navigator nor MaterialLocalizations. Calling showDialog
  /// with it threw "No MaterialLocalizations found" and every dialog in the
  /// app — quitline, call-back consent, export and deletion — failed to open.
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  /// Context for showing dialogs, or null before the first frame.
  BuildContext? get _dialogContext => _navigatorKey.currentContext;

  @override
  void initState() {
    super.initState();
    _currentIndex =
        widget.initialScreen.clamp(0, approvedScreens.length - 1).toInt();
  }

  void _goTo(int index, {bool remember = true}) {
    final safeIndex = index.clamp(0, approvedScreens.length - 1).toInt();
    if (safeIndex == _currentIndex) return;

    setState(() {
      if (remember) _history.add(_currentIndex);
      _currentIndex = safeIndex;
    });
  }

  void _goBack() {
    if (_history.isNotEmpty) {
      setState(() => _currentIndex = _history.removeLast());
      return;
    }
    _goTo(_currentIndex - 1, remember: false);
  }

  void _goNext() => _goTo(_currentIndex + 1);

  Future<void> _handleTarget(AppTapTarget target) async {
    switch (target.action) {
      case TapAction.navigate:
        if (target.destination != null) _goTo(target.destination!);
        break;
      case TapAction.back:
        _goBack();
        break;
      case TapAction.quitline:
        await _showQuitlineDialog(target.quitline ?? ContactInfo.english);
        break;
      case TapAction.contactSupport:
        await _showSupportDialog();
        break;
      case TapAction.callbackConsent:
        await _showCallbackConsent();
        break;
      case TapAction.exportData:
        await _showInformationDialog(
          title: 'Prepare your data copy?',
          message:
              'The production service will create a password-protected PDF and JSON export after identity verification.',
          confirmLabel: 'Continue',
        );
        break;
      case TapAction.deleteAccount:
        await _showInformationDialog(
          title: 'Delete account and data?',
          message:
              'This is a protected demo action. A production build must require recent authentication, a final data summary and explicit confirmation before permanent deletion.',
          confirmLabel: 'Review deletion',
          destructive: true,
        );
        break;
      case TapAction.information:
        await _showInformationDialog(
          title: target.label,
          message:
              'This approved interaction is represented in the UI prototype and is ready to connect to the production API.',
          confirmLabel: 'Done',
        );
        break;
    }
  }

  Future<void> _showQuitlineDialog(QuitlineContact quitline) async {
    final host = _dialogContext;
    if (host == null) return;
    await showDialog<void>(
      context: host,
      builder: (dialogContext) => AlertDialog(
        title: Text('Call ${quitline.vanityNumber}?'),
        content: Text(
          'This free, confidential ${quitline.language} service routes the '
          'caller to their state quitline. Services and hours may vary. Phone '
          'launching is intentionally disabled in this source-only preview.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('quitline-copy'),
            onPressed: () => _copyAndConfirm(
              dialogContext,
              value: quitline.dialledNumber,
              confirmation: '${quitline.language} quitline number copied',
            ),
            child: const Text('Copy number'),
          ),
        ],
      ),
    );
  }

  /// Shows the product-support address and offers to copy it.
  ///
  /// This is deliberately separate from the quitline and emergency routes. It
  /// reaches the people who build BreatheFree, not a clinician, and the copy
  /// says so — a patient with urgent symptoms must not be sent to an inbox.
  Future<void> _showSupportDialog() async {
    if (!mounted) return;
    final host = _dialogContext;
    if (host == null) return;
    await showDialog<void>(
      context: host,
      builder: (dialogContext) => AlertDialog(
        key: const ValueKey('support-dialog'),
        title: const Text('Contact BreatheFree support'),
        // Not const: ContactInfo.english.vanityNumber is a property read on a
        // const object, which Dart cannot evaluate at compile time.
        content: Text(
          'For questions about the app, your account or your data, email '
          '${ContactInfo.supportEmail}.\n\n'
          'This inbox is not monitored for medical emergencies and cannot give '
          'medical advice. In an emergency call ${ContactInfo.emergencyNumber}, '
          'or call ${ContactInfo.english.vanityNumber} for free, confidential '
          'quit support.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          FilledButton(
            key: const ValueKey('support-copy'),
            onPressed: () => _copyAndConfirm(
              dialogContext,
              value: ContactInfo.supportEmail,
              confirmation: 'Support address copied',
            ),
            child: const Text('Copy address'),
          ),
        ],
      ),
    );
  }

  /// Copies [value], closes the dialog, then confirms in a snack bar.
  ///
  /// The messenger is looked up before the pop, because afterwards
  /// [dialogContext] is defunct and looking it up then throws.
  void _copyAndConfirm(
    BuildContext dialogContext, {
    required String value,
    required String confirmation,
  }) {
    final messenger = ScaffoldMessenger.of(dialogContext);
    Clipboard.setData(ClipboardData(text: value));
    Navigator.pop(dialogContext);
    messenger.showSnackBar(SnackBar(content: Text(confirmation)));
  }

  Future<void> _showCallbackConsent() {
    return _showInformationDialog(
      title: 'Request a counselor call-back?',
      message:
          'Before sending a referral, the production app will show the exact contact details, purpose, destination and consent expiration.',
      confirmLabel: 'Review consent',
    );
  }

  Future<void> _showInformationDialog({
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    final host = _dialogContext;
    if (host == null) return;
    await showDialog<void>(
      context: host,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          // A protected action that a patient cannot complete is exactly when
          // they need a way to ask a person, so every one of these offers it.
          TextButton(
            key: const ValueKey('information-contact-support'),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _showSupportDialog();
            },
            child: const Text('Contact support'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(dialogContext).colorScheme.error,
                  )
                : null,
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'BreatheFree',
      debugShowCheckedModeBanner: false,
      restorationScopeId: 'breathefree',
      theme: AppTheme.light(),
      home: ApprovedScreenPlayer(
        currentIndex: _currentIndex,
        onSelectScreen: _goTo,
        onPrevious: _goBack,
        onNext: _goNext,
        onTarget: _handleTarget,
      ),
    );
  }
}
