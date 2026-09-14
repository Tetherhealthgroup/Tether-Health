/// The six routes the host shell owns.
///
/// They live in one place because `shell.json` says the shell is "built once
/// and is identical in every area". A program that could supply its own crisis
/// route, or its own record screen, would eventually supply a slightly
/// different one — and the rule that matters most here, `one_crisis_route`,
/// exists precisely because per-program crisis copy will be wrong in at least
/// one program.
///
/// The paths are the ones the LookUp product file already pins for its shell
/// screens, so a content file written against the bundle routes correctly
/// without translation.
abstract final class ShellRoutes {
  /// SH1 · Your programs.
  static const programs = '/programs';

  /// SH2 · Health areas. Reached on request, never from the home screen.
  static const areas = '/areas';

  /// SH3 · Join a program. Pushed with the [Area] as its route argument.
  static const join = '/areas/join';

  /// SH4 · Your record.
  static const record = '/record';

  /// SH5 · Who sees what.
  static const sharing = '/privacy/sharing';

  /// SH6 · Get help now.
  static const crisis = '/help-now';

  static const all = <String>[programs, areas, join, record, sharing, crisis];

  /// Shell screen id to route, exactly as `shell.json` numbers them.
  static const _byScreenId = <String, String>{
    'SH1': programs,
    'SH2': areas,
    'SH3': join,
    'SH4': record,
    'SH5': sharing,
    'SH6': crisis,
  };

  /// The shell route a content `to` target names, or null when the target is
  /// an ordinary program screen.
  ///
  /// Content files point at `SH6` from inside a program — LookUp's home screen
  /// does it from its first card. That has to land on the one global crisis
  /// route rather than on a per-program copy of it, and this is where that
  /// redirection happens.
  static String? forScreenId(String screenId) => _byScreenId[screenId];

  /// The shell screen id a route implements, or null.
  static String? screenIdFor(String route) {
    for (final entry in _byScreenId.entries) {
      if (entry.value == route) return entry.key;
    }
    return null;
  }
}
