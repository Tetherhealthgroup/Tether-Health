// Tether Health UI kit — components.
//
// One widget per node type in spec/screens.json. Generated screens only use
// these widgets, so visual changes happen here, once. Interactive controls
// (chips, segmented, radio, toggles, checklists, zone) keep their own local
// selection state and expose onChanged for wiring to real data.
import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart';

import '../logic/rules.dart';
import 'nav.dart';
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
class TScreen extends StatelessWidget {
  const TScreen({super.key, this.header, this.children = const [], this.footer = const [], this.tab, this.background = TBackground.paper});
  final THeader? header;
  final List<Widget> children;
  final List<Widget> footer;
  final String? tab;
  final TBackground background;

  bool get dark => background != TBackground.paper;

  @override
  Widget build(BuildContext context) {
    final decoration = switch (background) {
      TBackground.paper => const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFBF8F0), Color(0xFFF3F0E6)])),
      TBackground.dark => const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [TColors.teal, Color(0xFF1C5149)])),
      TBackground.indigo => const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1F2A6B), Color(0xFF3B4CC0)])),
    };
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
                if (header != null) _Header(spec: header!, dark: dark),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(TSpace.screen, 6, TSpace.screen, 20),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: _gap(children)),
                  ),
                ),
                if (footer.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(TSpace.screen, 10, TSpace.screen, 12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: _gap(footer, 8)),
                  ),
                if (tab != null) TTabBar(active: tab!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom-sheet content. Shown by TNav.sheet through a ModalBottomSheetRoute.
class TSheet extends StatelessWidget {
  const TSheet({super.key, this.children = const [], this.footer = const []});
  final List<Widget> children;
  final List<Widget> footer;

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * 0.86;
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
              Center(child: Container(width: 40, height: 5, margin: const EdgeInsets.fromLTRB(0, 9, 0, 6), decoration: BoxDecoration(color: TColors.line, borderRadius: BorderRadius.circular(3)))),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(TSpace.screen, 6, TSpace.screen, 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: _gap(children)),
                ),
              ),
              if (footer.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(TSpace.screen, 8, TSpace.screen, 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: _gap(footer, 8)),
                ),
            ],
          ),
        ),
      ),
    );
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
        left = Row(children: [const TLogoMark(), const SizedBox(width: 10), Text(spec.title, style: TText.headerTitle.copyWith(fontSize: 20, fontWeight: FontWeight.w800, color: fg))]);
      case THeaderLeft.none:
        left = Padding(padding: const EdgeInsets.only(left: 4), child: Text(spec.title, style: TText.largeTitle.copyWith(color: fg)));
      case THeaderLeft.back:
      case THeaderLeft.close:
        final isBack = spec.left == THeaderLeft.back;
        left = _CircleButton(
          key: const ValueKey('a:header.left'),
          label: isBack ? 'Back' : 'Close',
          icon: isBack ? Icons.chevron_left_rounded : Icons.close_rounded,
          dark: dark,
          onTap: () => isBack ? TNav.back(context) : TNav.close(context),
        );
        middle = Expanded(child: Text(spec.title, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TText.headerTitle.copyWith(color: fg)));
    }
    final right = <Widget>[
      if (spec.pill != null) TPill(spec.pill!),
      if (spec.avatar != null) ...[const SizedBox(width: 8), TAvatar(spec.avatar!, key: const ValueKey('a:header.avatar'), onTap: spec.onAvatar, semanticLabel: 'Account')],
    ];
    final isNav = spec.left == THeaderLeft.back || spec.left == THeaderLeft.close;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: SizedBox(
        height: 52,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            if (isNav) ...[left, const SizedBox(width: 8), middle] else Expanded(child: Align(alignment: Alignment.centerLeft, child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: left))),
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

class TLogoMark extends StatelessWidget {
  const TLogoMark({super.key});
  @override
  Widget build(BuildContext context) => Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(color: TColors.teal, shape: BoxShape.circle),
        child: const Icon(Icons.eco_rounded, size: 18, color: TColors.lime),
      );
}

