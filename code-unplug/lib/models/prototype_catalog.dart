import '../unplug/models/unplug_screen_spec.dart';
import 'screen_spec.dart';

/// One entry in the prototype, whichever module it belongs to.
///
/// The prototype now holds two modules with different rendering strategies: the
/// 28 approved cessation screens, which are bitmaps with interaction
/// rectangles laid over them, and the twelve Unplug screens, which are native
/// widgets. The player walks one list so that navigation, keyboard shortcuts
/// and the desktop sidebar do not have to know which is which.
sealed class CatalogEntry {
  const CatalogEntry();

  /// Short identifier shown in the sidebar: a number, or a letter.
  String get badge;

  String get title;

  /// The phase or stage this screen belongs to.
  String get sectionLabel;
}

/// One of the 28 approved cessation screens.
class ApprovedCatalogEntry extends CatalogEntry {
  const ApprovedCatalogEntry(this.spec);

  final ScreenSpec spec;

  @override
  String get badge => '${spec.number}';

  @override
  String get title => spec.title;

  @override
  String get sectionLabel => spec.phase.label;
}

/// One of the twelve Unplug v2.1 screens.
class UnplugCatalogEntry extends CatalogEntry {
  const UnplugCatalogEntry(this.spec);

  final UnplugScreenSpec spec;

  @override
  String get badge => spec.letter;

  @override
  String get title => spec.title;

  @override
  String get sectionLabel => spec.phase.label;
}

/// Every screen in the prototype, approved screens first.
final prototypeCatalog = <CatalogEntry>[
  for (final screen in approvedScreens) ApprovedCatalogEntry(screen),
  for (final screen in unplugScreens) UnplugCatalogEntry(screen),
];

/// The index at which the Unplug module starts.
final int unplugCatalogOffset = approvedScreens.length;

/// The index of an Unplug screen by letter, or -1 when there is no such screen.
int prototypeIndexOfLetter(String letter) {
  final position =
      unplugScreens.indexWhere((screen) => screen.letter == letter);
  return position < 0 ? -1 : unplugCatalogOffset + position;
}
