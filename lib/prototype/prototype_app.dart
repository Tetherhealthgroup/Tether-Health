import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../auth/account_controller.dart';

import '../config/contact_info.dart';
import '../models/prototype_catalog.dart';
import '../models/tap_target.dart';
import '../screens/approved_screen_player.dart';
import '../theme/app_theme.dart';
import '../unplug/models/intercept_tokens.dart';
import '../unplug/models/unplug_module_state.dart';
import '../unplug/platform/unplug_platform.dart';
import '../unplug/widgets/unplug_scope.dart';

/// The BreatheFree bitmap prototype and the Unplug v2.1 module, as a
/// standalone app.
///
/// This is the original review build: the 28 approved 1290 × 2796 screens with
/// invisible tap rectangles over them, plus the twelve Unplug screens as
/// native widgets. It is no longer the app's entry point — [TetherApp] is —
/// but it is kept whole and reachable, because the approved artwork is the
/// signed-off reference for the cessation programme and a native rebuild of
/// those screens has not been reviewed against it.
///
/// Reached at [TetherRouter.prototypeRoute], or by launching with
/// `--dart-define=TETHER_ENTRY=prototype`.
class TetherHealthApp extends StatefulWidget {
  const TetherHealthApp({
    this.initialScreen = 0,
    this.standalone = true,
    this.accountController,
    super.key,
  });

  final int initialScreen;

  /// The signed-in account, when the build is configured for one.
  ///
  /// Null on an unconfigured build, which is the ordinary case for a reviewer
  /// running `flutter run` with no dart-defines. `AccountController.disabled()`
  /// stands in so the rest of this class never branches on it.
  final AccountController? accountController;

  /// Whether this widget supplies its own [MaterialApp].
  ///
  /// True when it is the entry point. False when it is pushed as a route
  /// inside the Tether shell, which already has one — nesting a second
  /// MaterialApp would give the prototype its own Navigator and its own theme,
  /// and the back gesture would stop leaving it.
  final bool standalone;

  @override
  State<TetherHealthApp> createState() => _TetherHealthAppState();
}

class _TetherHealthAppState extends State<TetherHealthApp> {
  /// Waits between attempts to restore a profile after sign-in.
  ///
  /// Three tries with a widening gap, because the development API sleeps and
  /// its first request after a cold start can time out. Failing straight to an
  /// error would tell somebody their account is broken when it is merely
  /// asleep.
  static const _profileRetryDelays = <Duration>[
    Duration.zero,
    Duration(seconds: 2),
    Duration(seconds: 5),
  ];

  late int _currentIndex;
  final List<int> _history = <int>[];
  final UnplugModuleState _unplug = UnplugModuleState();
  late final AccountController _accountController;
  late final bool _ownsAccountController;
  late bool _restoringAccount;
  bool _restoreFailed = false;

  /// Gives dialogs a context that sits below [MaterialApp].
  ///
  /// When this widget is the entry point it builds the MaterialApp itself, so
  /// its own `context` is *above* that MaterialApp and has neither a Navigator
  /// nor MaterialLocalizations. Calling `showDialog` with it threw "No
  /// MaterialLocalizations found", and every dialog here — quitline, support,
  /// call-back consent, export and deletion — failed to open.
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  /// Where to show a dialog from, or null before the first frame.
  ///
  /// Only the standalone case needs the key. Pushed as a route inside the
  /// Tether shell this widget builds no MaterialApp, and the ambient context
  /// is already below the shell's — using the key there would find nothing.
  BuildContext? get _dialogContext =>
      widget.standalone ? _navigatorKey.currentContext : context;

  @override
  void initState() {
    super.initState();
    _ownsAccountController = widget.accountController == null;
    _accountController =
        widget.accountController ?? AccountController.disabled();
    _currentIndex =
        widget.initialScreen.clamp(0, prototypeCatalog.length - 1).toInt();
    _restoringAccount = _accountController.isSignedIn && _currentIndex == 0;
    unawaited(_initializeAccount());
    _loadInterceptTokens();
    _attachUnplugPlatform();
  }

  /// Connects the Unplug module to the platform screen-time layer, when this
  /// build has one. When it does not, the module runs on its own simulation and
  /// says so in the banner on every one of its screens.
  Future<void> _attachUnplugPlatform() async {
    final platform = await UnplugPlatform.attach(_unplug);
    if (platform == null || !mounted) return;
    await _unplug.refreshUsage();
    await _unplug.purgeExpiredData();
  }