class TTabBar extends StatelessWidget {
  const TTabBar({super.key, required this.active});
  final String active;
  static const _tabs = <(String, String, IconData)>[
    ('today', 'Today', Icons.home_outlined),
    ('plans', 'Plans', Icons.list_alt_rounded),
    ('progress', 'Progress', Icons.bar_chart_rounded),
    ('learn', 'Learn', Icons.menu_book_outlined),
    ('support', 'Support', Icons.favorite_border_rounded),
  ];
  @override
  Widget build(BuildContext context) {
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
                    selected: t.$1 == active,
                    button: true,
                    label: '${t.$2} tab',
                    child: InkWell(
                      key: ValueKey('a:tabbar.${t.$1}'),
                      onTap: t.$1 == active ? null : () => TNav.tab(context, TNav.tabRoute(t.$1)),
                      child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          width: 48,
                          height: 28,
                          decoration: BoxDecoration(color: t.$1 == active ? TColors.mint : Colors.transparent, borderRadius: BorderRadius.circular(14)),
                          child: Icon(t.$3, size: 21, color: t.$1 == active ? TColors.teal : TColors.muted),
                        ),
                        const SizedBox(height: 2),
                        Text(t.$2, maxLines: 1, overflow: TextOverflow.ellipsis, style: TText.tab.copyWith(color: t.$1 == active ? TColors.teal : TColors.muted, fontWeight: t.$1 == active ? FontWeight.w800 : FontWeight.w600)),
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
  const TProgramTag({super.key, required this.program, this.extra});
  final String program;
  final String? extra;
  static const names = {'bf': 'BreatheFree', 'sf': 'ScrollFree', 'ca': 'ClearAir', 'hw': 'Heartwise', 'st': 'Steady', 're': 'Renew', 'nu': 'Nourish', 'sd': 'Stride', 'ea': 'Ease', 'ck': 'Checkup', 'be': 'Beacon'};
  @override
  Widget build(BuildContext context) {
    final c = TDark.of(context) ? Color.lerp(TColors.program(program), Colors.white, 0.55)! : TColors.program(program);
    final text = (names[program] ?? program) + (extra != null ? ' · $extra' : '');
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 9, height: 9, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 6),
      Flexible(child: Text(text.toUpperCase(), style: TText.tag.copyWith(color: c))),
    ]);
  }
}

class TSteps extends StatelessWidget {
  const TSteps({super.key, required this.n, required this.total});
  final int n;
  final int total;
  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Step $n of $total',
        child: Row(children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(child: Container(height: 5, decoration: BoxDecoration(color: i < n ? TColors.teal : TColors.line2, borderRadius: BorderRadius.circular(3)))),
          ]
        ]),
      );
}

// ============================================================== inputs

class TChips extends StatefulWidget {
  const TChips({super.key, required this.options, this.selected = const [], this.multi = true, this.dots = const {}, this.label, this.onChanged, this.fieldKey});
  final String? fieldKey;
  final List<String> options;
  final List<String> selected;
  final bool multi;
  final Map<String, Color> dots;
  final String? label;
  final ValueChanged<Set<String>>? onChanged;
  @override
  State<TChips> createState() => _TChipsState();
}

class _TChipsState extends State<TChips> {
  late final Set<String> _sel = {...widget.selected};
  @override
  void initState() {
    super.initState();
    TSession.set(widget.fieldKey, _sel.toList());
  }

  void _tap(String o) {
    setState(() {
      if (widget.multi) {
        _sel.contains(o) ? _sel.remove(o) : _sel.add(o);
      } else {
        _sel
          ..clear()
          ..add(o);
      }
    });
    TSession.set(widget.fieldKey, _sel.toList());
    widget.onChanged?.call(_sel);
  }

  @override
  Widget build(BuildContext context) {
    final dark = TDark.of(context);
    return _labelled(
      widget.label,
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final o in widget.options)
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
                  Flexible(child: Text(o, style: TText.chip.copyWith(color: dark ? Colors.white : null))),
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}

class TSegmented extends StatefulWidget {
  const TSegmented({super.key, required this.options, required this.selected, this.label, this.onChanged, this.fieldKey});
  final String? fieldKey;
  final List<String> options;
  final String selected;
  final String? label;
  final ValueChanged<String>? onChanged;
  @override
  State<TSegmented> createState() => _TSegmentedState();
}

class _TSegmentedState extends State<TSegmented> {
  late String _sel = widget.selected;
  @override
  void initState() {
    super.initState();
    TSession.set(widget.fieldKey, _sel);
  }

  @override
  Widget build(BuildContext context) => _labelled(
        widget.label,
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(color: TColors.segBg, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            for (final o in widget.options)
              Expanded(
                child: Semantics(
                  selected: o == _sel,
                  button: true,
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _sel = o);
                      TSession.set(widget.fieldKey, o);
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
                      child: Text(o, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TText.chip.copyWith(fontSize: 13.5, color: o == _sel ? TColors.teal : TColors.teal2)),
                    ),
                  ),
                ),
              ),
          ]),
        ),
      );
}

