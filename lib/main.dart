import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth/account_controller.dart';
import 'auth/auth_gateway.dart';
import 'auth/secure_session_storage.dart';
import 'config/app_config.dart';
import 'models/screen_spec.dart';
import 'models/tap_target.dart';
import 'profile/profile_api_client.dart';
import 'profile/profile_repository.dart';
import 'screens/approved_screen_player.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android)) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(
      const [DeviceOrientation.portraitUp],
    );
  }

  final config = AppConfig.fromEnvironment();
  AccountController? account;
  if (config.hasAnyConfiguration) config.validate();
  if (config.isConfigured) {
    await Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabaseAnonKey,
      authOptions: FlutterAuthClientOptions(
        localStorage: SecureSessionStorage(),
      ),
    );
    final auth = SupabaseAuthGateway(Supabase.instance.client);
    account = AccountController(
      auth: auth,
      profiles: ProfileRepository(
        auth: auth,
        api: HttpProfileApiClient(baseUrl: config.apiBaseUrl),
      ),
    );
  }

  runApp(BreatheFreeApp(accountController: account));
}

class BreatheFreeApp extends StatefulWidget {
  const BreatheFreeApp({
    this.initialScreen = 0,
    this.accountController,
    super.key,
  });

  final int initialScreen;
  final AccountController? accountController;

  @override
  State<BreatheFreeApp> createState() => _BreatheFreeAppState();
}

class _BreatheFreeAppState extends State<BreatheFreeApp> {
  late int _currentIndex;
  late final AccountController _accountController;
  late final bool _ownsAccountController;
  final List<int> _history = <int>[];

  @override
  void initState() {
    super.initState();
    _ownsAccountController = widget.accountController == null;
    _accountController =
        widget.accountController ?? AccountController.disabled();
    _currentIndex =
        widget.initialScreen.clamp(0, approvedScreens.length - 1).toInt();
    unawaited(_initializeAccount());
  }

  @override
  void dispose() {
    if (_ownsAccountController) _accountController.dispose();
    super.dispose();
  }

  Future<void> _initializeAccount() async {
    await _accountController.initialize();
    if (!mounted || !_accountController.isSignedIn || _currentIndex != 0) {
      return;
    }
    _goTo(
      _accountController.profile?.onboardingCompleted == true ? 11 : 1,
      remember: false,
    );
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
    return AnimatedBuilder(
      animation: _accountController,
      builder: (context, _) => MaterialApp(
        title: 'BreatheFree',
        debugShowCheckedModeBanner: false,
        restorationScopeId: 'breathefree',
        theme: AppTheme.light(),
        home: ApprovedScreenPlayer(
          accountController: _accountController,
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