  /// Reads the intercept design tokens the Unplug module shares with the
  /// SwiftUI and Android intercepts. A failure is surfaced on screen C rather
  /// than swallowed, because the native implementations read the same file.
  Future<void> _loadInterceptTokens() async {
    try {
      final tokens = await InterceptTokens.load();
      if (!mounted) return;
      _unplug.setTokens(tokens);
    } catch (error) {
      if (!mounted) return;
      _unplug.setTokenError(error);
    }
  }

  @override
  void dispose() {
    _unplug.dispose();
    if (_ownsAccountController) _accountController.dispose();
    super.dispose();
  }

  Future<void> _initializeAccount() async {
    if (!_accountController.isSignedIn || _currentIndex != 0) return;

    for (final delay in _profileRetryDelays) {
      if (delay > Duration.zero) await Future<void>.delayed(delay);
      if (!mounted) return;

      final loaded = await _accountController.initialize();
      if (!mounted) return;
      if (!_accountController.isSignedIn) {
        setState(() {
          _restoringAccount = false;
          _restoreFailed = false;
        });
        return;
      }
      if (loaded && _accountController.profile != null) {
        setState(() {
          _restoringAccount = false;
          _restoreFailed = false;
          _history.clear();
          _currentIndex =
              _accountController.profile!.onboardingCompleted ? 11 : 1;
        });
        return;
      }
    }

    if (mounted) {
      setState(() {
        _restoringAccount = false;
        _restoreFailed = true;
      });
    }
  }

  void _retryAccountRestore() {
    setState(() {
      _restoringAccount = true;
      _restoreFailed = false;
    });
    unawaited(_initializeAccount());
  }

  Future<void> _signOutAfterRestoreFailure() async {
    await _accountController.signOut();
    if (!mounted) return;
    setState(() {
      _restoringAccount = false;
      _restoreFailed = false;
      _history.clear();
      _currentIndex = 0;
    });
  }

  void _goTo(int index, {bool remember = true}) {
    final safeIndex = index.clamp(0, prototypeCatalog.length - 1).toInt();
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
  /// Deliberately separate from the quitline and emergency routes. It reaches
  /// the people who build the app, not a clinician, and the copy says so — a
  /// patient with urgent symptoms must not be sent to an inbox.
  Future<void> _showSupportDialog() async {
    if (!mounted) return;
    final host = _dialogContext;
    if (host == null) return;
    await showDialog<void>(
      context: host,
      builder: (dialogContext) => AlertDialog(
        key: const ValueKey('support-dialog'),
        title: const Text('Contact BreatheFree support'),
        // Not const: `ContactInfo.english.vanityNumber` is a property read on
        // a const object, which Dart cannot evaluate at compile time.
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
          // A protected action a patient cannot complete is exactly when they
          // need a way to ask a person, so every one of these offers it.
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
    return AnimatedBuilder(
      animation: _accountController,
      builder: (context, _) {
        final home = _restoringAccount || _restoreFailed
            ? _AccountConnectionScreen(
                failed: _restoreFailed,
                onRetry: _retryAccountRestore,
                onSignOut: _signOutAfterRestoreFailure,
              )
            : UnplugScope(
                state: _unplug,
                child: ApprovedScreenPlayer(
                  accountController: _accountController,
                  currentIndex: _currentIndex,
                  onSelectScreen: _goTo,
                  onPrevious: _goBack,
                  onNext: _goNext,
                  onTarget: _handleTarget,
                ),
              );

        if (!widget.standalone) return home;

        return MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'Tether Health',
          debugShowCheckedModeBanner: false,
          restorationScopeId: 'tetherhealth',
          theme: AppTheme.light(),
          home: home,
        );
      },
    );
  }
}

class _AccountConnectionScreen extends StatelessWidget {
  const _AccountConnectionScreen({
    required this.failed,
    required this.onRetry,
    required this.onSignOut,
  });

  final bool failed;
  final VoidCallback onRetry;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('account-connection-screen'),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (failed)
                    Icon(
                      Icons.cloud_off_rounded,
                      size: 52,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  else
                    const SizedBox.square(
                      dimension: 44,
                      child: CircularProgressIndicator(),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    failed
                        ? 'We could not reach your profile'
                        : 'Connecting to BreatheFree',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    failed
                        ? 'Your account is still signed in. Check your connection and try again.'
                        : 'Your secure session is restored. This can take a moment while the development service wakes up.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (failed) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: const ValueKey('account-connection-retry'),
                        onPressed: onRetry,
                        child: const Text('Try again'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      key: const ValueKey('account-connection-sign-out'),
                      onPressed: () => unawaited(onSignOut()),
                      child: const Text('Sign out'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
