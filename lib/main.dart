import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/prototype_catalog.dart';
import 'models/tap_target.dart';
import 'screens/approved_screen_player.dart';
import 'theme/app_theme.dart';
import 'unplug/models/intercept_tokens.dart';
import 'unplug/models/unplug_module_state.dart';
import 'unplug/widgets/unplug_scope.dart';

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
  final UnplugModuleState _unplug = UnplugModuleState();

  @override
  void initState() {
    super.initState();
    _currentIndex =
        widget.initialScreen.clamp(0, prototypeCatalog.length - 1).toInt();
    _loadInterceptTokens();
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
    super.dispose();
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
        await _showQuitlineDialog();
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

  Future<void> _showQuitlineDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Call 1-800-QUIT-NOW?'),
        content: const Text(
          'This free, confidential service routes the caller to their state quitline. Phone launching is intentionally disabled in this source-only preview.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: '1-800-784-8669'));
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              messenger.showSnackBar(
                const SnackBar(content: Text('Quitline number copied')),
              );
            },
            child: const Text('Copy number'),
          ),
        ],
      ),
    );
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
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  )
                : null,
            onPressed: () => Navigator.pop(context),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BreatheFree',
      debugShowCheckedModeBanner: false,
      restorationScopeId: 'breathefree',
      theme: AppTheme.light(),
      home: UnplugScope(
        state: _unplug,
        child: ApprovedScreenPlayer(
          currentIndex: _currentIndex,
          onSelectScreen: _goTo,
          onPrevious: _goBack,
          onNext: _goNext,
          onTarget: _handleTarget,
        ),
      ),
    );
  }
}
