// Tether Health UI kit — components.
//
// One widget per node type in spec/screens.json. Generated screens only use
// these widgets, so visual changes happen here, once. Interactive controls
// (chips, segmented, radio, toggles, checklists, zone) keep their own local
// selection state and expose onChanged for wiring to real data.
import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import '../l10n/strings.g.dart';
import '../logic/rules.dart';
import 'data.dart';
import 'environment.dart';
import 'nav.dart';
import 'strings.dart';
import 'tokens.dart';

// ============================================================== scaffolding

enum THeaderLeft { back, close, none, logo }

enum TBackground { paper, dark, indigo }

class THeader {
  const THeader({this.title = '', this.left = THeaderLeft.back, this.pill, this.avatar, this.onAvatar});
  final String title;
  final THeaderLeft left;
  final String? pill;
  final String? avatar;
  final VoidCallback? onAvatar;
}

/// A full screen: status-bar safe area, header, scrollable body, pinned
/// footer (primary actions) and optional tab bar.
///
/// Large text: the footer stays pinned while it takes at most
/// [_footerShare] of the room below the header and every text in the body
/// fits whole above it. Otherwise (big text sizes on a small phone) it moves
/// to the end of the scrolling body, so no text is ever partly hidden behind
/// the buttons and the buttons are never cut off. At the default text size
/// every footer fits, so nothing moves.
class TScreen extends StatefulWidget {
  const TScreen({super.key, this.header, this.children = const [], this.footer = const [], this.tab, this.background = TBackground.paper});
  final THeader? header;
  final List<Widget> children;
  final List<Widget> footer;
  final String? tab;
  final TBackground background;

  bool get dark => background != TBackground.paper;

  @override
  State<TScreen> createState() => _TScreenState();
}

class _TScreenState extends State<TScreen> with _FooterPlacement<TScreen> {
  /// Keeps the footer's elements, state and focus nodes when it moves
  /// between the pinned area and the scrolling body.
  @override
  final GlobalKey _footerKey = GlobalKey(debugLabel: 'TScreen footer');

  @override
  Widget build(BuildContext context) {
    final TScreen(:header, :children, :footer, :tab, :background, :dark) = widget;
    final decoration = switch (background) {
      TBackground.paper => const BoxDecoration(gradient: LinearGradient(begin: AlignmentDirectional.topStart, end: AlignmentDirectional.bottomEnd, colors: [Color(0xFFFBF8F0), Color(0xFFF3F0E6)])),
      TBackground.dark => const BoxDecoration(gradient: LinearGradient(begin: AlignmentDirectional.topStart, end: AlignmentDirectional.bottomEnd, colors: [TColors.teal, Color(0xFF1C5149)])),
      TBackground.indigo => const BoxDecoration(gradient: LinearGradient(begin: AlignmentDirectional.topStart, end: AlignmentDirectional.bottomEnd, colors: [Color(0xFF1F2A6B), Color(0xFF3B4CC0)])),
    };
    // Lays out above the call fallback while it shows (TCallFallback); the
    // footer then scrolls with the body so nothing overflows.
    return TFallbackInset(builder: (context, covered) {
      // Read outside the Scaffold, which removes the keyboard from its body.
      final keyboard = MediaQuery.viewInsetsOf(context).bottom;
      final inBody = covered || _footerScrolls;
      return TDark(
        dark: dark,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: DecoratedBox(
            decoration: decoration,
            child: SafeArea(
              bottom: tab == null,
              child: Column(
                children: [
                  const TEnvironmentBadge(),
                  if (header != null) _Header(spec: header, dark: dark),
                  Expanded(
                    child: LayoutBuilder(builder: (context, box) {
                      // Room below the header with the keyboard down; 22 is
                      // the pinned footer's padding.
                      _place(box.maxHeight + keyboard, 22, keyboard > 0);
                      final fit = _fit(inBody, _footerColumn(_footerKey, footer));
                      return Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsetsDirectional.fromSTEB(TSpace.screen, 6, TSpace.screen, 20),
                              child: _OnResize(onResize: _scheduleCheck, child: Column(key: _bodyKey, crossAxisAlignment: CrossAxisAlignment.stretch, children: [..._gap(children), if (inBody && footer.isNotEmpty) ...[const SizedBox(height: 16), fit]])),
                            ),
                          ),
                          if (!inBody && footer.isNotEmpty)
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(TSpace.screen, 10, TSpace.screen, 12),
                              child: fit,
                            ),
                        ],
                      );
                    }),
                  ),
                  if (tab != null) TTabBar(active: tab),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

/// Bottom-sheet content. Shown by TNav.sheet through a ModalBottomSheetRoute.
class TSheet extends StatefulWidget {
  const TSheet({super.key, this.children = const [], this.footer = const []});
  final List<Widget> children;
  final List<Widget> footer;

  @override
  State<TSheet> createState() => _TSheetState();
}

class _TSheetState extends State<TSheet> with _FooterPlacement<TSheet> {
  /// Keeps the footer's elements, state and focus nodes when it moves
  /// between the pinned area and the scrolling body.
  @override
  final GlobalKey _footerKey = GlobalKey(debugLabel: 'TSheet footer');

  @override
  Widget build(BuildContext context) {
    final TSheet(:children, :footer) = widget;
    final maxH = MediaQuery.sizeOf(context).height * 0.86;
    // Lays out above the call fallback while it shows (TCallFallback); the
    // footer then scrolls with the body so nothing overflows.
    return TFallbackInset(sheet: true, builder: (context, covered) {
      final inBody = covered || _footerScrolls;
      // Room below the handle (20) and above the home indicator; 20 is the
      // pinned footer's padding.
      _place(maxH - 20 - MediaQuery.paddingOf(this.context).bottom, 20, MediaQuery.viewInsetsOf(context).bottom > 0);
      final fit = _fit(inBody, _footerColumn(_footerKey, footer));
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: Material(
          color: TColors.paper,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(TRadius.sheet)),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: Container(width: 40, height: 5, margin: const EdgeInsetsDirectional.fromSTEB(0, 9, 0, 6), decoration: BoxDecoration(color: TColors.line, borderRadius: BorderRadius.circular(3)))),
                const TEnvironmentBadge(),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsetsDirectional.fromSTEB(TSpace.screen, 6, TSpace.screen, 12),
                    child: _OnResize(onResize: _scheduleCheck, child: Column(key: _bodyKey, crossAxisAlignment: CrossAxisAlignment.stretch, children: [..._gap(children), if (inBody && footer.isNotEmpty) ...[const SizedBox(height: 16), fit]])),
                  ),
                ),
                if (!inBody && footer.isNotEmpty)
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(TSpace.screen, 8, TSpace.screen, 12),
                    child: fit,
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

/// Used by the dev gallery and tests to show a sheet without a navigator.
class TSheetPreview extends StatelessWidget {
  const TSheetPreview({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF6F7F7A),
        body: Align(alignment: Alignment.bottomCenter, child: child),
      );
}

/// The footer of a [TScreen] or [TSheet], pinned or in the scrolling body.
/// [key] moves the same subtree between the two, so a focused footer button
/// keeps its focus node and gets focus back when the call fallback closes.
Widget _footerColumn(GlobalKey key, List<Widget> footer) => Column(key: key, crossAxisAlignment: CrossAxisAlignment.stretch, children: _gap(footer, 8));

/// Largest share of the room a pinned footer may take (see [TScreen]).
/// The tallest footer at the default text size on a 375×667 phone takes
/// about a third.
const double _footerShare = 0.4;

/// Pins the footer of a [TScreen] or [TSheet] or moves it into the body
/// (see [TScreen]). Checked after each frame in which the screen was built
/// or the body or the footer changed size.
mixin _FooterPlacement<T extends StatefulWidget> on State<T> {
  GlobalKey get _footerKey;

  /// The body column, searched for the tallest text.
  final GlobalKey _bodyKey = GlobalKey();

  /// The footer scrolls with the body.
  bool _footerScrolls = false;

  double _room = double.infinity;
  double _padding = 0;
  bool _keyboard = false;
  bool _checkScheduled = false;

  /// Called while building: [room] for the body and the pinned footer with
  /// the keyboard down, the pinned footer's [padding], and whether the
  /// [keyboard] is up.
  void _place(double room, double padding, bool keyboard) {
    _room = room;
    _padding = padding;
    _keyboard = keyboard;
    _scheduleCheck();
  }

  void _scheduleCheck() {
    if (_checkScheduled) return;
    _checkScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScheduled = false;
      if (mounted) _check();
    });
  }

  void _check() {
    final body = _bodyKey.currentContext?.findRenderObject();
    final foot = _footerKey.currentContext?.findRenderObject();
    if (body is! RenderBox || foot is! RenderBox || !body.hasSize || !foot.hasSize) return;
    final block = foot.size.height + _padding;
    var tallest = 0.0;
    void visit(RenderObject o) {
      if (identical(o, foot)) return;
      if (o is RenderParagraph && o.hasSize && o.size.height > tallest) tallest = o.size.height;
      o.visitChildren(visit);
    }

    body.visitChildren(visit);
    final scrolls = block > _footerShare * _room || tallest > _room - block;
    // Pin again only with the keyboard down, so it never jumps while typing.
    if (scrolls != _footerScrolls && (scrolls || !_keyboard)) setState(() => _footerScrolls = scrolls);
  }

  Widget _fit(bool inBody, Widget footer) => _FooterFit(limit: _footerShare * _room - _padding, pinned: !inBody, onResize: _scheduleCheck, child: footer);
}

/// Lays the footer out at its natural height and calls [onResize] when that
/// height changes. A [pinned] footer taller than [limit] takes no space and
/// paints nothing until it moves into the body after the frame, so the
/// screen never overflows.
class _FooterFit extends SingleChildRenderObjectWidget {
  const _FooterFit({required this.limit, required this.pinned, required this.onResize, required super.child});
  final double limit;
  final bool pinned;
  final VoidCallback onResize;

  @override
  _RenderFooterFit createRenderObject(BuildContext context) => _RenderFooterFit(limit, pinned, onResize);

  @override
  void updateRenderObject(BuildContext context, _RenderFooterFit renderObject) => renderObject
    ..limit = limit
    ..pinned = pinned
    ..onResize = onResize;
}

class _RenderFooterFit extends RenderProxyBox {
  _RenderFooterFit(this._limit, this._pinned, this.onResize);

  double _limit;
  set limit(double v) {
    if (v == _limit) return;
    _limit = v;
    markNeedsLayout();
  }

  bool _pinned;
  set pinned(bool v) {
    if (v == _pinned) return;
    _pinned = v;
    markNeedsLayout();
  }

  VoidCallback onResize;
  double? _height;
  bool _hidden = false;

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(BoxConstraints(minWidth: constraints.minWidth, maxWidth: constraints.maxWidth), parentUsesSize: true);
    if (child.size.height != _height) {
      _height = child.size.height;
      onResize();
    }
    _hidden = _pinned && child.size.height > _limit;
    size = constraints.constrain(_hidden ? Size(child.size.width, 0) : child.size);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!_hidden) super.paint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) => !_hidden && super.hitTestChildren(result, position: position);

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (!_hidden) super.visitChildrenForSemantics(visitor);
  }
}

/// Calls [onResize] after a layout in which its child changed size, so the
/// footer placement is checked again when the body grows or shrinks without
/// the screen being rebuilt (a text that changes on its own, a section that
/// expands).
class _OnResize extends SingleChildRenderObjectWidget {
  const _OnResize({required this.onResize, required super.child});
  final VoidCallback onResize;

  @override
  _RenderOnResize createRenderObject(BuildContext context) => _RenderOnResize(onResize);

  @override
  void updateRenderObject(BuildContext context, _RenderOnResize renderObject) => renderObject.onResize = onResize;
}

class _RenderOnResize extends RenderProxyBox {
  _RenderOnResize(this.onResize);
  VoidCallback onResize;
  Size? _last;

  @override
  void performLayout() {
    super.performLayout();
    if (size != _last) {
      _last = size;
      onResize();
    }
  }
}

/// [main] with [aside] beside it, laid out exactly like
/// `Row(children: [Expanded(child: main), SizedBox(width: gap), aside])`
/// (with [aside] first when [asideFirst]) while [aside] fits: at the default
/// text size, while the row does not overflow; with larger text, while
/// [main] keeps room for its longest word. Otherwise (large text on a
/// narrow phone) they stack in the same order, both at the start, 4 apart,
/// so nothing is cut off, overflows or breaks inside a word. At the default
/// text size no row in the generated screens overflows, so nothing moves.
class _Beside extends MultiChildRenderObjectWidget {
  _Beside({required Widget main, required Widget aside, this.asideFirst = false, this.gap = 8, this.center = true}) : super(children: asideFirst ? [aside, main] : [main, aside]);
  final bool asideFirst;
  final double gap;

  /// Centered across the row like a [Row]; otherwise aligned at the top.
  final bool center;

  @override
  _RenderBeside createRenderObject(BuildContext context) => _RenderBeside(asideFirst: asideFirst, gap: gap, center: center, textDirection: Directionality.of(context), largeText: _largeText(context));

  /// Measured at body text size: Android 14 and later enlarge small text
  /// more than large text and leave 100 px text unscaled.
  static bool _largeText(BuildContext context) => MediaQuery.textScalerOf(context).scale(14) > 14;

  @override
  void updateRenderObject(BuildContext context, _RenderBeside renderObject) => renderObject
    ..asideFirst = asideFirst
    ..gap = gap
    ..center = center
    ..textDirection = Directionality.of(context)
    ..largeText = _largeText(context);
}

class _BesideParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderBeside extends RenderBox with ContainerRenderObjectMixin<RenderBox, _BesideParentData>, RenderBoxContainerDefaultsMixin<RenderBox, _BesideParentData> {
  _RenderBeside({required bool asideFirst, required double gap, required bool center, required TextDirection textDirection, required bool largeText})
      : _asideFirst = asideFirst,
        _gap = gap,
        _center = center,
        _textDirection = textDirection,
        _largeText = largeText;

