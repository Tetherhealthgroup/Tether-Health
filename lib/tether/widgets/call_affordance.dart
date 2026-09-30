import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The one way this app offers a phone number.
///
/// There is exactly one of these because there is exactly one crisis route.
/// `shell.json` puts it plainly: per-program crisis copy will be wrong in at
/// least one program, so the route is reviewed once and reachable everywhere.
/// A second implementation of "here is a number" would be a second thing to
/// get wrong, and the one most likely to be reached at the worst moment.
///
/// It copies rather than dials. The app has one runtime dependency and
/// `url_launcher` is not it, so `tel:` is unavailable — and the dialog says
/// why instead of leaving a person pressing a button that appears broken.
abstract final class CallAffordance {
  /// Recognises a pill or label that offers a number to call.
  ///
  /// Deliberately narrow: `Call 988`, `Call 911`, `Call 1-800-784-8669`. It
  /// must not match `Call Jordan`, which names a person this build holds no
  /// number for and cannot offer.
  static final _pattern = RegExp(r'^Call\s+([0-9][0-9\-\s]*[0-9])\s*$');

  /// The number inside [label], or null when it is not a call affordance.
  static String? numberIn(String label) =>
      _pattern.firstMatch(label.trim())?.group(1)?.trim();

  /// Offers [number], copied, with an explanation of why it was not dialled.
  ///
  /// The messenger is captured before the pop, because looking it up through a
  /// context that has just been dismantled throws.
  static Future<void> offer(
    BuildContext context, {
    required String name,
    required String number,
  }) async {
    final messenger = ScaffoldMessenger.of(context);

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        // TODO(copy): dialog title.
        title: Text('Call $name on $number?'),
        content: const Text(
          // TODO(copy): the explanation for why the app does not dial. Honest
          // about the reason rather than implying the number does not work.
          'This app cannot place the call for you — it has no dialler. Copy '
          'the number and dial it from your phone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: number));
              Navigator.pop(context);
              messenger.showSnackBar(
                SnackBar(
                  // TODO(copy): copy confirmation.
                  content: Text('$number copied'),
                ),
              );
            },
            // TODO(copy): copy action label.
            child: const Text('Copy number'),
          ),
        ],
      ),
    );
  }
}
