import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../models/program_template.dart';
import '../widgets/unplug_kit.dart';
import '../widgets/unplug_scope.dart';

/// Screen L — the three program templates from addendum §4.2.
///
/// Applying a template is not cosmetic: it sets the delivery track, clamps the
/// tier range every other screen may use, and decides whether there is a
/// journal at all. Authoring new templates is Phase 4 work; these three are
/// fixed for now, which is why this screen offers no editor.
class UnplugScreenL extends StatelessWidget {
  const UnplugScreenL({required this.nav, super.key});

  final UnplugNavigation nav;

  @override
  Widget build(BuildContext context) {
    final state = UnplugScope.of(context);
    final applied = state.template;

    return UnplugPage(
      nav: nav,
      children: [
        if (applied != null)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: UnplugCard(
              color: AppColors.mint,
              borderColor: AppColors.mintStrong,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${applied.name} is applied',
                          style: const TextStyle(
                            color: AppColors.deepTeal,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Screen F is clamped to ${applied.tierRange.toLowerCase()} '
                          'and screen K shows the ${applied.track.label.toLowerCase()} '
                          'column.',
                          style: const TextStyle(
                            color: AppColors.tealSecondary,
                            fontSize: 12.5,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: state.clearTemplate,
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
          ),
        for (final template in programTemplates)
          _TemplateCard(
            template: template,
            applied: applied?.name == template.name,
            onApply: () => state.applyTemplate(template),
          ),
        const UnplugNote(
          text: 'Modules the addendum names are labelled. The rest are shown '
              'by identifier, because their definitions live in the v2 spec '
              'and inventing names for them here would put two different '
              'vocabularies into the same product.',
        ),
        const UnplugNote(
          text: 'Authoring new templates is Phase 4, alongside the physical '
              'key and cross-device support. These three are fixed for now.',
        ),
      ],
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.applied,
    required this.onApply,
  });

  final ProgramTemplate template;
  final bool applied;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: UnplugCard(
        borderColor: applied ? AppColors.deepTeal : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    template.name,
                    style: const TextStyle(
                      color: AppColors.deepTeal,
                      fontSize: 16.5,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                UnplugPill(label: template.track.label),
              ],
            ),
            const SizedBox(height: 12),
            UnplugFact(label: 'Tiers', value: template.tierRange),
            UnplugFact(label: 'Limits', value: template.limitControl.label),
            UnplugFact(label: 'Journal', value: template.journal.label),
            UnplugFact(label: 'Length', value: '${template.weeks} weeks'),
            if (template.assessment != null)
              UnplugFact(label: 'Assessment', value: template.assessment!),
            UnplugFact(
              label: 'Human review',
              value: template.humanReview
                  ? 'Yes — ${template.track.label.toLowerCase()}'
                  : 'None. Escalation is automatic on evidence.',
              emphasis: !template.humanReview,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final module in template.modules)
                  UnplugPill(
                    label: module.isUnnamed
                        ? module.id
                        : '${module.id} · ${module.name}',
                    background: module.isUnnamed
                        ? AppColors.cream
                        : AppColors.mint,
                    foreground: module.isUnnamed
                        ? AppColors.mutedTeal
                        : AppColors.deepTeal,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: applied
                  ? const FilledButton(
                      onPressed: null,
                      child: Text('Applied'),
                    )
                  : FilledButton.tonal(
                      onPressed: onApply,
                      child: const Text('Apply template'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