  bool _asideFirst;
  set asideFirst(bool v) {
    if (v == _asideFirst) return;
    _asideFirst = v;
    markNeedsLayout();
  }

  double _gap;
  set gap(double v) {
    if (v == _gap) return;
    _gap = v;
    markNeedsLayout();
  }

  /// Space between the stacked children.
  static const double _runGap = 4;

  bool _center;
  set center(bool v) {
    if (v == _center) return;
    _center = v;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection v) {
    if (v == _textDirection) return;
    _textDirection = v;
    markNeedsLayout();
  }

  /// Text is larger than the default size.
  bool _largeText;
  set largeText(bool v) {
    if (v == _largeText) return;
    _largeText = v;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _BesideParentData) child.parentData = _BesideParentData();
  }

  RenderBox get _main => _asideFirst ? lastChild! : firstChild!;
  RenderBox get _aside => _asideFirst ? firstChild! : lastChild!;

  /// Whether [_aside] goes beside [_main] in [width].
  bool _fits(double width) => !width.isFinite || _aside.getMaxIntrinsicWidth(double.infinity) + _gap + (_largeText ? _main.getMinIntrinsicWidth(double.infinity) : 0) <= width;

  @override
  double computeMinIntrinsicWidth(double height) {
    final a = _aside.getMinIntrinsicWidth(double.infinity), m = _main.getMinIntrinsicWidth(double.infinity);
    return a > m ? a : m;
  }

  @override
  double computeMaxIntrinsicWidth(double height) => _main.getMaxIntrinsicWidth(double.infinity) + _gap + _aside.getMaxIntrinsicWidth(double.infinity);

  double _height(double width) {
    if (_fits(width)) {
      final a = _aside.getMaxIntrinsicWidth(double.infinity);
      final mh = _main.getMinIntrinsicHeight(width.isFinite ? (width - _gap - a).clamp(0.0, double.infinity) : double.infinity);
      final ah = _aside.getMinIntrinsicHeight(double.infinity);
      return mh > ah ? mh : ah;
    }
    return _main.getMinIntrinsicHeight(width) + _runGap + _aside.getMinIntrinsicHeight(width);
  }

  @override
  double computeMinIntrinsicHeight(double width) => _height(width);

  @override
  double computeMaxIntrinsicHeight(double width) => _height(width);

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) => defaultComputeDistanceToHighestActualBaseline(baseline);

  /// Lays both children out with [layout] and returns this box's size and
  /// the children's offsets (first child, second child).
  (Size, Offset, Offset) _layout(BoxConstraints constraints, ChildLayouter layout) {
    final width = constraints.maxWidth;
    final first = firstChild!, second = lastChild!;
    if (_fits(width)) {
      // A Row: the aside at its natural width, the main child takes the rest.
      final aside = layout(_aside, BoxConstraints(maxHeight: constraints.maxHeight));
      assert(!width.isFinite || aside.width + _gap <= width + precisionErrorTolerance, 'The item beside the text is wider than the row: ${aside.width} + $_gap > $width.');
      final rest = width.isFinite ? (width - _gap - aside.width).clamp(0.0, double.infinity) : double.infinity;
      final main = layout(_main, BoxConstraints(minWidth: rest.isFinite ? rest : 0, maxWidth: rest, maxHeight: constraints.maxHeight));
      final (f, s) = _asideFirst ? (aside, main) : (main, aside);
      final size = constraints.constrain(Size(width.isFinite ? width : f.width + _gap + s.width, f.height > s.height ? f.height : s.height));
      double x(double start, Size child) => _textDirection == TextDirection.ltr ? start : size.width - start - child.width;
      double y(Size child) => _center ? (size.height - child.height) / 2.0 : 0;
      return (size, Offset(x(0, f), y(f)), Offset(x(f.width + _gap, s), y(s)));
    }
    // Stacked: the main child takes the full width, the aside its natural width.
    Size lay(RenderBox child) => layout(child, identical(child, _main) ? BoxConstraints.tightFor(width: width) : BoxConstraints(maxWidth: width));
    final f = lay(first), s = lay(second);
    final size = constraints.constrain(Size(width, f.height + _runGap + s.height));
    double x(Size child) => _textDirection == TextDirection.ltr ? 0 : size.width - child.width;
    return (size, Offset(x(f), 0), Offset(x(s), f.height + _runGap));
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) => _layout(constraints, ChildLayoutHelper.dryLayoutChild).$1;

  @override
  void performLayout() {
    final (size, first, second) = _layout(constraints, ChildLayoutHelper.layoutChild);
    this.size = size;
    (firstChild!.parentData! as _BesideParentData).offset = first;
    (lastChild!.parentData! as _BesideParentData).offset = second;
  }

  @override
  void paint(PaintingContext context, Offset offset) => defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) => defaultHitTestChildren(result, position: position);
}

List<Widget> _gap(List<Widget> items, [double gap = TSpace.gap]) {
  final out = <Widget>[];
  for (var i = 0; i < items.length; i++) {
    if (i > 0) out.add(SizedBox(height: gap));
    out.add(items[i]);
  }
  return out;
}

/// Inherited flag so components can switch to on-dark colors.
class TDark extends InheritedWidget {
  const TDark({super.key, required this.dark, required super.child});
  final bool dark;
  static bool of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<TDark>()?.dark ?? false;
  @override
  bool updateShouldNotify(TDark oldWidget) => oldWidget.dark != dark;
}

class _Header extends StatelessWidget {
  const _Header({required this.spec, required this.dark});
  final THeader spec;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final fg = dark ? Colors.white : TColors.teal;
    Widget left;
    Widget middle = const Spacer();
    switch (spec.left) {
      case THeaderLeft.logo:
        left = Row(children: [const TLogoMark(), const SizedBox(width: 10), Text(spec.title.isEmpty ? 'Tether Health' : spec.title, style: TText.headerTitle.copyWith(fontSize: 20, fontWeight: FontWeight.w800, color: fg))]);
      case THeaderLeft.none:
        left = Padding(padding: const EdgeInsetsDirectional.only(start: 4), child: Text(spec.title, style: TText.largeTitle.copyWith(color: fg)));
      case THeaderLeft.back:
      case THeaderLeft.close:
        final isBack = spec.left == THeaderLeft.back;
        left = _CircleButton(
          key: const ValueKey('a:header.left'),
          label: isBack ? TStrings.of(context).kitBack : TStrings.of(context).kitClose,
          icon: isBack ? Icons.chevron_left_rounded : Icons.close_rounded,
          dark: dark,
          onTap: () => isBack ? TNav.back(context) : TNav.close(context),
        );
        middle = Expanded(child: Text(spec.title, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TText.headerTitle.copyWith(color: fg)));
    }
    final right = <Widget>[
      if (spec.pill != null) TPill(spec.pill!),
      if (spec.avatar != null) ...[const SizedBox(width: 8), TAvatar(spec.avatar!, key: const ValueKey('a:header.avatar'), onTap: spec.onAvatar, semanticLabel: TStrings.of(context).kitAccount)],
    ];
    final isNav = spec.left == THeaderLeft.back || spec.left == THeaderLeft.close;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: SizedBox(
        height: 52,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            if (isNav) ...[left, const SizedBox(width: 8), middle] else Expanded(child: Align(alignment: AlignmentDirectional.centerStart, child: FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: left))),
            const SizedBox(width: 8),
            ConstrainedBox(constraints: const BoxConstraints(minWidth: 44), child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.end, children: right)),
          ]),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({super.key, required this.label, required this.icon, required this.onTap, required this.dark});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool dark;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: InkResponse(
          onTap: onTap,
          radius: 24,
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(shape: BoxShape.circle, color: dark ? Colors.transparent : TColors.paper, border: Border.all(color: dark ? TColors.tealBorder : TColors.line)),
              child: Icon(icon, size: 24, color: dark ? Colors.white : TColors.teal),
            ),
          ),
        ),
      );
}

/// The Tether Health mark: the outlined lime leaf on the teal disc, drawn
/// with the geometry of tool/brand/tether_mark.svg (the app icon's master
/// artwork, from the design's header logo).
class TLogoMark extends StatelessWidget {
  const TLogoMark({super.key, this.size = 32});
  final double size;

  /// The leaf outline in the mark's 32-unit space (tool/brand/tether_mark.svg `#leaf`).
  static Path leaf() => _LogoMarkPainter.leaf();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(child: CustomPaint(size: Size.square(size), painter: const _LogoMarkPainter()));
}

class _LogoMarkPainter extends CustomPainter {
  const _LogoMarkPainter();

  /// The leaf of tool/brand/tether_mark.svg (`#leaf`) in its 32-unit space:
  /// the outer and inner edges of the rotated outline, filled even-odd.
  static Path leaf() {
    const r14 = Radius.circular(14), r9 = Radius.circular(9);
    return Path()
      ..fillType = PathFillType.evenOdd
      ..moveTo(11.136, 26.776)
      ..arcToPoint(const Offset(16.261, 7.651), radius: r14)
      ..lineTo(20.764, 5.051)
      ..lineTo(20.864, 5.224)
      ..arcToPoint(const Offset(15.739, 24.349), radius: r14)
      ..lineTo(11.236, 26.949)
      ..close()
      ..moveTo(12.188, 23.397)
      ..arcToPoint(const Offset(15.482, 11.103), radius: r9)
      ..lineTo(19.812, 8.603)
      ..arcToPoint(const Offset(16.518, 20.897), radius: r9)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 32;
    canvas.scale(scale);
    canvas.drawCircle(const Offset(16, 16), 16, Paint()..color = TColors.teal);
    canvas.drawPath(leaf(), Paint()..color = TColors.lime);
  }

  @override
  bool shouldRepaint(_LogoMarkPainter oldDelegate) => false;
}

class TTabBar extends StatelessWidget {
  const TTabBar({super.key, required this.active});
  final String active;
  static const _tabs = <String>['today', 'plans', 'progress', 'learn', 'support'];

  static String _name(TStrings s, String tab) => switch (tab) {
        'today' => s.kitTabToday,
        'plans' => s.kitTabPlans,
        'progress' => s.kitTabProgress,
        'learn' => s.kitTabLearn,
        _ => s.kitTabSupport,
      };

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return Container(
      decoration: const BoxDecoration(color: TColors.paper, border: Border(top: BorderSide(color: TColors.line2))),
      child: SafeArea(
        top: false,
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.15,
          child: Row(
            children: [
              for (final t in _tabs)
                Expanded(
                  child: Semantics(
                    selected: t == active,
                    button: true,
                    label: s.kitTabSemantics(tab: _name(s, t)),
                    child: InkWell(
                      key: ValueKey('a:tabbar.${t}'),
                      onTap: t == active ? null : () => TNav.tab(context, TNav.tabRoute(t)),
                      child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          width: 44,
                          height: 28,
                          decoration: BoxDecoration(color: t == active ? TColors.mint : Colors.transparent, borderRadius: BorderRadius.circular(14)),
                          // The prototype's line icons (`.tab svg`): 24 x 22 pt inside the pill.
                          child: ExcludeSemantics(child: CustomPaint(painter: _TabIconPainter(t, t == active ? TColors.teal : TColors.muted))),
                        ),
                        const SizedBox(height: 2),
                        Text(_name(s, t), maxLines: 1, overflow: TextOverflow.ellipsis, style: TText.tab.copyWith(color: t == active ? TColors.teal : TColors.muted, fontWeight: t == active ? FontWeight.w800 : FontWeight.w600)),
                      ])),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The tab bar's line icons, the paths of the prototype's SVGs (viewBox 24 x
/// 24, stroke 1.8, round caps and joins), drawn without any package.
class _TabIconPainter extends CustomPainter {
  const _TabIconPainter(this.tab, this.color);
  final String tab;
  final Color color;

  static Path pathOf(String tab) {
    final p = Path();
    switch (tab) {
      case 'today':
        p
          ..moveTo(4, 11.5)
          ..lineTo(12, 5)
          ..lineTo(20, 11.5)
          ..lineTo(20, 20)
          ..arcToPoint(const Offset(19, 21), radius: const Radius.circular(1))
          ..lineTo(14.5, 21)
          ..lineTo(14.5, 15.5)
          ..lineTo(9.5, 15.5)
          ..lineTo(9.5, 21)
          ..lineTo(5, 21)
          ..arcToPoint(const Offset(4, 20), radius: const Radius.circular(1))
          ..close();
      case 'plans':
        p
          ..moveTo(5, 5)
          ..lineTo(19, 5)
          ..moveTo(5, 12)
          ..lineTo(19, 12)
          ..moveTo(5, 19)
          ..lineTo(14, 19)
          ..addOval(Rect.fromCircle(center: const Offset(19, 19), radius: 1.2));
      case 'progress':
        p
          ..moveTo(5, 20)
          ..lineTo(5, 12)
          ..moveTo(10, 20)
          ..lineTo(10, 6)
          ..moveTo(15, 20)
          ..lineTo(15, 11)
          ..moveTo(20, 20)
          ..lineTo(20, 9);
      case 'learn':
        p
          ..moveTo(4, 5.5)
          ..cubicTo(6.5, 4.5, 9.5, 4.5, 12, 6)
          ..cubicTo(14.5, 4.5, 17.5, 4.5, 20, 5.5)
          ..lineTo(20, 19)
          ..cubicTo(17.5, 18, 14.5, 18, 12, 19.5)
          ..cubicTo(9.5, 18, 6.5, 18, 4, 19)
          ..close()
          ..moveTo(12, 6)
          ..lineTo(12, 19.5);
      default:
        p
          ..moveTo(12, 20)
          ..cubicTo(12, 20, 5, 15.6, 5, 10)
          ..arcToPoint(const Offset(12, 7.4), radius: const Radius.circular(4))
          ..arcToPoint(const Offset(19, 10), radius: const Radius.circular(4))
          ..cubicTo(19, 15.6, 12, 20, 12, 20)
          ..close();
    }
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 24 x 22 pt content box, the viewBox fitted inside it and centred.
    final scale = 22 / 24;
    canvas.translate((size.width - 24 * scale) / 2, (size.height - 22) / 2);
    canvas.scale(scale);
    canvas.drawPath(
      pathOf(tab),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = color
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_TabIconPainter old) => old.tab != tab || old.color != color;
}

// ============================================================== typography

enum TTitleSize { m, l, xl }

enum TTextTone { body, muted, small }

class TEyebrow extends StatelessWidget {
  const TEyebrow(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(), style: TText.eyebrow.copyWith(color: TDark.of(context) ? TColors.onDarkMuted : null));
}

class TTitle extends StatelessWidget {
  const TTitle(this.text, {super.key, this.size = TTitleSize.m, this.center = false});
  final String text;
  final TTitleSize size;
  final bool center;
  @override
  Widget build(BuildContext context) {
    final style = switch (size) { TTitleSize.m => TText.titleM, TTitleSize.l => TText.titleL, TTitleSize.xl => TText.titleXl };
    return Semantics(header: true, child: Text(text, textAlign: center ? TextAlign.center : TextAlign.start, style: style.copyWith(color: TDark.of(context) ? Colors.white : null)));
  }
}

class TBody extends StatelessWidget {
  const TBody(this.text, {super.key, this.tone = TTextTone.body, this.center = false});
  final String text;
  final TTextTone tone;
  final bool center;
  @override
  Widget build(BuildContext context) {
    final style = switch (tone) { TTextTone.body => TText.body, TTextTone.muted => TText.muted, TTextTone.small => TText.small };
    return Text(text, textAlign: center ? TextAlign.center : TextAlign.start, style: TDark.of(context) ? style.copyWith(color: TColors.onDark) : style);
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: TText.label.copyWith(color: TDark.of(context) ? Colors.white : null)));
}

Widget _labelled(String? label, Widget child) => label == null ? child : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [_Label(label), child]);

class TPill extends StatelessWidget {
  const TPill(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) {
    final dark = TDark.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: dark ? const Color(0xFF234E48) : const Color(0xFFE4F1E9), borderRadius: BorderRadius.circular(12)),
      child: Text(text.toUpperCase(), style: TText.pill.copyWith(color: dark ? TColors.lime : null)),
    );
  }
}

class TAvatar extends StatelessWidget {
  const TAvatar(this.text, {super.key, this.onTap, this.semanticLabel, this.icon = false});
  final String text;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool icon;
  @override
  Widget build(BuildContext context) {
    final av = Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: icon ? TColors.paper : TColors.mint, border: Border.all(color: icon ? TColors.line : TColors.mintStrong)),
      child: Text(text, style: TText.label.copyWith(fontSize: icon ? 18 : 15, fontWeight: FontWeight.w800)),
    );
    if (onTap == null) return av;
    return Semantics(button: true, label: semanticLabel ?? text, child: InkResponse(onTap: onTap, radius: 24, child: SizedBox(width: 44, height: 44, child: Center(child: av))));
  }
}

