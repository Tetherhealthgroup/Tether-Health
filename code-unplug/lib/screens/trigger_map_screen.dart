import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum SmokingTrigger {
  stress,
  afterMeals,
  driving,
  coffee,
  socialSettings,
  workBreaks,
  alcohol,
  boredom,
  morning,
  beforeBed,
}

class TriggerMapScreen extends StatelessWidget {
  const TriggerMapScreen({
    required this.isSpanish,
    required this.selectedTriggers,
    required this.customTrigger,
    required this.onSelectedTriggersChanged,
    required this.onCustomTriggerChanged,
    required this.onBack,
    required this.onContinue,
    super.key,
  });

  final bool isSpanish;
  final Set<SmokingTrigger> selectedTriggers;
  final String? customTrigger;
  final ValueChanged<Set<SmokingTrigger>> onSelectedTriggersChanged;
  final ValueChanged<String?> onCustomTriggerChanged;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  String _labelFor(SmokingTrigger trigger) {
    return switch (trigger) {
      SmokingTrigger.stress => isSpanish ? 'Estrés' : 'Stress',
      SmokingTrigger.afterMeals =>
        isSpanish ? 'Después de comer' : 'After meals',
      SmokingTrigger.driving => isSpanish ? 'Al conducir' : 'Driving',
      SmokingTrigger.coffee => isSpanish ? 'Con café' : 'With coffee',
      SmokingTrigger.socialSettings =>
        isSpanish ? 'Entornos sociales' : 'Social settings',
      SmokingTrigger.workBreaks =>
        isSpanish ? 'Descansos laborales' : 'Work breaks',
      SmokingTrigger.alcohol => isSpanish ? 'Alcohol' : 'Alcohol',
      SmokingTrigger.boredom => isSpanish ? 'Aburrimiento' : 'Boredom',
      SmokingTrigger.morning => isSpanish ? 'Por la mañana' : 'Morning',
      SmokingTrigger.beforeBed => isSpanish ? 'Antes de dormir' : 'Before bed',
    };
  }

  IconData _iconFor(SmokingTrigger trigger) {
    return switch (trigger) {
      SmokingTrigger.stress => Icons.bolt_rounded,
      SmokingTrigger.afterMeals => Icons.restaurant_rounded,
      SmokingTrigger.driving => Icons.directions_car_filled_rounded,
      SmokingTrigger.coffee => Icons.coffee_rounded,
      SmokingTrigger.socialSettings => Icons.groups_rounded,
      SmokingTrigger.workBreaks => Icons.work_rounded,
      SmokingTrigger.alcohol => Icons.wine_bar_rounded,
      SmokingTrigger.boredom => Icons.more_horiz_rounded,
      SmokingTrigger.morning => Icons.wb_sunny_outlined,
      SmokingTrigger.beforeBed => Icons.dark_mode_rounded,
    };
  }

  void _toggleTrigger(SmokingTrigger trigger) {
    final updated = Set<SmokingTrigger>.of(selectedTriggers);
    if (!updated.add(trigger)) {
      updated.remove(trigger);
    }
    onSelectedTriggersChanged(updated);
  }

