// The production TPlatform: calls, texts, links and phone settings for the
// tether_ui screens.
//
// - call / sms: only a dialable number (3 to 15 digits, optional leading +)
//   is launched; a name opens Messages with no recipient. Each returns true
//   only when something opened, false otherwise, and never takes longer than
//   TNav.platformTimeout, so the kit can show the number to dial instead.
// - openUrl: only https links (with a host, no user info) and the exact
//   `message://` (open the email app) are opened; every other scheme is
//   refused without launching anything.
// - openOsSettings: the app's own settings page.
//
// Nothing here throws, and nothing logs a number, recipient or URL: failures
// are reported as codes only.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:tether_ui/ui/ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens [uri] outside the app. Returns whether something opened.
typedef UrlLauncher = Future<bool> Function(Uri uri, LaunchMode mode);

Future<bool> _launchUrl(Uri uri, LaunchMode mode) => launchUrl(uri, mode: mode);

/// Codes the adapter reports. Never with the number, recipient or URL.
abstract final class PlatformCodes {
  /// A link with a scheme the app does not open.
  static const String urlRefused = 'url_refused';

  /// An accepted link that nothing opened.
  static const String urlOpenFailed = 'url_open_failed';

  /// The phone's settings page did not open.
  static const String settingsOpenFailed = 'settings_open_failed';
}

/// What the member sees when a link or settings did not open. Draft copy,
/// pending owner review.
abstract final class PlatformCopy {
  static const String linkFailed = 'Couldn’t open this link. Please try again.';
  static const String settingsFailed =
      'Couldn’t open Settings. Open them from your phone’s home screen.';
}

/// The production [TPlatform].
class AppPlatform implements TPlatform {
  AppPlatform({
    UrlLauncher? launcher,
    MethodChannel? channel,
    TargetPlatform Function()? platform,
    this.onCode,
  })  : _launch = launcher ?? _launchUrl,
        _channel = channel ?? const MethodChannel(channelName),
        _platform = platform ?? (() => defaultTargetPlatform);

  /// The app's own native channel (MainActivity.kt on Android).
  static const String channelName = 'com.tetherhealthllc.tetherhealth/platform';

  final UrlLauncher _launch;
  final MethodChannel _channel;
  final TargetPlatform Function() _platform;

  /// Receives a code for each refused or failed link or settings attempt.
  final void Function(String code)? onCode;

  /// [number] as `tel:`/`sms:` digits: digits with an optional leading `+`,
  /// after removing spaces, dashes, dots and parentheses. Null when anything
  /// else remains or there are fewer than 3 or more than 15 digits.
  static String? dialable(String number) {
    final compact = number.replaceAll(RegExp(r'[\s\-.()]'), '');
    final match = RegExp(r'^(\+?)(\d+)$').firstMatch(compact);
    if (match == null) return null;
    final digits = match.group(2)!;
    if (digits.length < 3 || digits.length > 15) return null;
    return '${match.group(1)}$digits';
  }

  @override
  Future<bool> call(BuildContext context, String number, String label) {
    final digits = dialable(number);
    if (digits == null) return Future<bool>.value(false);
    return _bounded(() => _launch(
          Uri(scheme: 'tel', path: digits),
          LaunchMode.externalApplication,
        ));
  }

  @override
  Future<bool> sms(BuildContext context, String recipient) {
    // A name (not a number) opens Messages with no recipient.
    final digits = dialable(recipient) ?? '';
    return _bounded(() => _launch(
          Uri(scheme: 'sms', path: digits),
          LaunchMode.externalApplication,
        ));
  }

  @override
  Future<void> openUrl(BuildContext context, String url) async {
    final Future<bool> Function() open;
    if (url == 'message://') {
      open = _platform() == TargetPlatform.android
          ? () => _invoke('openEmailApp')
          : () => _launch(Uri.parse(url), LaunchMode.externalApplication);
    } else {
      final uri = Uri.tryParse(url);
      final accepted = uri != null &&
          uri.scheme == 'https' &&
          uri.host.isNotEmpty &&
          uri.userInfo.isEmpty;
      if (!accepted) {
        _report(PlatformCodes.urlRefused);
        return;
      }
      open = () => _launch(uri, LaunchMode.externalApplication);
    }
    if (await _bounded(open)) return;
    _report(PlatformCodes.urlOpenFailed);
    if (context.mounted) TNav.toast(context, PlatformCopy.linkFailed);
  }

  @override
  Future<void> openOsSettings(BuildContext context) async {
    final opened = await _bounded(() => switch (_platform()) {
          TargetPlatform.android => _invoke('openAppSettings'),
          TargetPlatform.iOS => _launch(
              Uri.parse('app-settings:'),
              LaunchMode.externalApplication,
            ),
          _ => Future<bool>.value(false),
        });
    if (opened) return;
    _report(PlatformCodes.settingsOpenFailed);
    if (context.mounted) TNav.toast(context, PlatformCopy.settingsFailed);
  }

  /// Calls [method] on the app's channel with no arguments.
  Future<bool> _invoke(String method) async =>
      await _channel.invokeMethod<bool>(method) ?? false;

  /// [attempt]'s result, or false when it throws, fails or has not
  /// completed within [TNav.platformTimeout]. A late result changes nothing.
  static Future<bool> _bounded(Future<bool> Function() attempt) {
    final result = Completer<bool>();
    void finish(bool value) {
      if (!result.isCompleted) result.complete(value);
    }

    try {
      attempt().then(
        (value) => finish(value == true),
        onError: (Object _) => finish(false),
      );
    } catch (_) {
      finish(false);
    }
    final timer = Timer(TNav.platformTimeout, () => finish(false));
    return result.future.whenComplete(timer.cancel);
  }

  void _report(String code) {
    try {
      onCode?.call(code);
    } catch (_) {
      // Reporting never stops the fallback.
    }
  }
}