class TProgramBadge extends StatelessWidget {
  const TProgramBadge(this.program, {super.key, this.size = 36});
  final String program;
  final double size;
  static const _letters = {'bf': 'B', 'sf': 'S', 'ca': 'C', 'hw': 'H', 'st': 'S', 're': 'R', 'nu': 'N', 'sd': 'S', 'ea': 'E', 'ck': 'C', 'be': 'B'};
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: TColors.program(program), borderRadius: BorderRadius.circular(size * 0.31)),
          child: Text(_letters[program] ?? '•', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: size * 0.42)),
        ),
      );
}

class TProgramTag extends StatelessWidget {
  const TProgramTag({super.key, required this.program, this.extra, this.muted = false});
  final String program;
  final String? extra;

  /// The text is grey at 12.5 pt, as the tag in a stat tile (`.stat span`
  /// overrides `.tag`); the square keeps the programme colour.
  final bool muted;
  static const names = {'bf': 'BreatheFree', 'sf': 'ScrollFree', 'ca': 'ClearAir', 'hw': 'Heartwise', 'st': 'Steady', 're': 'Renew', 'nu': 'Nourish', 'sd': 'Stride', 'ea': 'Ease', 'ck': 'Checkup', 'be': 'Beacon'};
  @override
  Widget build(BuildContext context) {
    final c = TDark.of(context) ? Color.lerp(TColors.program(program), Colors.white, 0.55)! : TColors.program(program);
    final text = (names[program] ?? program) + (extra != null ? ' · $extra' : '');
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 9, height: 9, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 6),
      Flexible(child: Text(text.toUpperCase(), style: muted ? TText.tag.copyWith(color: TColors.muted, fontSize: 12.5) : TText.tag.copyWith(color: c))),
    ]);
  }
}

class TSteps extends StatelessWidget {
  const TSteps({super.key, required this.n, required this.total});
  final int n;
  final int total;
  @override
  Widget build(BuildContext context) => Semantics(
        label: TStrings.of(context).kitStepOf(n: n, total: total),
        child: Row(children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(child: Container(height: 5, decoration: BoxDecoration(color: i < n ? TColors.teal : TColors.line2, borderRadius: BorderRadius.circular(3)))),
          ]
        ]),
      );
}

// ============================================================== inputs

/// Same session value: lists (multi-select labels) compare as sets.
bool _sameValue(Object? a, Object? b) {
  if (a is List && b is List) return a.length == b.length && setEquals(a.toSet(), b.toSet());
  return a == b;
}

/// The starting value of an input control and its settings binding (P-71).
///
/// Without a bind key the control starts from the spec's starting value and
/// writes it to [TSession] when built.
///
/// With a bind key (spec `bind`, settings screens only) the control starts
/// from the member's stored value, [TData.instance] `.watch(bindKey)`, with
/// `:program` in the key resolved for the programme the screen was opened
/// for ([TNav.programOf], [TData.resolve]; no programme counts as null):
/// - a valid stored value: shown; a [TBindClass.plan] control also writes
///   it to the session;
/// - [TData.unset] (nothing stored): a plan control shows and writes the
///   spec's starting value; a [TBindClass.consent] control shows its empty
///   (off) state and writes nothing;
/// - null (not loaded), or a value the control cannot show: the empty state,
///   and nothing is written;
/// - [TData.example] (preview data): the spec's starting value is shown; a
///   plan control writes it, as an unbound control would.
///
/// A consent control therefore never writes the spec's starting value, and
/// no control writes anything while its value is not loaded. Until the
/// member sets the control, a new TData value replaces the shown one. Either
/// way the control marks its key touched ([TSession.touched]) while the
/// member's value differs from the value it started from.
mixin _TInput<W extends StatefulWidget, T> on State<W> {
  String? get fieldKey;
  String? get bindKey;
  TBindClass get bindClass;

  /// The spec's starting value.
  T get designed;

  /// The empty state, shown while a bound value is unknown.
  T get empty;

  /// [stored] as this control's value, or null if it cannot show it.
  T? fromStored(Object stored);

  /// [value] as written to the session.
  Object? toSession(T value);

  /// The value shown.
  late T current;

  ValueListenable<Object?>? _source;
  bool _started = false;
  bool _memberSet = false;

  /// Session form of the value the control started from; null when unknown.
  Object? _start;

  /// Call from initState.
  void initInput() {
    TSession.markTouched(fieldKey, false);
    if (bindKey == null) {
      _started = true;
      current = designed;
      _start = toSession(current);
      TSession.set(fieldKey, _start);
      return;
    }
    TSession.forget(fieldKey);
    current = empty;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final key = TData.resolve(bindKey!, TNav.programOf(context));
    _source = key == null ? null : (TData.instance.watch(key)..addListener(_onData));
    _seed(_source?.value);
  }

  void _seed(Object? stored) {
    final plan = bindClass == TBindClass.plan;
    final T? value;
    if (identical(stored, TData.example) || identical(stored, TData.unset)) {
      value = identical(stored, TData.example) || plan ? designed : null;
    } else {
      value = stored == null ? null : fromStored(stored);
    }
    current = value ?? empty;
    _start = value == null ? null : toSession(value);
    if (!plan) return;
    value == null ? TSession.forget(fieldKey) : TSession.set(fieldKey, _start);
  }

  void _onData() {
    if (_memberSet || !mounted) return;
    setState(() => _seed(_source!.value));
  }

  void disposeInput() => _source?.removeListener(_onData);

  /// The member set [value]: show it, write it, and mark the key touched
  /// unless it is the starting value.
  void memberSet(T value) {
    _memberSet = true;
    setState(() => current = value);
    final v = toSession(value);
    TSession.set(fieldKey, v);
    TSession.markTouched(fieldKey, !_sameValue(v, _start));
  }
}

class TChips extends StatefulWidget {
  const TChips({super.key, required this.options, this.labels, this.selected = const [], this.multi = true, this.dots = const {}, this.label, this.onChanged, this.fieldKey, this.bind, this.bindClass = TBindClass.consent})
      : assert(labels == null || labels.length == options.length);
  final String? fieldKey;

  /// Settings binding (spec `bind`): the stored labels (see [_TInput]).
  final String? bind;

  /// How the bound control starts ([_TInput]).
  final TBindClass bindClass;
  /// The option values: what [selected], [dots], the session and the
  /// bound value hold. Stable across languages.
  final List<String> options;

  /// The text shown for each option, in the app language; the values
  /// themselves when null.
  final List<String>? labels;
  final List<String> selected;
  final bool multi;
  final Map<String, Color> dots;
  final String? label;
  final ValueChanged<Set<String>>? onChanged;
  @override
  State<TChips> createState() => _TChipsState();
}

class _TChipsState extends State<TChips> with _TInput<TChips, Set<String>> {
  @override
  String? get fieldKey => widget.fieldKey;
  @override
  String? get bindKey => widget.bind;
  @override
  TBindClass get bindClass => widget.bindClass;
  @override
  Set<String> get designed => {...widget.selected};
  @override
  Set<String> get empty => <String>{};
  @override
  Set<String>? fromStored(Object stored) {
    final labels = stored is String ? [stored] : (stored is Iterable ? stored.whereType<String>().toList() : null);
    if (labels == null) return null;
    final known = {for (final o in widget.options) if (labels.contains(o)) o};
    return widget.multi || known.length <= 1 ? known : {known.first};
  }

  @override
  Object? toSession(Set<String> value) => value.toList();

  Set<String> get _sel => current;

  @override
  void initState() {
    super.initState();
    initInput();
  }

  @override
  void dispose() {
    disposeInput();
    super.dispose();
  }

  void _tap(String o) {
    final next = {..._sel};
    if (widget.multi) {
      next.contains(o) ? next.remove(o) : next.add(o);
    } else {
      next
        ..clear()
        ..add(o);
    }
    memberSet(next);
    widget.onChanged?.call(_sel);
  }