  Future<void> _showCustomTriggerEditor(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.paper,
      builder: (sheetContext) => _CustomTriggerEditorSheet(
        isSpanish: isSpanish,
        initialValue: customTrigger ?? '',
        onSave: (value) {
          onCustomTriggerChanged(value);
          Navigator.of(sheetContext).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasCustomTrigger = customTrigger?.trim().isNotEmpty ?? false;
    final selectionCount = selectedTriggers.length + (hasCustomTrigger ? 1 : 0);
    final canContinue = selectionCount > 0;

    return Scaffold(
      key: const ValueKey('functional-trigger-map-screen'),
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: (details) {
            if ((details.primaryVelocity ?? 0) > 250) {
              onBack();
            }
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 380;
              final compact = constraints.maxHeight < 760;
              final horizontalPadding = narrow ? 18.0 : 24.0;

              return Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      compact ? 5 : 10,
                      horizontalPadding,
                      0,
                    ),
                    child: _TriggerHeader(
                      isSpanish: isSpanish,
                      onBack: onBack,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      compact ? 5 : 8,
                      horizontalPadding,
                      compact ? 7 : 10,
                    ),
                    child: _TriggerProgress(isSpanish: isSpanish),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      key: const ValueKey('trigger-content-scroll'),
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        compact ? 7 : 16,
                        horizontalPadding,
                        18,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isSpanish
                                    ? 'PREGUNTA 6 · ELIGE TODAS LAS QUE CORRESPONDAN'
                                    : 'QUESTION 6 · CHOOSE ALL THAT APPLY',
                                style: const TextStyle(
                                  color: AppColors.mutedTeal,
                                  fontSize: 11,
                                  height: 1.25,
                                  letterSpacing: 1.8,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                isSpanish
                                    ? '¿Cuándo es más probable que quieras fumar?'
                                    : 'When are you most likely to want a cigarette?',
                                style: Theme.of(context)
                                    .textTheme
                                    .displayLarge
                                    ?.copyWith(
                                      fontSize: narrow ? 30 : 34,
                                      height: 1.06,
                                    ),
                              ),
                              SizedBox(height: compact ? 9 : 13),
                              Text(
                                isSpanish
                                    ? 'Elige cada situación que sea cierta para ti.'
                                    : 'Choose every situation that feels true for you.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: AppColors.tealSecondary,
                                      fontSize: narrow ? 15 : 16,
                                      height: 1.35,
                                    ),
                              ),
                              SizedBox(height: compact ? 14 : 20),
                              LayoutBuilder(
                                builder: (context, gridConstraints) {
                                  const gap = 10.0;
                                  final itemWidth =
                                      (gridConstraints.maxWidth - gap) / 2;
                                  return Wrap(
                                    spacing: gap,
                                    runSpacing: gap,
                                    children: [
                                      for (final trigger
                                          in SmokingTrigger.values)
                                        SizedBox(
                                          width: itemWidth,
                                          child: _TriggerChoice(
                                            trigger: trigger,
                                            label: _labelFor(trigger),
                                            icon: _iconFor(trigger),
                                            selected: selectedTriggers
                                                .contains(trigger),
                                            onTap: () =>
                                                _toggleTrigger(trigger),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              _CustomTriggerCard(
                                isSpanish: isSpanish,
                                customTrigger: customTrigger,
                                onEdit: () => _showCustomTriggerEditor(context),
                                onRemove: () => onCustomTriggerChanged(null),
                              ),
                              const SizedBox(height: 12),
                              _TriggerPrivacyNote(isSpanish: isSpanish),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  _TriggerBottomAction(
                    isSpanish: isSpanish,
                    selectionCount: selectionCount,
                    canContinue: canContinue,
                    onContinue: onContinue,
                    horizontalPadding: horizontalPadding,
                    compact: compact,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CustomTriggerEditorSheet extends StatefulWidget {
  const _CustomTriggerEditorSheet({
    required this.isSpanish,
    required this.initialValue,
    required this.onSave,
  });

  final bool isSpanish;
  final String initialValue;
  final ValueChanged<String> onSave;

  @override
  State<_CustomTriggerEditorSheet> createState() =>
      _CustomTriggerEditorSheetState();
}

class _CustomTriggerEditorSheetState extends State<_CustomTriggerEditorSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final normalized = _controller.text.trim();
    if (normalized.isNotEmpty) {
      widget.onSave(normalized);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          4,
          24,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isSpanish
                  ? 'Añade tu desencadenante'
                  : 'Add your own trigger',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.deepTeal,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.isSpanish
                  ? 'Escribe una situación, emoción o rutina que te provoque ganas de fumar.'
                  : 'Enter a situation, feeling, or routine that makes you want to smoke.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.tealSecondary,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('trigger-custom-input'),
              controller: _controller,
              autofocus: true,
              maxLength: 50,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText:
                    widget.isSpanish ? 'Mi desencadenante' : 'My trigger',
                hintText: widget.isSpanish
                    ? 'Por ejemplo, llamadas'
                    : 'For example, phone calls',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (context, value, child) {
                  return FilledButton(
                    key: const ValueKey('trigger-custom-save'),
                    onPressed: value.text.trim().isEmpty ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.deepTeal,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      widget.isSpanish ? 'Guardar' : 'Save trigger',
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TriggerHeader extends StatelessWidget {
  const _TriggerHeader({required this.isSpanish, required this.onBack});

  final bool isSpanish;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          IconButton.outlined(
            key: const ValueKey('trigger-back'),
            tooltip: isSpanish ? 'Atrás' : 'Back',
            onPressed: onBack,
            style: IconButton.styleFrom(
              foregroundColor: AppColors.deepTeal,
              side: const BorderSide(color: AppColors.border),
            ),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Expanded(
            child: Text(
              isSpanish ? 'Tus desencadenantes' : 'Your triggers',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.deepTeal,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Text(
              '6 OF 8',
              style: TextStyle(
                color: AppColors.deepTeal,
                fontSize: 10,
                letterSpacing: .6,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TriggerProgress extends StatelessWidget {
  const _TriggerProgress({required this.isSpanish});

  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              isSpanish ? 'EVALUACIÓN' : 'ASSESSMENT',
              style: const TextStyle(
                color: AppColors.mutedTeal,
                fontSize: 10,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            const Text(
              '75%',
              style: TextStyle(
                color: AppColors.mutedTeal,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: const LinearProgressIndicator(
            key: ValueKey('trigger-progress'),
            value: .75,
            minHeight: 6,
            backgroundColor: Color(0xFFDCE7E1),
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.coral),
          ),
        ),
      ],
    );
  }
}

class _TriggerChoice extends StatelessWidget {
  const _TriggerChoice({
    required this.trigger,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final SmokingTrigger trigger;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: Material(
        color: selected ? AppColors.coralLight : AppColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? AppColors.coral : AppColors.border,
            width: selected ? 1.7 : 1,
          ),
        ),
        child: InkWell(
          key: ValueKey('trigger-choice-${trigger.name}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 68),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              child: Stack(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: selected ? AppColors.coral : AppColors.mint,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          color: selected ? Colors.white : AppColors.deepTeal,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.deepTeal,
                            fontSize: 13.5,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (selected)
                    Positioned(
                      key: ValueKey('trigger-selected-${trigger.name}'),
                      top: 0,
                      right: 0,
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.coral,
                        size: 17,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomTriggerCard extends StatelessWidget {
  const _CustomTriggerCard({
    required this.isSpanish,
    required this.customTrigger,
    required this.onEdit,
    required this.onRemove,
  });

  final bool isSpanish;
  final String? customTrigger;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final hasValue = customTrigger?.trim().isNotEmpty ?? false;
    return Material(
      color: hasValue ? AppColors.coralLight : AppColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: hasValue ? AppColors.coral : AppColors.border,
          width: hasValue ? 1.7 : 1,
        ),
      ),
      child: InkWell(
        key: const ValueKey('trigger-add-own'),
        onTap: onEdit,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(13, 11, 11, 11),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: AppColors.mint,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasValue ? Icons.edit_rounded : Icons.add_rounded,
                  color: AppColors.deepTeal,
                  size: 22,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasValue
                          ? (isSpanish ? 'TU DESENCADENANTE' : 'YOUR TRIGGER')
                          : (isSpanish
                              ? 'AÑADE TU DESENCADENANTE'
                              : 'ADD YOUR OWN TRIGGER'),
                      style: const TextStyle(
                        color: AppColors.mutedTeal,
                        fontSize: 10,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasValue
                          ? customTrigger!
                          : (isSpanish
                              ? 'Escribe otra situación…'
                              : 'Type another situation…'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.deepTeal,
                        fontSize: hasValue ? 13.5 : 12,
                        fontWeight:
                            hasValue ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasValue)
                IconButton(
                  key: const ValueKey('trigger-custom-remove'),
                  tooltip: isSpanish ? 'Eliminar' : 'Remove',
                  onPressed: onRemove,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.coral,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TriggerPrivacyNote extends StatelessWidget {
  const _TriggerPrivacyNote({required this.isSpanish});

  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('trigger-privacy-note'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.mintStrong),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: AppColors.paper,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.deepTeal,
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSpanish
                      ? 'Se usa para prepararte, no para vigilarte'
                      : 'Used to prepare, not to monitor',
                  style: const TextStyle(
                    color: AppColors.deepTeal,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isSpanish
                      ? 'Tus elecciones adaptan las herramientas y los recordatorios.'
                      : 'Your choices shape coping tools and reminder timing.',
                  style: const TextStyle(
                    color: AppColors.tealSecondary,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isSpanish
                      ? 'BreatheFree no rastrea tu ubicación en segundo plano.'
                      : 'BreatheFree does not track your location in the background.',
                  style: const TextStyle(
                    color: AppColors.mutedTeal,
                    fontSize: 10,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TriggerBottomAction extends StatelessWidget {
  const _TriggerBottomAction({
    required this.isSpanish,
    required this.selectionCount,
    required this.canContinue,
    required this.onContinue,
    required this.horizontalPadding,
    required this.compact,
  });

  final bool isSpanish;
  final int selectionCount;
  final bool canContinue;
  final VoidCallback onContinue;
  final double horizontalPadding;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final countLabel = isSpanish
        ? '$selectionCount ${selectionCount == 1 ? 'desencadenante elegido' : 'desencadenantes elegidos'} · Guardado automáticamente'
        : '$selectionCount ${selectionCount == 1 ? 'trigger selected' : 'triggers selected'} · Saved automatically';

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(top: BorderSide(color: Color(0x1A123C37))),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          compact ? 8 : 11,
          horizontalPadding,
          compact ? 8 : 11,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: compact ? 50 : 54,
                  child: FilledButton(
                    key: const ValueKey('trigger-continue'),
                    onPressed: canContinue ? onContinue : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.deepTeal,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.border,
                      disabledForegroundColor: AppColors.tealSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isSpanish ? 'Continuar' : 'Continue',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: canContinue
                              ? AppColors.lime
                              : AppColors.mutedTeal,
                        ),
                      ],
                    ),
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 7),
                  Text(
                    countLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.mutedTeal,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