class TRadioItem {
  const TRadioItem(this.label, {this.sub, this.badge});
  final String label;
  final String? sub;
  final String? badge;
}

class TRadioList extends StatefulWidget {
  const TRadioList({super.key, required this.items, this.selected = 0, this.label, this.onChanged, this.fieldKey});
  final String? fieldKey;
  final List<TRadioItem> items;
  final int selected;
  final String? label;
  final ValueChanged<int>? onChanged;
  @override
  State<TRadioList> createState() => _TRadioListState();
}

class _TRadioListState extends State<TRadioList> {
  late int _sel = widget.selected;
  @override
  void initState() {
    super.initState();
    _store();
  }

  void _store() => TSession.set(widget.fieldKey, _sel >= 0 && _sel < widget.items.length ? widget.items[_sel].label : null);

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
                  setState(() => _sel = i);
                  _store();
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
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(widget.items[i].label, style: TText.optionLabel),
                        if (widget.items[i].sub != null) Text(widget.items[i].sub!, style: TText.sub),
                      ]),
                    ),
                    if (widget.items[i].badge != null) ...[const SizedBox(width: 8), TPill(widget.items[i].badge!)],
                  ]),
                ),
              ),
            ),
          ]
        ]),
      );
}

class TCheckItem {
  const TCheckItem(this.label, {this.sub, this.done = false});
  final String label;
  final String? sub;
  final bool done;
}

class TChecklist extends StatefulWidget {
  const TChecklist({super.key, required this.items, this.label, this.onChanged, this.fieldKey});
  final List<TCheckItem> items;
  final String? label;
  final void Function(int index, bool done)? onChanged;

  /// Session key. When set, the labels of the ticked items are written to
  /// [TSession] (consent checklists).
  final String? fieldKey;
  @override
  State<TChecklist> createState() => _TChecklistState();
}

class _TChecklistState extends State<TChecklist> {
  late final List<bool> _done = [for (final i in widget.items) i.done];
  void _store() => TSession.set(widget.fieldKey, [
        for (var i = 0; i < widget.items.length; i++)
          if (_done[i]) widget.items[i].label
      ]);

  @override
  void initState() {
    super.initState();
    _store();
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
                  setState(() => _done[i] = !_done[i]);
                  _store();
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
  const TToggleRow({super.key, required this.label, this.sub, this.value = false, this.onChanged, this.fieldKey});
  final String? fieldKey;
  final String label;
  final String? sub;
  final bool value;
  final ValueChanged<bool>? onChanged;
  @override
  State<TToggleRow> createState() => _TToggleRowState();
}

class _TToggleRowState extends State<TToggleRow> {
  late bool _on = widget.value;
  @override
  void initState() {
    super.initState();
    TSession.set(widget.fieldKey, _on);
  }

  @override
  Widget build(BuildContext context) => MergeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
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
                setState(() => _on = v);
                TSession.set(widget.fieldKey, v);
                widget.onChanged?.call(v);
              },
            ),
          ]),
        ),
      );
}

enum TFieldKind { text, number, email, password, phone, date, select, multiline, search }

class TField extends StatefulWidget {
  const TField({super.key, required this.label, this.value, this.unit, this.hint, this.error, this.placeholder, this.kind = TFieldKind.text, this.onChanged, this.fieldKey});
  final String label;
  final String? value;
  final String? unit;
  final String? hint;
  final String? error;
  final String? placeholder;
  final TFieldKind kind;
  final ValueChanged<String>? onChanged;
  final String? fieldKey;

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

  @override
  void initState() {
    super.initState();
    TSession.set(widget.fieldKey, widget.value);
    TSession.changes.addListener(_onSessionChange);
  }

  @override
  void dispose() {
    TSession.changes.removeListener(_onSessionChange);
    _controller.dispose();
    super.dispose();
  }