  @override
  Widget build(BuildContext context) {
    final dark = TDark.of(context);
    return _labelled(
      widget.label,
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final (i, o) in widget.options.indexed)
          Semantics(
            checked: _sel.contains(o),
            button: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(TRadius.chip),
              onTap: () => _tap(o),
              child: Container(
                constraints: const BoxConstraints(minHeight: 40),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _sel.contains(o) ? (dark ? const Color(0xFF2B6258) : TColors.mint) : (dark ? TColors.tealRaised : TColors.paper),
                  borderRadius: BorderRadius.circular(TRadius.chip),
                  border: Border.all(width: 1.5, color: _sel.contains(o) ? (dark ? TColors.lime : TColors.teal) : (dark ? TColors.tealBorder : const Color(0xFFC8D8D1))),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (_sel.contains(o)) ...[Icon(Icons.check_rounded, size: 15, color: dark ? Colors.white : TColors.teal), const SizedBox(width: 5)],
                  if (widget.dots[o] != null) ...[Container(width: 10, height: 10, decoration: BoxDecoration(color: widget.dots[o], borderRadius: BorderRadius.circular(3))), const SizedBox(width: 6)],
                  Flexible(child: Text(widget.labels?[i] ?? o, style: TText.chip.copyWith(color: dark ? Colors.white : null))),
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}

class TSegmented extends StatefulWidget {
  const TSegmented({super.key, required this.options, this.labels, required this.selected, this.label, this.onChanged, this.fieldKey, this.bind, this.bindClass = TBindClass.consent})
      : assert(labels == null || labels.length == options.length);
  final String? fieldKey;

  /// Settings binding (spec `bind`): the stored option (see [_TInput]).
  final String? bind;

  /// How the bound control starts ([_TInput]).
  final TBindClass bindClass;
  /// The option values: what [selected], the session and the bound value
  /// hold. Stable across languages.
  final List<String> options;

  /// The text shown for each option; the values themselves when null.
  final List<String>? labels;
  final String selected;
  final String? label;
  final ValueChanged<String>? onChanged;
  @override
  State<TSegmented> createState() => _TSegmentedState();
}

class _TSegmentedState extends State<TSegmented> with _TInput<TSegmented, String?> {
  @override
  String? get fieldKey => widget.fieldKey;
  @override
  String? get bindKey => widget.bind;
  @override
  TBindClass get bindClass => widget.bindClass;
  @override
  String? get designed => widget.selected;
  @override
  String? get empty => null;
  @override
  String? fromStored(Object stored) => stored is String && widget.options.contains(stored) ? stored : null;
  @override
  Object? toSession(String? value) => value;

  String? get _sel => current;

  @override
  void initState() {
    super.initState();
    initInput();
  }

  @override
  void dispose() {
    disposeInput();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _labelled(
        widget.label,
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(color: TColors.segBg, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            for (final (i, o) in widget.options.indexed)
              Expanded(
                child: Semantics(
                  selected: o == _sel,
                  button: true,
                  child: GestureDetector(
                    onTap: () {
                      memberSet(o);
                      widget.onChanged?.call(o);
                    },
                    child: AnimatedContainer(
                      duration: TMotion.enter,
                      constraints: const BoxConstraints(minHeight: 38),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                      decoration: BoxDecoration(
                        color: o == _sel ? TColors.paper : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: o == _sel ? const [BoxShadow(color: Color(0x24123C37), blurRadius: 5, offset: Offset(0, 2))] : null,
                      ),
                      child: Text(widget.labels?[i] ?? o, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TText.chip.copyWith(fontSize: 13.5, color: o == _sel ? TColors.teal : TColors.teal2)),
                    ),
                  ),
                ),
              ),
          ]),
        ),
      );
}

class TRadioItem {
  const TRadioItem(this.label, {String? value, this.sub, this.badge}) : _value = value;

  /// The text shown, in the app language.
  final String label;
  final String? _value;

  /// The stable value written to the session and matched against the bound
  /// value; [label] when not given.
  String get value => _value ?? label;
  final String? sub;
  final String? badge;
}

class TRadioList extends StatefulWidget {
  const TRadioList({super.key, required this.items, this.selected = 0, this.label, this.onChanged, this.fieldKey, this.bind, this.bindClass = TBindClass.consent});
  final String? fieldKey;

  /// Settings binding (spec `bind`): the stored item label (see [_TInput]).
  final String? bind;

  /// How the bound control starts ([_TInput]).
  final TBindClass bindClass;
  final List<TRadioItem> items;
  final int selected;
  final String? label;
  final ValueChanged<int>? onChanged;
  @override
  State<TRadioList> createState() => _TRadioListState();
}

class _TRadioListState extends State<TRadioList> with _TInput<TRadioList, int> {
  @override
  String? get fieldKey => widget.fieldKey;
  @override
  String? get bindKey => widget.bind;
  @override
  TBindClass get bindClass => widget.bindClass;
  @override
  int get designed => widget.selected;
  @override
  int get empty => -1;
  @override
  int? fromStored(Object stored) {
    final i = widget.items.indexWhere((item) => item.value == stored);
    return i < 0 ? null : i;
  }

  @override
  Object? toSession(int value) => value >= 0 && value < widget.items.length ? widget.items[value].value : null;

  int get _sel => current;

  @override
  void initState() {
    super.initState();
    initInput();
  }

  @override
  void dispose() {
    disposeInput();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _labelled(
        widget.label,
        Column(children: [
          for (var i = 0; i < widget.items.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            Semantics(
              inMutuallyExclusiveGroup: true,
              checked: i == _sel,
              button: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(TRadius.control),
                onTap: () {
                  memberSet(i);
                  widget.onChanged?.call(i);
                },
                child: AnimatedContainer(
                  duration: TMotion.enter,
                  constraints: const BoxConstraints(minHeight: 52),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: i == _sel ? TColors.mintTint : TColors.paper,
                    borderRadius: BorderRadius.circular(TRadius.control),
                    border: Border.all(width: 1.5, color: i == _sel ? TColors.teal : TColors.line2),
                  ),
                  child: Row(children: [
                    Container(width: 20, height: 20, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: i == _sel ? TColors.teal : TColors.line, width: i == _sel ? 6 : 2))),
                    const SizedBox(width: 12),
                    Expanded(child: _withBadge(widget.items[i])),
                  ]),
                ),
              ),
            ),
          ]
        ]),
      );
}

/// The label and sub text of [item], with its badge beside them (or below
/// them when it does not fit, see [_Beside]).
Widget _withBadge(TRadioItem item) {
  final text = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(item.label, style: TText.optionLabel),
    if (item.sub != null) Text(item.sub!, style: TText.sub),
  ]);
  return item.badge == null ? text : _Beside(main: text, aside: TPill(item.badge!));
}

class TCheckItem {
  const TCheckItem(this.label, {String? value, this.sub, this.done = false}) : _value = value;

  /// The text shown, in the app language.
  final String label;
  final String? _value;

  /// The stable value written to the session; [label] when not given.
  String get value => _value ?? label;
  final String? sub;
  final bool done;
}

class TChecklist extends StatefulWidget {
  const TChecklist({super.key, required this.items, this.label, this.onChanged, this.fieldKey, this.bind, this.bindClass = TBindClass.consent});
  final List<TCheckItem> items;
  final String? label;
  final void Function(int index, bool done)? onChanged;

  /// Session key. When set, the labels of the ticked items are written to
  /// [TSession] (consent checklists).
  final String? fieldKey;

  /// Settings binding (spec `bind`): the stored ticked labels (see
  /// [_TInput]).
  final String? bind;

  /// How the bound control starts ([_TInput]).
  final TBindClass bindClass;
  @override
  State<TChecklist> createState() => _TChecklistState();
}

class _TChecklistState extends State<TChecklist> with _TInput<TChecklist, List<bool>> {
  @override
  String? get fieldKey => widget.fieldKey;
  @override
  String? get bindKey => widget.bind;
  @override
  TBindClass get bindClass => widget.bindClass;
  @override
  List<bool> get designed => [for (final i in widget.items) i.done];
  @override
  List<bool> get empty => [for (final _ in widget.items) false];
  @override
  List<bool>? fromStored(Object stored) {
    if (stored is! Iterable) return null;
    final labels = stored.whereType<String>().toSet();
    return [for (final i in widget.items) labels.contains(i.value)];
  }

  @override
  Object? toSession(List<bool> value) => [
        for (var i = 0; i < widget.items.length; i++)
          if (value[i]) widget.items[i].value
      ];

  List<bool> get _done => current;

  @override
  void initState() {
    super.initState();
    initInput();
  }

  @override
  void dispose() {
    disposeInput();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _labelled(
        widget.label,
        Column(children: [
          for (var i = 0; i < widget.items.length; i++)
            Semantics(
              checked: _done[i],
              button: true,
              child: InkWell(
                onTap: () {
                  memberSet([for (var j = 0; j < _done.length; j++) j == i ? !_done[j] : _done[j]]);
                  widget.onChanged?.call(i, _done[i]);
                },
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(border: i == 0 ? null : const Border(top: BorderSide(color: TColors.line2))),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: BoxDecoration(shape: BoxShape.circle, color: _done[i] ? TColors.teal : Colors.transparent, border: Border.all(width: 2, color: _done[i] ? TColors.teal : TColors.line)),
                      child: _done[i] ? const Icon(Icons.check_rounded, size: 15, color: TColors.lime) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(widget.items[i].label, style: TText.optionLabel),
                        if (widget.items[i].sub != null) Text(widget.items[i].sub!, style: TText.sub),
                      ]),
                    ),
                  ]),
                ),
              ),
            ),
        ]),
      );
}

class TToggleRow extends StatefulWidget {
  const TToggleRow({super.key, required this.label, this.sub, this.value = false, this.onChanged, this.fieldKey, this.bind, this.bindClass = TBindClass.consent});
  final String? fieldKey;

  /// Settings binding (spec `bind`): the stored on/off (see [_TInput]).
  final String? bind;

  /// How the bound control starts ([_TInput]).
  final TBindClass bindClass;
  final String label;
  final String? sub;
  final bool value;
  final ValueChanged<bool>? onChanged;
  @override
  State<TToggleRow> createState() => _TToggleRowState();
}

class _TToggleRowState extends State<TToggleRow> with _TInput<TToggleRow, bool> {
  @override
  String? get fieldKey => widget.fieldKey;
  @override
  String? get bindKey => widget.bind;
  @override
  TBindClass get bindClass => widget.bindClass;
  @override
  bool get designed => widget.value;
  @override
  bool get empty => false;
  @override
  bool? fromStored(Object stored) => stored is bool ? stored : null;
  @override
  Object? toSession(bool value) => value;

  bool get _on => current;

  @override
  void initState() {
    super.initState();
    initInput();
  }

  @override
  void dispose() {
    disposeInput();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MergeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.label, style: TText.optionLabel),
                if (widget.sub != null) Text(widget.sub!, style: TText.sub),
              ]),
            ),
            const SizedBox(width: 12),
            Switch.adaptive(
              value: _on,
              activeTrackColor: TColors.teal,
              inactiveTrackColor: TColors.toggleOff,
              onChanged: (v) {
                memberSet(v);
                widget.onChanged?.call(v);
              },
            ),
          ]),
        ),
      );
}

enum TFieldKind { text, number, email, password, phone, date, select, multiline, search }

class TField extends StatefulWidget {
  const TField({super.key, required this.label, this.value, this.unit, this.hint, this.error, this.placeholder, this.kind = TFieldKind.text, this.onChanged, this.fieldKey, this.bind, this.bindClass = TBindClass.consent, this.options, this.optionLabels})
      : assert(optionLabels == null || (options != null && optionLabels.length == options.length));
  final String label;

  /// A [TFieldKind.select] field with options opens a list to pick from. The
  /// session holds the picked option's value from [options] (stable across
  /// languages); the field shows its label from [optionLabels], or the value
  /// itself without labels. Without options a select field is read-only.
  final List<String>? options;
  final List<String>? optionLabels;

  final String? value;
  final String? unit;
  final String? hint;
  final String? error;
  final String? placeholder;
  final TFieldKind kind;
  final ValueChanged<String>? onChanged;
  final String? fieldKey;

  /// Settings binding (spec `bind`, select fields on settings screens): the
  /// field shows the member's stored text from [TData.instance] and writes
  /// nothing to [TSession] until the member types; null or a non-text value
  /// leaves it empty (placeholder only), and [TData.example] shows [value]
  /// (see [_TInput]). A [TBindClass.plan] field also writes a stored text;
  /// with [TData.unset] it starts from [value], which P-31 keeps null.
  final String? bind;

  /// How the bound field starts ([_TInput]).
  final TBindClass bindClass;

  @override
  State<TField> createState() => _TFieldState();
}

class _TFieldState extends State<TField> {
  // P-31: generated fields have no value; an example is only placeholder
  // (hint) text and is never written to the session. The field writes null
  // until the user types, and null again if they clear it.
  //
  // When the field's session key is removed (TSession.scrub, scrubPasswords,
  // clear), the field empties its text too, so a scrubbed value (a password)
  // does not stay on screen or in the text controller. The editable is also
  // rebuilt ([_generation]), which drops its undo history: an undo
  // (Ctrl/Cmd+Z, shake to undo) cannot bring the scrubbed value back. This
  // also holds when the text was typed and erased before the scrub: the
  // field is then already empty, but its undo history still has the typed
  // text. The rebuilt field does not keep the keyboard focus. Other session
  // changes do not rebuild the field.
  late final TextEditingController _controller = TextEditingController(text: widget.value);
  int _generation = 0;

  // The user has edited the field (it wrote its key) since the editable was
  // last built, so its undo history may hold typed text.
  bool _hadKey = false;

  // Settings binding: the stored value's source, and the value the field
  // started from (touched while the typed value differs from it).
  ValueListenable<Object?>? _source;
  String? _start;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    TSession.markTouched(widget.fieldKey, false);
    if (widget.bind == null) {
      _started = true;
      _start = widget.value;
      TSession.set(widget.fieldKey, widget.value);
    } else {
      TSession.forget(widget.fieldKey);
    }
    TSession.changes.addListener(_onSessionChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final key = TData.resolve(widget.bind!, TNav.programOf(context));
    _source = key == null ? null : (TData.instance.watch(key)..addListener(_onData));
    _seed(_source?.value);
  }

  void _seed(Object? stored) {
    final plan = widget.bindClass == TBindClass.plan;
    final String? text;
    if (identical(stored, TData.example) || identical(stored, TData.unset)) {
      text = identical(stored, TData.example) || plan ? widget.value : null;
    } else {
      text = stored is String && stored.isNotEmpty ? stored : null;
    }
    _start = text;
    _controller.text = text == null ? '' : _labelOf(text) ?? text;
    _empty = (text ?? '').isEmpty;
    if (!plan) return;
    text == null ? TSession.forget(widget.fieldKey) : TSession.set(widget.fieldKey, text);
  }

  void _onData() {
    if (_hadKey || !mounted) return;
    setState(() => _seed(_source!.value));
  }

  @override
  void dispose() {
    _source?.removeListener(_onData);
    TSession.changes.removeListener(_onSessionChange);
    _controller.dispose();
    super.dispose();
  }

  void _onSessionChange() {
    final key = widget.fieldKey;
    // A bound field's key is absent until the member types: only a scrub of
    // what the member typed empties it.
    if (key == null || TSession.values.containsKey(key) || (_controller.text.isEmpty && !_hadKey) || (widget.bind != null && !_hadKey)) return;
    _controller.clear();
    _hadKey = false;
    setState(() {
      _empty = true;
      _generation++;
    });
  }

  /// Largest text scale for the unit (mmHg, mg/dL...). The value keeps the
  /// full text scale; capping the shorter unit leaves the value room at large
  /// text sizes. No effect at 100%.
  static const unitMaxScale = 1.5;

  late bool _empty = (widget.value ?? '').isEmpty;

  String get label => widget.label;
  String? get value => widget.value;
  String? get unit => widget.unit;
  String? get hint => widget.hint;
  String? get error => widget.error;
  String? get placeholder => widget.placeholder;
  TFieldKind get kind => widget.kind;

  /// The shown label of option [value], or null when it is not an option.
  String? _labelOf(String value) {
    final options = widget.options;
    final i = options?.indexOf(value) ?? -1;
    return i < 0 ? null : (widget.optionLabels ?? options!)[i];
  }

  bool get _picks => kind == TFieldKind.select && (widget.options?.isNotEmpty ?? false);

