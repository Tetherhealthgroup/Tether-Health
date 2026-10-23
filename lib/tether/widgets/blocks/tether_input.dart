import 'package:flutter/material.dart';

import '../../data/design_bundle.dart';
import '../../state/tether_scope.dart';
import '../../theme/tether_tokens.dart';
import 'tether_card.dart';

/// `.inp` — a free-text field.
///
/// The shipped content prefills it with an example answer rather than a hint,
/// so it is editable text and not a placeholder. That is the right call for
/// the screen it appears on: "why does this matter to you?" is easier to
/// answer by editing a sentence than by facing an empty box.
///
/// The `plan_reasons` archetype notes that under-13 profiles have no free text
/// and must render chips only. That gate belongs to whatever knows the
/// person's age, which this widget does not; it is recorded here so the
/// requirement is visible at the place it would have to be enforced.
class TetherInput extends StatefulWidget {
  const TetherInput({
    required this.block,
    required this.index,
    required this.areaId,
    required this.screenId,
    super.key,
  });

  final InputBlock block;
  final int index;
  final String areaId;
  final String screenId;

  @override
  State<TetherInput> createState() => _TetherInputState();
}

class _TetherInputState extends State<TetherInput> {
  TextEditingController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Seeded here rather than in initState because the stored value lives in
    // the session, which is reached through an InheritedWidget.
    if (_controller != null) return;
    final stored = TetherScope.of(context).textValue(
      widget.areaId,
      widget.screenId,
      widget.index,
      widget.block.value,
    );
    _controller = TextEditingController(text: stored);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = TetherScope.of(context);

    return TetherCardShell(
      tone: CardTone.plain,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.block.title case final String text) ...[
            Text(text, style: TetherText.cardTitle),
            const SizedBox(height: 8),
          ],
          TextField(
            controller: _controller,
            minLines: 2,
            maxLines: 6,
            style: TetherText.cardBody.copyWith(color: TetherColors.ink),
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.all(10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide(color: TetherColors.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide(color: TetherColors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide(color: TetherColors.coral),
              ),
            ),
            onChanged: (value) => session.setText(
              widget.areaId,
              widget.screenId,
              widget.index,
              value,
            ),
          ),
        ],
      ),
    );
  }
}