  void _onSessionChange() {
    final key = widget.fieldKey;
    if (key == null || TSession.values.containsKey(key) || (_controller.text.isEmpty && !_hadKey)) return;
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

  void onChanged(String v) {
    _hadKey = widget.fieldKey != null;
    TSession.set(widget.fieldKey, v.isEmpty ? null : v);
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
                      ? Padding(padding: const EdgeInsets.only(left: 8, right: 18, top: 2.67), child: Text(unit!, style: unitStyle, textScaler: unitScaler))
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
    TSession.set(widget.fieldKey, _v);
  }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text(widget.label, style: TText.label)),
          Text('${_v.round()}${widget.suffix}', style: TText.titleM.copyWith(fontSize: 22)),
        ]),
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
              widget.onChanged?.call(v);
            },
          ),
        ),
        Row(children: [Text(widget.minLabel ?? '${widget.min.round()}', style: TText.small), const Spacer(), Text(widget.maxLabel ?? '${widget.max.round()}', style: TText.small)]),
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

  static const _z = <(String, String, Color, Color)>[
    ('green', 'Green', TColors.okFill, TColors.okText),
    ('yellow', 'Yellow', TColors.warnFill, TColors.warnText),
    ('red', 'Red', TColors.errorFill, TColors.errorText),
  ];
  @override
  Widget build(BuildContext context) => Row(children: [
        for (var i = 0; i < _z.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              selected: _sel == _z[i].$1,
              button: true,
              label: '${_z[i].$2} zone',
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
                  decoration: BoxDecoration(color: _z[i].$3, borderRadius: BorderRadius.circular(12), border: Border.all(width: 2, color: _sel == _z[i].$1 ? TColors.teal : Colors.transparent)),
                  child: Text(_z[i].$2, style: TText.optionLabel.copyWith(color: _z[i].$4, fontWeight: FontWeight.w800)),
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
    final (bg, fg, dot, icon) = switch (kind) {
      TBannerKind.offline => (TColors.warnFill, TColors.warnText, TColors.warn, Icons.cloud_off_rounded),
      TBannerKind.error => (TColors.errorFill, TColors.errorText, TColors.error, Icons.error_outline_rounded),
      TBannerKind.success => (TColors.okFill, TColors.okText, TColors.ok, Icons.check_rounded),
      TBannerKind.info => (const Color(0xFFEAF1EC), TColors.teal, TColors.teal, Icons.info_outline_rounded),
      TBannerKind.urgent => (TColors.error, Colors.white, Colors.white, Icons.priority_high_rounded),
    };
    return Semantics(
      liveRegion: kind == TBannerKind.error || kind == TBannerKind.urgent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 20, color: dot),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TText.label.copyWith(color: fg, fontWeight: FontWeight.w600, height: 1.4))),
          if (actionLabel != null) TextButton(key: actionKey, onPressed: onAction, child: Text(actionLabel!, style: TText.label.copyWith(color: fg, decoration: TextDecoration.underline))),
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
      if (tag != null) ...[Align(alignment: Alignment.centerLeft, child: TProgramTag(program: tag!, extra: tagExtra)), const SizedBox(height: 6)],
      if (eyebrow != null) ...[TEyebrow(eyebrow!), const SizedBox(height: 4)],
      if (title != null) Text(title!, style: TText.cardTitle.copyWith(color: titleColor)),
      if (text != null) ...[const SizedBox(height: 3), Text(text!, style: TText.cardText.copyWith(color: textColor))],
      for (final c in children) ...[const SizedBox(height: 8), c],
    ]);
    Widget body = content;
    if (cta != null || onTap != null) {
      body = Row(children: [
        Expanded(child: content),
        const SizedBox(width: 12),
        if (cta != null) Flexible(child: cta!) else Icon(Icons.chevron_right_rounded, size: 26, color: dark ? TColors.onDarkMuted : TColors.muted),
      ]);
    }
    final card = Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
            child: Stack(children: [card, Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 4, color: TColors.program(accent!)))]),
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
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Text(rows[i].$1, style: TText.cardText.copyWith(fontSize: 14))),
              const SizedBox(width: 16),
              Flexible(child: Text(rows[i].$2, textAlign: TextAlign.right, style: TText.cardText.copyWith(fontSize: 14, color: TColors.teal, fontWeight: FontWeight.w700))),
            ]),
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
    final row = Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(children: [
        if (lead?.program != null) ...[TProgramBadge(lead!.program!), const SizedBox(width: 12)],
        if (lead?.avatar != null) ...[TAvatar(lead!.avatar!), const SizedBox(width: 12)],
        if (lead?.icon != null) ...[TAvatar(lead!.icon!, icon: true), const SizedBox(width: 12)],
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TText.optionLabel.copyWith(color: danger ? TColors.error : null)),
            if (sub != null) Text(sub!, style: TText.sub),
          ]),
        ),
        if (value != null) ...[const SizedBox(width: 8), Text(value!, style: TText.sub.copyWith(color: TColors.teal, fontWeight: FontWeight.w700))],
        if (pill != null) ...[const SizedBox(width: 8), TPill(pill!)],
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
  const TTile({required this.label, this.sub, this.program, this.glyph, this.color, this.selected = false, this.onTap, this.key});
  final Key? key;
  final String label;
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
  void _store() => TSession.set(widget.fieldKey, [
        for (var i = 0; i < widget.tiles.length; i++)
          if (_sel[i] && widget.tiles[i].onTap == null) widget.tiles[i].label
      ]);

  @override
  void initState() {
    super.initState();
    _store();
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
            if (on) const Positioned(top: 0, right: 0, child: CircleAvatar(radius: 11, backgroundColor: TColors.teal, child: Icon(Icons.check_rounded, size: 14, color: TColors.lime))),
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
          if (s.program != null) TProgramTag(program: s.program!, extra: s.label) else TEyebrow(s.label),
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
  Widget build(BuildContext context) => TCard(onTap: onTap, children: [
        Row(children: [
          if (tag != null) ...[TProgramTag(program: tag!), const SizedBox(width: 8)],
          Expanded(child: Text(title ?? '', style: TText.label)),
          if (unit != null) Flexible(child: Text(unit!, textAlign: TextAlign.right, style: TText.sub)),
        ]),
        chart,
        if (caption != null) Text(caption!, style: TText.cardText),
      ]);
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
        label: '${title ?? 'Chart'}: ${[for (var i = 0; i < values.length; i++) missing.contains(i) ? 'no entry' : values[i].round().toString()].join(', ')}',
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
              if (target != null) Positioned(left: 0, right: 0, bottom: target! / maxV * 96, child: Container(height: 2, color: TColors.teal)),
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
          label: '${title ?? 'Chart'}: ${values.map((v) => v.round()).join(', ')}',
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
  const TBreathRing({super.key, required this.value, this.label = 'SECONDS', this.palette = TRingPalette.teal});
  final String value;
  final String label;
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
    final cols = widget.palette == TRingPalette.teal ? const [Color(0xFF2B6258), Color(0xFF1C5149), Color(0xFF174640)] : const [Color(0xFF5566D8), Color(0xFF4656C9), Color(0xFF3A49B5)];
    return Center(
      child: Semantics(
        label: '${widget.value} ${widget.label.toLowerCase()}',
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
                    Text(widget.label, style: const TextStyle(color: Colors.white, fontSize: 11, letterSpacing: 1.3)),
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
        Flexible(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, maxLines: 1, style: TText.big.copyWith(color: dark ? Colors.white : null)))),
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
        label: '$value $label',
        child: Column(children: [
          Text(value, style: TText.big.copyWith(fontSize: 56, fontFeatures: const [FontFeature.tabularFigures()])),
          Text(label, style: TText.small),
        ]),
      );
}