  /// Opens the list of options; the picked option is written to the session.
  Future<void> _pick() async {
    final options = widget.options!;
    final labels = widget.optionLabels ?? options;
    final current = TSession.values[widget.fieldKey];
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: TColors.paper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(TRadius.sheet))),
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsetsDirectional.fromSTEB(TSpace.screen, 16, TSpace.screen, 12),
          children: [
            Semantics(header: true, child: Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(label, style: TText.cardTitle))),
            for (var i = 0; i < options.length; i++)
              Semantics(
                button: true,
                selected: options[i] == current,
                excludeSemantics: true,
                label: labels[i],
                onTap: () => Navigator.of(context).pop(options[i]),
                child: InkWell(
                  key: ValueKey('option:${options[i]}'),
                  borderRadius: BorderRadius.circular(TRadius.field),
                  onTap: () => Navigator.of(context).pop(options[i]),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Row(children: [
                      Expanded(child: Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(labels[i], style: TText.optionLabel))),
                      if (options[i] == current) const Icon(Icons.check_rounded, color: TColors.teal),
                    ]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    _hadKey = widget.fieldKey != null;
    _controller.text = _labelOf(picked) ?? picked;
    TSession.set(widget.fieldKey, picked);
    TSession.markTouched(widget.fieldKey, picked != _start);
    setState(() => _empty = false);
    widget.onChanged?.call(picked);
  }

  void onChanged(String v) {
    _hadKey = widget.fieldKey != null;
    TSession.set(widget.fieldKey, v.isEmpty ? null : v);
    TSession.markTouched(widget.fieldKey, (v.isEmpty ? null : v) != _start);
    if (v.isEmpty != _empty) setState(() => _empty = v.isEmpty);
    widget.onChanged?.call(v);
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(TRadius.field), borderSide: BorderSide(color: error != null ? TColors.error : TColors.line, width: 1.5));
    final keyboard = switch (kind) {
      TFieldKind.number => const TextInputType.numberWithOptions(decimal: true),
      TFieldKind.email => TextInputType.emailAddress,
      TFieldKind.phone => TextInputType.phone,
      TFieldKind.multiline => TextInputType.multiline,
      _ => TextInputType.text,
    };
    final readOnly = kind == TFieldKind.select || kind == TFieldKind.date;
    final unitStyle = TText.sub.copyWith(fontWeight: FontWeight.w700);
    final unitScaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: unitMaxScale);
    // Flutter shows a suffix only while the field has text, so an empty field
    // (P-31: every field starts empty) shows its unit as a suffix icon. Once
    // there is text the unit is the usual suffix, laid out as in the approved
    // design.
    final unitIcon = !readOnly && unit != null && _empty;
    final maxLines = kind == TFieldKind.multiline ? 4 : 1;
    // At large text sizes a hint beside the unit may need a second line
    // rather than being cut. One line at 100% and once there is text.
    final hintMaxLines = unitIcon ? 2 : null;
    final hintStyle = TText.input.copyWith(color: const Color(0xFF6B7F79), fontWeight: FontWeight.w400);
    // Screen readers: the field's label is the visible label above it, and
    // the example (placeholder) is its hint, never its label. The visible
    // label is announced once, as the field's label; the value is the typed
    // text. The example is drawn exactly as Flutter draws `hintText` (same
    // style, lines and overflow), but kept out of the semantics tree, where
    // `hintText` would become the field's label.
    final example = placeholder == null
        ? null
        : ExcludeSemantics(
            child: Text(
              placeholder!,
              style: Theme.of(context).textTheme.bodyLarge!.merge(hintStyle),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.start,
              maxLines: hintMaxLines ?? maxLines,
            ),
          );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (kind != TFieldKind.search) Padding(padding: const EdgeInsets.only(bottom: 6), child: ExcludeSemantics(child: Text(label, style: TText.fieldLabel))),
      Semantics(
        label: label,
        // A password's example is bullets: nothing useful to speak.
        hint: kind == TFieldKind.password ? null : placeholder,
        // A field that picks from a list opens it for a screen reader's tap.
        onTap: _picks ? _pick : null,
        // A new generation (after a scrub) is a new editable, with no undo
        // history.
        child: KeyedSubtree(
          key: ValueKey<int>(_generation),
          child: TextFormField(
            key: widget.fieldKey == null ? null : ValueKey('field:${widget.fieldKey}'),
            controller: _controller,
            obscureText: kind == TFieldKind.password,
            keyboardType: keyboard,
            readOnly: readOnly,
            onTap: _picks ? _pick : null,
            minLines: kind == TFieldKind.multiline ? 2 : 1,
            maxLines: maxLines,
            style: TText.input,
            onChanged: onChanged,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: error != null ? const Color(0xFFFFFBFA) : TColors.paper,
              hint: example,
              hintMaxLines: hintMaxLines,
              hintStyle: hintStyle,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
              prefixIcon: kind == TFieldKind.search ? const Icon(Icons.search_rounded, color: TColors.muted) : null,
              suffixIcon: readOnly
                  ? const Icon(Icons.expand_more_rounded, color: TColors.muted)
                  : unitIcon
                      ? Padding(padding: const EdgeInsetsDirectional.only(start: 8, end: 18, top: 2.67), child: Text(unit!, style: unitStyle, textScaler: unitScaler))
                      : null,
              suffixIconConstraints: unitIcon ? const BoxConstraints(minWidth: 0, minHeight: 0) : null,
              suffix: unit == null || unitIcon ? null : Text(unit!, style: unitStyle, textScaler: unitScaler),
              suffixStyle: unitStyle,
              enabledBorder: border,
              focusedBorder: border.copyWith(borderSide: const BorderSide(color: TColors.teal, width: 2)),
              semanticCounterText: label,
            ),
          ),
        ),
      ),
      if (error != null)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Semantics(
            liveRegion: true,
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.error_rounded, size: 16, color: TColors.error),
              const SizedBox(width: 6),
              Expanded(child: Text(error!, style: TText.small.copyWith(color: TColors.error, fontWeight: FontWeight.w700))),
            ]),
          ),
        )
      else if (hint != null)
        Padding(padding: const EdgeInsets.only(top: 5), child: Text(hint!, style: TText.small.copyWith(fontSize: 12.5))),
    ]);
  }
}

class TFieldRow extends StatelessWidget {
  const TFieldRow({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(width: 10), Expanded(child: children[i])]
      ]);
}

class TSliderField extends StatefulWidget {
  const TSliderField({super.key, required this.label, required this.value, this.min = 0, this.max = 10, this.minLabel, this.maxLabel, this.color = TColors.coral, this.suffix = '', this.onChanged, this.fieldKey});
  final String? fieldKey;
  final String label;
  final double value;
  final double min;
  final double max;
  final String? minLabel;
  final String? maxLabel;
  final Color color;
  final String suffix;
  final ValueChanged<double>? onChanged;
  @override
  State<TSliderField> createState() => _TSliderFieldState();
}

class _TSliderFieldState extends State<TSliderField> {
  late double _v = widget.value;
  @override
  void initState() {
    super.initState();
    TSession.markTouched(widget.fieldKey, false);
    TSession.set(widget.fieldKey, _v);
  }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // The value goes below the label when it does not fit beside it.
        _Beside(gap: 0, main: Text(widget.label, style: TText.label), aside: Text('${_v.round()}${widget.suffix}', style: TText.titleM.copyWith(fontSize: 22))),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(activeTrackColor: widget.color, inactiveTrackColor: TColors.line2, thumbColor: widget.color, trackHeight: 6, overlayColor: widget.color.withValues(alpha: 0.12)),
          child: Slider(
            value: _v,
            min: widget.min,
            max: widget.max,
            divisions: (widget.max - widget.min).round().clamp(1, 1000),
            semanticFormatterCallback: (v) => '${widget.label}: ${v.round()}${widget.suffix}',
            onChanged: (v) {
              setState(() => _v = v);
              TSession.set(widget.fieldKey, v);
              TSession.markTouched(widget.fieldKey, v != widget.value);
              widget.onChanged?.call(v);
            },
          ),
        ),
        // The end label wraps to its own line when both do not fit.
        Wrap(alignment: WrapAlignment.spaceBetween, children: [Text(widget.minLabel ?? '${widget.min.round()}', style: TText.small), Text(widget.maxLabel ?? '${widget.max.round()}', style: TText.small)]),
      ]);
}

class TZoneSelector extends StatefulWidget {
  const TZoneSelector({super.key, required this.selected, this.onChanged, this.rule});
  final String selected;

  /// When set, the zone is computed live from the form (e.g. 'ca.zone') and
  /// cannot be tapped.
  final String? rule;
  final ValueChanged<String>? onChanged;
  @override
  State<TZoneSelector> createState() => _TZoneSelectorState();
}

class _TZoneSelectorState extends State<TZoneSelector> {
  late String _sel = widget.selected;
  @override
  void initState() {
    super.initState();
    TSession.changes.addListener(_recompute);
    WidgetsBinding.instance.addPostFrameCallback((_) => _recompute());
  }

  @override
  void dispose() {
    TSession.changes.removeListener(_recompute);
    super.dispose();
  }

  void _recompute() {
    if (widget.rule == null || !mounted) return;
    final z = TRules.decide(widget.rule!, TSession.values)?.toLowerCase();
    if (z != null && z != _sel && ['green', 'yellow', 'red'].contains(z)) setState(() => _sel = z);
  }

  static const _z = <(String, Color, Color)>[
    ('green', TColors.okFill, TColors.okText),
    ('yellow', TColors.warnFill, TColors.warnText),
    ('red', TColors.errorFill, TColors.errorText),
  ];

  static String _name(TStrings s, String zone) => switch (zone) {
        'green' => s.kitZoneGreen,
        'yellow' => s.kitZoneYellow,
        _ => s.kitZoneRed,
      };

  @override
  Widget build(BuildContext context) => Row(children: [
        for (var i = 0; i < _z.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              selected: _sel == _z[i].$1,
              button: true,
              label: TStrings.of(context).kitZoneSemantics(zone: _name(TStrings.of(context), _z[i].$1)),
              child: GestureDetector(
                onTap: widget.rule != null
                    ? null
                    : () {
                        setState(() => _sel = _z[i].$1);
                        widget.onChanged?.call(_sel);
                      },
                child: Container(
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: _z[i].$2, borderRadius: BorderRadius.circular(12), border: Border.all(width: 2, color: _sel == _z[i].$1 ? TColors.teal : Colors.transparent)),
                  child: Text(_name(TStrings.of(context), _z[i].$1), style: TText.optionLabel.copyWith(color: _z[i].$3, fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ),
        ]
      ]);
}

// ============================================================== content

enum TBannerKind { offline, error, success, info, urgent }

class TBanner extends StatelessWidget {
  const TBanner({super.key, required this.kind, required this.text, this.actionLabel, this.onAction, this.actionKey});
  final Key? actionKey;
  final TBannerKind kind;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) {
    // A filled 20 pt circle with a glyph, as in the prototype (`.bn>b`).
    final (bg, fg, dot, glyph) = switch (kind) {
      TBannerKind.offline => (TColors.warnFill, TColors.warnText, TColors.warn, '≈'),
      TBannerKind.error => (TColors.errorFill, TColors.errorText, TColors.error, '!'),
      TBannerKind.success => (TColors.okFill, TColors.okText, TColors.ok, '✓'),
      TBannerKind.info => (const Color(0xFFEAF1EC), TColors.teal, TColors.teal, 'i'),
      TBannerKind.urgent => (TColors.error, Colors.white, Colors.white, '!'),
    };
    final glyphColor = kind == TBannerKind.urgent ? TColors.error : Colors.white;
    final message = Text(text, style: TText.label.copyWith(color: fg, fontWeight: FontWeight.w600, height: 1.4));
    // The action goes below the message when it does not fit beside it.
    return Semantics(
      liveRegion: kind == TBannerKind.error || kind == TBannerKind.urgent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ExcludeSemantics(child: Container(width: 20, height: 20, alignment: Alignment.center, decoration: BoxDecoration(color: dot, shape: BoxShape.circle), child: Text(glyph, style: TextStyle(fontSize: 12, height: 1, fontWeight: FontWeight.w700, color: glyphColor, fontFamilyFallback: const ['Roboto', 'sans-serif'])))),
          const SizedBox(width: 10),
          Expanded(child: actionLabel == null ? message : _Beside(gap: 0, center: false, main: message, aside: TextButton(key: actionKey, onPressed: onAction, child: Text(actionLabel!, style: TText.label.copyWith(color: fg, decoration: TextDecoration.underline))))),
        ]),
      ),
    );
  }
}

enum TCardVariant { plain, dark, dark2, coral, mint, urgent, warn, flat }