class TCalendar extends StatelessWidget {
  const TCalendar({super.key, required this.month, required this.selected, required this.window, this.today, this.firstWeekday = 6, this.days = 31});
  final String month;
  final int selected;
  final List<int> window;
  final int? today;
  final int firstWeekday; // 0 = Sunday
  final int days;
  @override
  Widget build(BuildContext context) {
    final cells = <Widget>[
      for (final d in const ['S', 'M', 'T', 'W', 'T', 'F', 'S']) Center(child: Text(d, style: TText.eyebrow)),
      for (var i = 0; i < firstWeekday; i++) const SizedBox(),
      for (var d = 1; d <= days; d++)
        Semantics(
          selected: d == selected,
          button: true,
          label: '$month $d',
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
    return TCard(children: [
      Row(children: [Expanded(child: Text(month, style: TText.label)), const Icon(Icons.chevron_left_rounded, color: TColors.muted), const Icon(Icons.chevron_right_rounded, color: TColors.muted)]),
      GridView.count(crossAxisCount: 7, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 4, crossAxisSpacing: 4, childAspectRatio: 1.2, children: cells),
    ]);
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
            alignment: arrow ? Alignment.centerLeft : Alignment.center,
            child: child,
          ),
        ),
      ),
    );
  }
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
  Widget build(BuildContext context) => Align(
        alignment: alignLeft ? Alignment.centerLeft : Alignment.center,
        child: Semantics(
          link: true,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              child: Text(label, textAlign: TextAlign.center, style: TText.label.copyWith(fontSize: 15, color: TDark.of(context) ? Colors.white : TColors.teal, decoration: TextDecoration.underline)),
            ),
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
        Text('“$text”', style: TText.quote),
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
        label: 'Emergency help',
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
      label: 'Loading',
      child: TCard(children: [
        for (var i = 0; i < widget.lines.clamp(1, 4); i++)
          FadeTransition(
            opacity: Tween(begin: 0.45, end: 1.0).animate(_c),
            child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: widths[i], child: Container(height: 12, decoration: BoxDecoration(color: const Color(0xFFE8EEEA), borderRadius: BorderRadius.circular(6)))),
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