class TCard extends StatelessWidget {
  const TCard({super.key, this.variant = TCardVariant.plain, this.tag, this.tagExtra, this.eyebrow, this.title, this.text, this.accent, this.onTap, this.cta, this.children = const []});
  final TCardVariant variant;
  final String? tag;
  final String? tagExtra;
  final String? eyebrow;
  final String? title;
  final String? text;
  final String? accent;
  final VoidCallback? onTap;
  final Widget? cta;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final dark = variant == TCardVariant.dark || variant == TCardVariant.dark2;
    final (bg, borderC) = switch (variant) {
      TCardVariant.plain => (TColors.paper, const Color(0x8CB6C8C2)),
      TCardVariant.flat => (TColors.paper, const Color(0x8CB6C8C2)),
      TCardVariant.dark => (TColors.teal, Colors.transparent),
      TCardVariant.dark2 => (TColors.tealRaised, Colors.transparent),
      TCardVariant.coral => (TColors.coralFill, TColors.coralBorder),
      TCardVariant.mint => (const Color(0xFFDDEFE5), const Color(0xFFB8D7C9)),
      TCardVariant.urgent => (TColors.errorFill, TColors.errorBorder),
      TCardVariant.warn => (TColors.warnFill, TColors.warnBorder),
    };
    final titleColor = dark ? Colors.white : (variant == TCardVariant.urgent ? TColors.errorText : TColors.teal);
    final textColor = dark ? TColors.onDarkMuted : (variant == TCardVariant.urgent ? TColors.errorText : TColors.teal2);
    final content = Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      if (tag != null) ...[Align(alignment: AlignmentDirectional.centerStart, child: TProgramTag(program: tag!, extra: tagExtra)), const SizedBox(height: 6)],
      if (eyebrow != null) ...[TEyebrow(eyebrow!), const SizedBox(height: 4)],
      if (title != null) Text(title!, style: TText.cardTitle.copyWith(color: titleColor)),
      if (text != null) ...[const SizedBox(height: 3), Text(text!, style: TText.cardText.copyWith(color: textColor))],
      // Consecutive toggle rows are divided by a line (`.card .tgr+.tgr`).
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0 && children[i] is TToggleRow && children[i - 1] is TToggleRow) ...[const SizedBox(height: 6), const Divider(height: 1, thickness: 1, color: TColors.line2)] else const SizedBox(height: 8),
        children[i],
      ],
    ]);
    Widget body = content;
    if (cta != null || onTap != null) {
      // The call to action is as wide as its text (`.btn.sm{flex:none}`) and gives way
      // only at very large text, where it takes at most 60% of the card.
      body = LayoutBuilder(
        builder: (context, c) => Row(children: [
          Expanded(child: content),
          const SizedBox(width: 12),
          if (cta != null) ConstrainedBox(constraints: BoxConstraints(maxWidth: c.maxWidth * 0.6), child: cta!) else Icon(Icons.chevron_right_rounded, size: 26, color: dark ? TColors.onDarkMuted : TColors.muted),
        ]),
      );
    }
    final card = Container(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(TRadius.card),
        border: Border.all(color: borderC, width: variant == TCardVariant.urgent ? 1.5 : 1),
        boxShadow: variant == TCardVariant.flat || dark ? null : const [BoxShadow(color: Color(0x2E123C37), blurRadius: 20, offset: Offset(0, 10), spreadRadius: -14)],
      ),
      child: TDark(dark: dark, child: body),
    );
    final framed = accent == null
        ? card
        : ClipRRect(
            borderRadius: BorderRadius.circular(TRadius.card),
            child: Stack(children: [card, PositionedDirectional(start: 0, top: 0, bottom: 0, child: Container(width: 4, color: TColors.program(accent!)))]),
          );
    if (onTap == null) return framed;
    return Semantics(button: true, child: InkWell(borderRadius: BorderRadius.circular(TRadius.card), onTap: onTap, child: framed));
  }
}

class TKeyValue extends StatelessWidget {
  const TKeyValue({super.key, required this.rows});
  final List<(String, String)> rows;
  @override
  Widget build(BuildContext context) => TCard(children: [
        for (var i = 0; i < rows.length; i++)
          Container(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
            decoration: BoxDecoration(border: i == 0 ? null : const Border(top: BorderSide(color: TColors.line2))),
            // Label at the start and value at the end (`.kv{justify-content:space-between}`),
            // each as wide as its text; when both do not fit they shrink in proportion to
            // their width, as flex items do.
            child: LayoutBuilder(builder: (context, c) {
              final labelStyle = TText.cardText.copyWith(fontSize: 14);
              final valueStyle = TText.cardText.copyWith(fontSize: 14, color: TColors.teal, fontWeight: FontWeight.w700);
              double width(String text, TextStyle style) => (TextPainter(
                    text: TextSpan(text: text, style: style),
                    textDirection: Directionality.of(context),
                    textScaler: MediaQuery.textScalerOf(context),
                    maxLines: 1,
                  )..layout())
                  .width;
              final label = width(rows[i].$1, labelStyle), value = width(rows[i].$2, valueStyle);
              return Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Flexible(flex: label.ceil() + 1, child: Text(rows[i].$1, style: labelStyle)),
                const SizedBox(width: 16),
                Flexible(flex: value.ceil() + 1, child: Text(rows[i].$2, textAlign: TextAlign.end, style: valueStyle)),
              ]);
            }),
          ),
      ]);
}

class TLead {
  const TLead._({this.program, this.avatar, this.icon});
  const TLead.program(String id) : this._(program: id);
  const TLead.avatar(String letter) : this._(avatar: letter);
  const TLead.icon(String glyph) : this._(icon: glyph);
  final String? program;
  final String? avatar;
  final String? icon;
}

class TListRow extends StatelessWidget {
  const TListRow({super.key, required this.label, this.sub, this.value, this.lead, this.pill, this.danger = false, this.onTap, this.first = false});
  final String label;
  final String? sub;
  final String? value;
  final TLead? lead;
  final String? pill;
  final bool danger;
  final VoidCallback? onTap;
  final bool first;
  @override
  Widget build(BuildContext context) {
    final text = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TText.optionLabel.copyWith(color: danger ? TColors.error : null)),
      if (sub != null) Text(sub!, style: TText.sub),
    ]);
    // The value and pill go below the label when they do not fit beside it.
    final aside = [
      if (value != null) Text(value!, style: TText.sub.copyWith(color: TColors.teal, fontWeight: FontWeight.w700)),
      if (pill != null) TPill(pill!),
    ];
    final row = Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(children: [
        if (lead?.program != null) ...[TProgramBadge(lead!.program!), const SizedBox(width: 12)],
        if (lead?.avatar != null) ...[TAvatar(lead!.avatar!), const SizedBox(width: 12)],
        if (lead?.icon != null) ...[TAvatar(lead!.icon!, icon: true), const SizedBox(width: 12)],
        Expanded(child: aside.isEmpty ? text : _Beside(main: text, aside: aside.length == 1 ? aside.single : Row(mainAxisSize: MainAxisSize.min, children: [aside.first, const SizedBox(width: 8), aside.last]))),
        if (onTap != null) ...[const SizedBox(width: 4), const Icon(Icons.chevron_right_rounded, size: 26, color: TColors.muted)],
      ]),
    );
    if (onTap == null) return row;
    return Semantics(button: true, child: InkWell(onTap: onTap, child: row));
  }
}

class TListGroup extends StatelessWidget {
  const TListGroup({super.key, this.title, required this.rows, this.flat = false});
  final String? title;
  final List<TListRow> rows;
  final bool flat;
  @override
  Widget build(BuildContext context) {
    final list = Column(children: [
      for (var i = 0; i < rows.length; i++) DecoratedBox(decoration: BoxDecoration(border: i == 0 ? null : const Border(top: BorderSide(color: TColors.line2))), child: rows[i]),
    ]);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (title != null) Padding(padding: const EdgeInsets.only(bottom: 6), child: TEyebrow(title!)),
      if (flat)
        list
      else
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          decoration: BoxDecoration(color: TColors.paper, borderRadius: BorderRadius.circular(TRadius.card), border: Border.all(color: const Color(0x8CB6C8C2)), boxShadow: const [BoxShadow(color: Color(0x2E123C37), blurRadius: 20, offset: Offset(0, 10), spreadRadius: -14)]),
          child: list,
        ),
    ]);
  }
}

class TTile {
  const TTile({required this.label, String? value, this.sub, this.program, this.glyph, this.color, this.selected = false, this.onTap, this.key}) : _value = value;
  final Key? key;

  /// The text shown, in the app language.
  final String label;
  final String? _value;

  /// The stable value written to the session; [label] when not given.
  String get value => _value ?? label;
  final String? sub;
  final String? program;
  final String? glyph;
  final Color? color;
  final bool selected;
  final VoidCallback? onTap;
}

class TTileGrid extends StatefulWidget {
  const TTileGrid({super.key, required this.tiles, this.columns = 2, this.fieldKey});
  final List<TTile> tiles;
  final int columns;

  /// Session key. When set, the labels of the selected tiles (tiles without
  /// [TTile.onTap]) are written to [TSession] (the program picker).
  final String? fieldKey;
  @override
  State<TTileGrid> createState() => _TTileGridState();
}

class _TTileGridState extends State<TTileGrid> {
  late final List<bool> _sel = [for (final t in widget.tiles) t.selected];
  List<String> get _labels => [
        for (var i = 0; i < widget.tiles.length; i++)
          if (_sel[i] && widget.tiles[i].onTap == null) widget.tiles[i].value
      ];
  late final List<String> _start = _labels;
  void _store() {
    TSession.set(widget.fieldKey, _labels);
    TSession.markTouched(widget.fieldKey, !_sameValue(_labels, _start));
  }

  @override
  void initState() {
    super.initState();
    TSession.markTouched(widget.fieldKey, false);
    TSession.set(widget.fieldKey, _start);
  }

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < widget.tiles.length; i += widget.columns) {
      rows.add(IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var j = i; j < i + widget.columns; j++) ...[
            if (j > i) const SizedBox(width: 10),
            Expanded(child: j < widget.tiles.length ? _tile(j) : const SizedBox()),
          ]
        ]),
      ));
    }
    return Column(children: _gap(rows, 10));
  }

  Widget _tile(int i) {
    final t = widget.tiles[i];
    final on = _sel[i];
    return Semantics(
      button: true,
      checked: t.onTap == null ? on : null,
      child: InkWell(
        key: t.key,
        borderRadius: BorderRadius.circular(TRadius.tile),
        onTap: t.onTap ??
            () {
              setState(() => _sel[i] = !_sel[i]);
              _store();
            },
        child: Container(
          constraints: const BoxConstraints(minHeight: 104),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(color: on ? TColors.mintTint : TColors.paper, borderRadius: BorderRadius.circular(TRadius.tile), border: Border.all(width: 1.5, color: on ? TColors.teal : TColors.line2)),
          child: Stack(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (t.program != null)
                TProgramBadge(t.program!)
              else
                Container(width: 36, height: 36, alignment: Alignment.center, decoration: BoxDecoration(color: t.color ?? TColors.teal2, borderRadius: BorderRadius.circular(11)), child: Text(t.glyph ?? '•', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15))),
              const SizedBox(height: 6),
              Text(t.label, style: TText.optionLabel.copyWith(fontSize: 15)),
              if (t.sub != null) Text(t.sub!, style: TText.sub),
            ]),
            if (on) const PositionedDirectional(top: 0, end: 0, child: CircleAvatar(radius: 11, backgroundColor: TColors.teal, child: Icon(Icons.check_rounded, size: 14, color: TColors.lime))),
          ]),
        ),
      ),
    );
  }
}

class TStat {
  const TStat({required this.label, required this.value, this.sub, this.program});
  final String label;
  final String value;
  final String? sub;
  final String? program;
}

class TStatGrid extends StatelessWidget {
  const TStatGrid({super.key, required this.stats, this.columns = 2});
  final List<TStat> stats;
  final int columns;
  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < stats.length; i += columns) {
      rows.add(IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var j = i; j < i + columns; j++) ...[
            if (j > i) const SizedBox(width: 10),
            Expanded(child: j < stats.length ? _stat(stats[j]) : const SizedBox()),
          ]
        ]),
      ));
    }
    return Column(children: _gap(rows, 10));
  }

  Widget _stat(TStat s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: TColors.paper, borderRadius: BorderRadius.circular(TRadius.tile), border: Border.all(color: TColors.line2)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (s.program != null) TProgramTag(program: s.program!, extra: s.label, muted: true) else TEyebrow(s.label),
          const SizedBox(height: 3),
          Text(s.value, style: TText.stat),
          if (s.sub != null) Text(s.sub!, style: TText.sub.copyWith(fontSize: 12.5)),
        ]),
      );
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({this.title, this.unit, this.tag, this.caption, this.onTap, required this.chart});
  final String? title;
  final String? unit;
  final String? tag;
  final String? caption;
  final VoidCallback? onTap;
  final Widget chart;
  @override
  Widget build(BuildContext context) {
    final titleRow = Row(children: [
      Expanded(child: Text(title ?? '', style: TText.label)),
      if (unit != null) Flexible(child: Text(unit!, textAlign: TextAlign.end, style: TText.sub)),
    ]);
    return TCard(onTap: onTap, children: [
      // The program tag goes above the title when both do not fit.
      if (tag == null) titleRow else _Beside(asideFirst: true, aside: TProgramTag(program: tag!), main: titleRow),
      chart,
      if (caption != null) Text(caption!, style: TText.cardText),
    ]);
  }
}

class TBarChart extends StatelessWidget {
  const TBarChart({super.key, required this.values, required this.color, this.title, this.unit, this.missing = const [], this.target, this.labels = const [], this.caption, this.tag, this.onTap});
  final List<double> values;
  final Color color;
  final String? title;
  final String? unit;
  final List<int> missing;
  final double? target;
  final List<String> labels;
  final String? caption;
  final String? tag;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final mx = [...values, target ?? 0].reduce((a, b) => a > b ? a : b);
    final maxV = mx <= 0 ? 1.0 : mx;
    return _ChartCard(
      title: title,
      unit: unit,
      tag: tag,
      caption: caption,
      onTap: onTap,
      chart: Semantics(
        label: TStrings.of(context).kitChartSemantics(title: title ?? TStrings.of(context).kitChart, values: [for (var i = 0; i < values.length; i++) missing.contains(i) ? TStrings.of(context).kitChartNoEntry : values[i].round().toString()].join(', ')),
        child: Column(children: [
          SizedBox(
            height: 96,
            child: Stack(children: [
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                for (var i = 0; i < values.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: missing.contains(i)
                        ? Container(height: 25, decoration: BoxDecoration(border: Border.all(color: TColors.line), borderRadius: const BorderRadius.vertical(top: Radius.circular(5)), color: TColors.line2.withValues(alpha: 0.5)))
                        : Container(height: (values[i] / maxV * 96).clamp(4, 96).toDouble(), decoration: BoxDecoration(color: color.withValues(alpha: 0.9), borderRadius: const BorderRadius.vertical(top: Radius.circular(5)))),
                  ),
                ]
              ]),
              if (target != null) PositionedDirectional(start: 0, end: 0, bottom: target! / maxV * 96, child: Container(height: 2, color: TColors.teal)),
            ]),
          ),
          if (labels.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Row(children: [
                for (var i = 0; i < labels.length; i++) ...[if (i > 0) const SizedBox(width: 8), Expanded(child: Text(labels[i], textAlign: TextAlign.center, style: TText.sub.copyWith(fontSize: 11)))]
              ]),
            ),
        ]),
      ),
    );
  }
}

class TLineChart extends StatelessWidget {
  const TLineChart({super.key, required this.values, required this.color, this.title, this.unit, this.band, this.caption, this.tag, this.onTap});
  final List<double> values;
  final Color color;
  final String? title;
  final String? unit;
  final List<double>? band;
  final String? caption;
  final String? tag;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => _ChartCard(
        title: title,
        unit: unit,
        tag: tag,
        caption: caption,
        onTap: onTap,
        chart: Semantics(
          label: TStrings.of(context).kitChartSemantics(title: title ?? TStrings.of(context).kitChart, values: values.map((v) => v.round()).join(', ')),
          child: SizedBox(height: 110, width: double.infinity, child: CustomPaint(painter: _LinePainter(values, color, band))),
        ),
      );
}

class _LinePainter extends CustomPainter {
  _LinePainter(this.values, this.color, this.band);
  final List<double> values;
  final Color color;
  final List<double>? band;
  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final all = [...values, ...?band];
    final lo = all.reduce((a, b) => a < b ? a : b), hi = all.reduce((a, b) => a > b ? a : b);
    final rng = (hi - lo) == 0 ? 1 : hi - lo;
    const pad = 6.0;
    double y(double v) => pad + (size.height - 2 * pad) * (1 - (v - lo) / rng);
    double x(int i) => pad + (size.width - 2 * pad) * i / (values.length - 1);
    if (band != null) {
      canvas.drawRect(Rect.fromLTRB(0, y(band![1]), size.width, y(band![0])), Paint()..color = const Color(0xFFE4F1E9));
    }
    final path = Path()..moveTo(x(0), y(values[0]));
    for (var i = 1; i < values.length; i++) {
      path.lineTo(x(i), y(values[i]));
    }
    canvas.drawPath(path, Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round);
    for (var i = 0; i < values.length; i++) {
      canvas.drawCircle(Offset(x(i), y(values[i])), 3, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.values != values || old.color != color;
}

enum TRingPalette { teal, indigo }

/// Breathing guide. Scales gently; respects the OS Reduce Motion setting.
class TBreathRing extends StatefulWidget {
  const TBreathRing({super.key, required this.value, this.label, this.palette = TRingPalette.teal});
  final String value;

  /// The label under the number; the kit's localized "SECONDS" when null.
  final String? label;
  final TRingPalette palette;
  @override
  State<TBreathRing> createState() => _TBreathRingState();
}

class _TBreathRingState extends State<TBreathRing> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 8));
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _c.stop();
      _c.value = 0.5;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.label ?? TStrings.of(context).kitSeconds;
    final cols = widget.palette == TRingPalette.teal ? const [Color(0xFF2B6258), Color(0xFF1C5149), Color(0xFF174640)] : const [Color(0xFF5566D8), Color(0xFF4656C9), Color(0xFF3A49B5)];
    return Center(
      child: Semantics(
        label: TStrings.of(context).kitRingSemantics(value: widget.value, label: label.toLowerCase()),
        child: ScaleTransition(
          scale: Tween(begin: 0.9, end: 1.04).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
          child: Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(shape: BoxShape.circle, color: cols[2]),
            alignment: Alignment.center,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(shape: BoxShape.circle, color: cols[1]),
              alignment: Alignment.center,
              child: Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(shape: BoxShape.circle, color: cols[0]),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(12),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(widget.value, style: const TextStyle(color: Colors.white, fontSize: 46, fontWeight: FontWeight.w800, height: 1)),
                    Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, letterSpacing: 1.3)),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TBigNumber extends StatelessWidget {
  const TBigNumber({super.key, required this.value, this.unit, this.caption, this.center = false});
  final String value;
  final String? unit;
  final String? caption;
  final bool center;
  @override
  Widget build(BuildContext context) {
    final dark = TDark.of(context);
    return Column(crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start, children: [
      Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
        Flexible(child: FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: Text(value, maxLines: 1, style: TText.big.copyWith(color: dark ? Colors.white : null)))),
        if (unit != null) ...[const SizedBox(width: 6), Text(unit!, style: TText.sub.copyWith(fontSize: 15, fontWeight: FontWeight.w700, color: dark ? TColors.onDarkMuted : null))],
      ]),
      if (caption != null) ...[const SizedBox(height: 4), Text(caption!, style: TText.small.copyWith(color: dark ? TColors.onDarkMuted : TColors.teal2))],
    ]);
  }
}

class TTimer extends StatelessWidget {
  const TTimer({super.key, required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        label: TStrings.of(context).kitTimerSemantics(value: value, label: label),
        // The prototype's line height is 1.45 for the value (56 pt) and for the label's line (15 pt).
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(children: [
            Text(value, style: TText.big.copyWith(fontSize: 56, height: 1.45, fontFeatures: const [FontFeature.tabularFigures()])),
            Text(label, style: TText.small, strutStyle: const StrutStyle(fontSize: 15, height: 1.45, forceStrutHeight: true)),
          ]),
        ),
      );
}

/// A month calendar.
///
/// With a [fieldKey] and the app's own [TData] it is a real calendar: it
/// opens on the current month, the member moves between months and taps a day,
/// and the chosen day is the session value [fieldKey] as `yyyy-MM-dd`. Days
/// run from tomorrow to [maxDaysAhead] days ahead; the days [recommendedFrom]
/// to [recommendedTo] days ahead are marked as recommended. A date that the
/// session already holds for the key, and that is still allowed, is chosen
/// when it opens; the key is empty until a day is chosen.
///
/// With preview data ([TData.isPreview]), or without a [fieldKey], it draws
/// the design: [month] with [selected], [window] and [today], and nothing is
/// tappable. A keyed design calendar writes its chosen day ([year],
/// [monthNumber], [selected]) to the session when built, as the other
/// controls write their starting values.
class TCalendar extends StatefulWidget {
  const TCalendar({super.key, required this.month, required this.selected, required this.window, this.today, this.firstWeekday = 6, this.days = 31, this.fieldKey, this.year, this.monthNumber});
  final String month;
  final int selected;
  final List<int> window;
  final int? today;
  final int firstWeekday; // 0 = Sunday
  final int days;

  /// Session key of the chosen date.
  final String? fieldKey;

  /// The design's year and month (1-12); only used to write the design's
  /// chosen day to the session.
  final int? year;
  final int? monthNumber;

  /// The latest day that can be chosen, in days from today.
  static const int maxDaysAhead = 90;

  /// The recommended window, in days from today (first and last).
  static const int recommendedFrom = 7;
  static const int recommendedTo = 14;

  /// The current time. Tests replace it.
  static DateTime Function() clock = DateTime.now;

  /// `yyyy-MM-dd` of [date].
  static String iso(DateTime date) => '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// The date held by [raw], a `yyyy-MM-dd` string naming a real day, or null.
  static DateTime? parseIso(Object? raw) {
    if (raw is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) return null;
    final date = DateTime.tryParse(raw);
    return date != null && iso(date) == raw ? DateUtils.dateOnly(date) : null;
  }

  /// [date] in full, for example "Friday, August 28, 2026", in the app language.
  static String fullDate(TStrings s, DateTime date) =>
      s.kitDateFull(weekday: s.kitWeekdayNames.split('|')[date.weekday % 7], month: s.kitMonthNames.split('|')[date.month - 1], day: date.day, year: date.year);

  /// Today, without the time.
  static DateTime get currentDay => DateUtils.dateOnly(clock());

  /// The day [days] calendar days after [from] (a daylight-saving change in
  /// between does not shift it).
  static DateTime daysAfter(DateTime from, int days) => DateTime(from.year, from.month, from.day + days);

  /// The whole calendar days from [from] to [to].
  static int daysBetween(DateTime from, DateTime to) => DateTime.utc(to.year, to.month, to.day).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

  @override
  State<TCalendar> createState() => _TCalendarState();
}

class _TCalendarState extends State<TCalendar> {
  late final bool _design = widget.fieldKey == null || TData.isPreview;
  DateTime? _selected;
  DateTime? _start;
  late DateTime _shown;

  DateTime get _min => TCalendar.daysAfter(TCalendar.currentDay, 1);
  DateTime get _max => TCalendar.daysAfter(TCalendar.currentDay, TCalendar.maxDaysAhead);
  bool _allowed(DateTime d) => !d.isBefore(_min) && !d.isAfter(_max);

  @override
  void initState() {
    super.initState();
    final key = widget.fieldKey;
    TSession.markTouched(key, false);
    if (_design) {
      final year = widget.year, month = widget.monthNumber;
      if (key != null && year != null && month != null) TSession.set(key, TCalendar.iso(DateTime(year, month, widget.selected)));
      return;
    }
    final kept = TCalendar.parseIso(TSession.values[key]);
    _selected = _start = kept != null && _allowed(kept) ? kept : null;
    _shown = DateTime((_selected ?? _min).year, (_selected ?? _min).month);
    _selected == null ? TSession.forget(key) : TSession.set(key, TCalendar.iso(_selected!));
  }

  void _choose(DateTime date) {
    setState(() => _selected = date);
    TSession.set(widget.fieldKey, TCalendar.iso(date));
    TSession.markTouched(widget.fieldKey, date != _start);
  }

  void _move(int months) => setState(() => _shown = DateTime(_shown.year, _shown.month + months));

  @override
  Widget build(BuildContext context) => _design ? _buildDesign(context) : _buildLive(context);

  Widget _buildDesign(BuildContext context) {
    final TCalendar(:month, :selected, :window, :today, :firstWeekday, :days) = widget;
    final cells = <Widget>[
      for (final d in TStrings.of(context).kitWeekdayInitials.split(' ')) Center(child: Text(d, style: TText.eyebrow)),
      for (var i = 0; i < firstWeekday; i++) const SizedBox(),
      for (var d = 1; d <= days; d++)
        Semantics(
          selected: d == selected,
          button: true,
          label: TStrings.of(context).kitCalendarDay(month: month, day: d),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: d == selected ? TColors.teal : (window.contains(d) ? TColors.mint : null),
              borderRadius: BorderRadius.circular(10),
              border: d == today ? Border.all(color: TColors.teal, width: 1.5) : null,
            ),
            child: Text('$d', style: TText.chip.copyWith(color: d == selected ? Colors.white : TColors.teal, fontWeight: d == selected ? FontWeight.w800 : FontWeight.w600)),
          ),
        ),
    ];
    final s = TStrings.of(context);
    final abbreviations = s.kitMonthAbbreviations.split('|');
    final monthName = widget.monthNumber != null ? abbreviations[widget.monthNumber! - 1] : month.split(' ').first;
    return TCard(children: [
      Row(children: [Expanded(child: Text(month, style: TText.label)), const Icon(Icons.chevron_left_rounded, color: TColors.muted), const Icon(Icons.chevron_right_rounded, color: TColors.muted)]),
      GridView.count(crossAxisCount: 7, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 4, crossAxisSpacing: 4, childAspectRatio: 1.2, children: cells),
      if (window.isNotEmpty) _windowCaption(s.kitDateShort(month: monthName, day: window.first), s.kitDateShort(month: monthName, day: window.last), s),
    ]);
  }

  Widget _buildLive(BuildContext context) {
    final s = TStrings.of(context);
    final months = s.kitMonthNames.split('|');
    final today = TCalendar.currentDay;
    final first = DateTime(_shown.year, _shown.month);
    final canGoBack = first.isAfter(DateTime(_min.year, _min.month));
    final canGoOn = first.isBefore(DateTime(_max.year, _max.month));
    final recommendedStart = TCalendar.daysAfter(today, TCalendar.recommendedFrom);
    final recommendedEnd = TCalendar.daysAfter(today, TCalendar.recommendedTo);
    final cells = <Widget>[
      for (final d in s.kitWeekdayInitials.split(' ')) ExcludeSemantics(child: Center(child: Text(d, style: TText.eyebrow))),
      for (var i = 0; i < first.weekday % 7; i++) const SizedBox(),
      for (var d = 1; d <= DateUtils.getDaysInMonth(first.year, first.month); d++) _day(s, DateTime(first.year, first.month, d), today, recommendedStart, recommendedEnd),
    ];
    return TCard(children: [
      Row(children: [
        Expanded(child: Semantics(header: true, child: Text(s.kitCalendarTitle(month: months[first.month - 1], year: first.year), style: TText.label))),
        IconButton(key: const ValueKey('calendar-prev'), tooltip: s.kitCalendarPrev, onPressed: canGoBack ? () => _move(-1) : null, icon: const Icon(Icons.chevron_left_rounded), color: TColors.teal, disabledColor: TColors.line),
        IconButton(key: const ValueKey('calendar-next'), tooltip: s.kitCalendarNext, onPressed: canGoOn ? () => _move(1) : null, icon: const Icon(Icons.chevron_right_rounded), color: TColors.teal, disabledColor: TColors.line),
      ]),
      GridView.count(crossAxisCount: 7, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 1, children: cells),
      _windowCaption(_short(s, recommendedStart), _short(s, recommendedEnd), s),
    ]);
  }

  String _short(TStrings s, DateTime date) => s.kitDateShort(month: s.kitMonthAbbreviations.split('|')[date.month - 1], day: date.day);

  /// "Recommended window: Aug 28 – Aug 31" under the grid (the prototype's caption).
  Widget _windowCaption(String start, String end, TStrings s) => Text(s.kitCalendarWindow(start: start, end: end), style: TText.cardText);

  Widget _day(TStrings s, DateTime date, DateTime today, DateTime recommendedStart, DateTime recommendedEnd) {
    final allowed = _allowed(date);
    final chosen = date == _selected;
    final recommended = !date.isBefore(recommendedStart) && !date.isAfter(recommendedEnd);
    return Semantics(
      button: true,
      enabled: allowed,
      selected: chosen,
      excludeSemantics: true,
      label: TCalendar.fullDate(s, date),
      hint: allowed && recommended ? s.kitCalendarRecommended : null,
      onTap: allowed ? () => _choose(date) : null,
      child: InkWell(
        key: ValueKey('calendar-day-${TCalendar.iso(date)}'),
        borderRadius: BorderRadius.circular(10),
        onTap: allowed ? () => _choose(date) : null,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: chosen ? TColors.teal : (allowed && recommended ? TColors.mint : null),
              borderRadius: BorderRadius.circular(10),
              border: date == today ? Border.all(color: TColors.teal, width: 1.5) : null,
            ),
            child: Text(
              '${date.day}',
              style: TText.chip.copyWith(color: chosen ? Colors.white : (allowed ? TColors.teal : TColors.disabledFg.withValues(alpha: 0.55)), fontWeight: chosen ? FontWeight.w800 : FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}

/// Runs [builder] again whenever [TSession] changes. A change made while the
/// tree is being built (an input writing its starting value) rebuilds after
/// the frame instead of during it.
class _OnSession extends StatefulWidget {
  const _OnSession({required this.builder});
  final WidgetBuilder builder;

  @override
  State<_OnSession> createState() => _OnSessionState();
}

class _OnSessionState extends State<_OnSession> {
  @override
  void initState() {
    super.initState();
    TSession.changes.addListener(_changed);
  }

  @override
  void dispose() {
    TSession.changes.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (!mounted) return;
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

/// The card that sums up the date chosen in a [TCalendar] ([fieldKey] is the
/// calendar's key): the date in full and the days left to prepare, under
/// [eyebrow]. It draws nothing until a day is chosen. With preview data it is
/// [design], the design's card.
class TDateSummary extends StatelessWidget {
  const TDateSummary({super.key, required this.fieldKey, this.eyebrow, required this.design});
  final String fieldKey;
  final String? eyebrow;
  final Widget design;

  @override
  Widget build(BuildContext context) {
    if (TData.isPreview) return design;
    return _OnSession(builder: (context) {
      final date = TCalendar.parseIso(TSession.values[fieldKey]);
      if (date == null) return const SizedBox.shrink();
      final s = TStrings.of(context);
      final left = TCalendar.daysBetween(TCalendar.currentDay, date);
      return TCard(variant: TCardVariant.dark, eyebrow: eyebrow, title: TCalendar.fullDate(s, date), text: left > 0 ? s.kitDaysToPrepare(n: left) : null);
    });
  }
}

// ============================================================== actions

enum TButtonVariant { primary, rescue, secondary, danger, lime, white, ghostDark }

class TButton extends StatelessWidget {
  const TButton({super.key, required this.label, this.onPressed, this.variant = TButtonVariant.primary, this.small = false, this.arrow = false, this.loading = false});
  final String label;
  final VoidCallback? onPressed;
  final TButtonVariant variant;
  final bool small;
  final bool arrow;
  final bool loading;
  @override
  Widget build(BuildContext context) {
    final darkCtx = TDark.of(context);
    var (bg, fg, border) = switch (variant) {
      TButtonVariant.primary => (TColors.teal, Colors.white, Colors.transparent),
      TButtonVariant.rescue => (TColors.coral, TColors.teal, Colors.transparent),
      TButtonVariant.secondary => (Colors.transparent, darkCtx ? Colors.white : TColors.teal, darkCtx ? TColors.tealBorder : TColors.line),
      TButtonVariant.danger => (TColors.error, Colors.white, Colors.transparent),
      TButtonVariant.lime => (TColors.lime, TColors.teal, Colors.transparent),
      TButtonVariant.white => (Colors.white, TColors.teal, Colors.transparent),
      TButtonVariant.ghostDark => (Colors.transparent, Colors.white, TColors.tealBorder),
    };
    if (onPressed == null) {
      bg = TColors.disabledBg;
      fg = TColors.disabledFg;
      border = Colors.transparent;
    }
    final arrowColor = (variant == TButtonVariant.primary && onPressed != null) ? TColors.lime : fg;
    final child = loading
        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: fg))
        : Row(mainAxisSize: small ? MainAxisSize.min : MainAxisSize.max, mainAxisAlignment: arrow ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center, children: [
            Flexible(child: Text(label, textAlign: arrow ? TextAlign.start : TextAlign.center, style: (small ? TText.buttonSmall : TText.button).copyWith(color: fg))),
            if (arrow) ...[const SizedBox(width: 10), Icon(Icons.arrow_forward_rounded, color: arrowColor, size: 20)],
          ]);
    return Semantics(
      button: true,
      enabled: onPressed != null,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(small ? 11 : TRadius.control), side: BorderSide(color: border, width: 1.5)),
        child: InkWell(
          borderRadius: BorderRadius.circular(small ? 11 : TRadius.control),
          onTap: loading ? null : onPressed,
          child: Container(
            constraints: BoxConstraints(minHeight: small ? 40 : 52, minWidth: 44),
            width: small ? null : double.infinity,
            padding: EdgeInsets.symmetric(horizontal: small ? 14 : 18, vertical: 8),
            // A small button is as wide as its text (`.btn.sm{width:auto;flex:none}`):
            // an alignment would make the container fill the width it is given.
            alignment: small ? null : (arrow ? AlignmentDirectional.centerStart : Alignment.center),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A [TButton] that works only once an input of the screen holds a value:
/// disabled while [TSession] has nothing for [fieldKey] (no value, blank
/// text or an empty list). When the value is a list (the selected programs),
/// [countLabel] gives the label for the number chosen and [emptyLabel] the
/// label while none is; otherwise [label] is shown (and [emptyLabel], while
/// the button is disabled, when given).
class TGatedButton extends StatelessWidget {
  const TGatedButton({super.key, required this.fieldKey, this.label, this.countLabel, this.emptyLabel, this.onPressed, this.variant = TButtonVariant.primary, this.small = false, this.arrow = false})
      : assert(label != null || countLabel != null, 'a gated button needs a label');
  final String fieldKey;
  final String? label;
  final String Function(int count)? countLabel;
  final String? emptyLabel;
  final VoidCallback? onPressed;
  final TButtonVariant variant;
  final bool small;
  final bool arrow;

  /// Whether [value] counts as chosen.
  static bool hasValue(Object? value) => switch (value) {
        null => false,
        final String text => text.trim().isNotEmpty,
        final Iterable<Object?> items => items.isNotEmpty,
        _ => true,
      };

  @override
  Widget build(BuildContext context) => _OnSession(builder: (context) {
        final value = TSession.values[fieldKey];
        final ready = hasValue(value);
        final count = value is List<Object?> ? value.length : null;
        final text = ready
            ? (countLabel != null && count != null ? countLabel!(count) : (label ?? emptyLabel ?? ''))
            : (emptyLabel ?? label ?? '');
        return TButton(label: text, onPressed: ready ? onPressed : null, variant: variant, small: small, arrow: arrow);
      });
}

class TButtonRow extends StatelessWidget {
  const TButtonRow({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Wrap(spacing: 8, runSpacing: 8, children: children);
}

class TLink extends StatelessWidget {
  const TLink({super.key, required this.label, required this.onTap, this.alignLeft = false});
  final String label;
  final VoidCallback onTap;
  final bool alignLeft;
  @override
  Widget build(BuildContext context) => Semantics(
        link: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            // The row is the tap target; the text sits at the start for alignLeft
            // (`.lnk.left`) and in the middle otherwise.
            alignment: alignLeft ? AlignmentDirectional.centerStart : Alignment.center,
            child: Text(label, textAlign: alignLeft ? TextAlign.start : TextAlign.center, style: TText.label.copyWith(fontSize: 15, color: TDark.of(context) ? Colors.white : TColors.teal, decoration: TextDecoration.underline)),
          ),
        ),
      );
}

class TQuote extends StatelessWidget {
  const TQuote(this.text, {super.key, this.caption});
  final String text;
  final String? caption;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(TStrings.of(context).kitQuote(text: text), style: TText.quote),
        if (caption != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(caption!, style: TText.sub)),
      ]);
}

enum TTone { mint, error, warn, dark }

class TIllustration extends StatelessWidget {
  const TIllustration({super.key, required this.glyph, this.tone = TTone.mint});
  final String glyph;
  final TTone tone;
  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      TTone.mint => (TColors.mint, TColors.teal),
      TTone.error => (TColors.errorFill, TColors.error),
      TTone.warn => (TColors.warnFill, TColors.warn),
      TTone.dark => (const Color(0xFF234E48), TColors.lime),
    };
    return ExcludeSemantics(
      child: Center(
        child: Container(
          width: 88,
          height: 88,
          margin: const EdgeInsets.only(top: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
          child: Text(glyph, style: TextStyle(fontFamily: 'Georgia', fontSize: 36, fontWeight: FontWeight.w800, color: fg)),
        ),
      ),
    );
  }
}

class TEmergencyCard extends StatelessWidget {
  const TEmergencyCard({super.key, required this.text, required this.actions});
  final String text;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: TStrings.of(context).kitEmergencyHelp,
        child: TCard(variant: TCardVariant.urgent, title: text, children: [TButtonRow(children: actions)]),
      );
}

class TSkeleton extends StatefulWidget {
  const TSkeleton({super.key, this.lines = 3});
  final int lines;
  @override
  State<TSkeleton> createState() => _TSkeletonState();
}

class _TSkeletonState extends State<TSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!(MediaQuery.maybeDisableAnimationsOf(context) ?? false) && !_c.isAnimating) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const widths = [0.55, 0.9, 0.72, 0.4];
    return Semantics(
      label: TStrings.of(context).kitLoading,
      child: TCard(children: [
        for (var i = 0; i < widget.lines.clamp(1, 4); i++)
          FadeTransition(
            opacity: Tween(begin: 0.45, end: 1.0).animate(_c),
            child: FractionallySizedBox(alignment: AlignmentDirectional.centerStart, widthFactor: widths[i], child: Container(height: 12, decoration: BoxDecoration(color: const Color(0xFFE8EEEA), borderRadius: BorderRadius.circular(6)))),
          ),
      ]),
    );
  }
}


// ============================================================== sign-in

/// "Continue with Apple / Google". iPhone shows Apple first (App Store
/// guideline 4.8 when Google is offered); Android shows Google only.
class TAuthButtons extends StatelessWidget {
  const TAuthButtons({super.key, required this.children});
  final List<TAuthButton> children;
  @override
  Widget build(BuildContext context) {
    final ios = defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS;
    final visible = children.where((b) => b.platforms.contains(ios ? 'ios' : 'android')).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: _gap(visible, 8));
  }
}

class TAuthButton extends StatelessWidget {
  const TAuthButton({super.key, required this.provider, required this.label, required this.onPressed, this.platforms = const ['ios', 'android']});
  final String provider;
  final String label;
  final VoidCallback onPressed;
  final List<String> platforms;
  @override
  Widget build(BuildContext context) {
    final apple = provider == 'apple';
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: apple ? Colors.black : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TRadius.control), side: BorderSide(color: apple ? Colors.black : TColors.line, width: 1.5)),
        child: InkWell(
          borderRadius: BorderRadius.circular(TRadius.control),
          onTap: onPressed,
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (apple)
                const Icon(Icons.apple, color: Colors.white, size: 22)
              else
                const Text('G', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19, color: Color(0xFF4285F4))),
              const SizedBox(width: 10),
              Flexible(child: Text(label, style: TText.button.copyWith(color: apple ? Colors.white : const Color(0xFF1F1F1F)))),
            ]),
          ),
        ),
      ),
    );
  }
}

// ============================================================== native views

/// A slot for a native platform view that Flutter cannot draw, such as the
/// iOS DeviceActivityReport minutes view or Apple's app picker.
///
/// The app registers a builder per [id] with [TNativeSlot.register] (for
/// example a `UiKitView` backed by the DeviceActivityReport extension). Where
/// nothing is registered for [id] — the dev gallery, tests, other platforms —
/// a labelled placeholder of the same height is shown, so layouts can be
/// reviewed without the native view.
class TNativeSlot extends StatelessWidget {
  const TNativeSlot({super.key, required this.id, required this.label, this.caption, this.platform = 'ios', this.height = 120});
  final String id;
  final String label;
  final String? caption;
  final String platform;
  final double height;

  static final Map<String, WidgetBuilder> _builders = <String, WidgetBuilder>{};

  /// Registers the platform view drawn for [id]. Call once at app startup.
  static void register(String id, WidgetBuilder builder) => _builders[id] = builder;

  @override
  Widget build(BuildContext context) {
    final builder = _builders[id];
    if (builder != null) {
      return Semantics(container: true, label: label, child: SizedBox(height: height, child: builder(context)));
    }
    return Semantics(
      container: true,
      label: '$label, native view placeholder',
      child: Container(
        constraints: BoxConstraints(minHeight: height),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TColors.mintTint,
          borderRadius: BorderRadius.circular(TRadius.card),
          border: Border.all(color: TColors.line, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TPill('NATIVE VIEW · ${platform.toUpperCase()}'),
            const SizedBox(height: 8),
            Text(label, style: TText.cardTitle),
            if (caption != null) ...[
              const SizedBox(height: 4),
              Text(caption!, style: TText.cardText),
            ],
          ],
        ),
      ),
    );
  }
}
