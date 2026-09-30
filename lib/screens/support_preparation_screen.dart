import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum SupportChannel { text, call }

enum PreparationTask { removeSupplies, smokeFreeSpaces, stockAlternatives }

@immutable
class SupportPersonPlan {
  const SupportPersonPlan({
    required this.id,
    required this.name,
    required this.relationship,
    required this.channel,
    required this.checkIn,
    this.enabled = true,
  });

  final String id;
  final String name;
  final String relationship;
  final SupportChannel channel;
  final String checkIn;
  final bool enabled;

  SupportPersonPlan copyWith({
    String? name,
    String? relationship,
    SupportChannel? channel,
    String? checkIn,
    bool? enabled,
  }) {
    return SupportPersonPlan(
      id: id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      channel: channel ?? this.channel,
      checkIn: checkIn ?? this.checkIn,
      enabled: enabled ?? this.enabled,
    );
  }
}

class SupportPreparationScreen extends StatelessWidget {
  const SupportPreparationScreen({
    required this.isSpanish,
    required this.supportPeople,
    required this.completedTasks,
    required this.treatmentSupport,
    required this.careTeamReminder,
    required this.onSupportPeopleChanged,
    required this.onCompletedTasksChanged,
    required this.onTreatmentSupportChanged,
    required this.onCareTeamReminderChanged,
    required this.onBack,
    required this.onContinue,
    super.key,
  });

  final bool isSpanish;
  final List<SupportPersonPlan> supportPeople;
  final Set<PreparationTask> completedTasks;
  final bool treatmentSupport;
  final bool careTeamReminder;
  final ValueChanged<List<SupportPersonPlan>> onSupportPeopleChanged;
  final ValueChanged<Set<PreparationTask>> onCompletedTasksChanged;
  final ValueChanged<bool> onTreatmentSupportChanged;
  final ValueChanged<bool> onCareTeamReminderChanged;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  int get _activeSupporters =>
      supportPeople.where((person) => person.enabled).length;

  String _supporterCountLabel() {
    final count = _activeSupporters;
    if (isSpanish) {
      return count == 1 ? '1 PERSONA AGREGADA' : '$count PERSONAS AGREGADAS';
    }
    return count == 1 ? '1 PERSON ADDED' : '$count PEOPLE ADDED';
  }

  String _channelLabel(SupportChannel channel) {
    return switch (channel) {
      SupportChannel.text => isSpanish ? 'Mensaje de texto' : 'Text message',
      SupportChannel.call => isSpanish ? 'Llamada' : 'Phone call',
    };
  }

  String _relationshipLabel(SupportPersonPlan person) {
    if (isSpanish && person.id == 'jordan' && person.relationship == 'Friend') {
      return 'Amigo';
    }
    return person.relationship;
  }

  String _checkInLabel(SupportPersonPlan person) {
    if (isSpanish &&
        person.id == 'jordan' &&
        person.checkIn == 'Check in the evening before my quit date') {
      return 'Contactarme la noche antes de mi fecha para dejarlo';
    }
    return person.checkIn;
  }

  String _taskLabel(PreparationTask task) {
    return switch (task) {
      PreparationTask.removeSupplies => isSpanish
          ? 'Retirar cigarrillos, encendedores y ceniceros'
          : 'Remove cigarettes, lighters and ashtrays',
      PreparationTask.smokeFreeSpaces => isSpanish
          ? 'Hacer que mi casa y auto estén libres de humo'
          : 'Make my home and car smoke-free',
      PreparationTask.stockAlternatives => isSpanish
          ? 'Tener chicle, agua o refrigerios saludables'
          : 'Stock gum, water or healthy snacks',
    };
  }

  void _togglePerson(SupportPersonPlan person, bool enabled) {
    onSupportPeopleChanged([
      for (final item in supportPeople)
        if (item.id == person.id) item.copyWith(enabled: enabled) else item,
    ]);
  }

  void _savePerson(SupportPersonPlan person) {
    final existingIndex =
        supportPeople.indexWhere((item) => item.id == person.id);
    if (existingIndex < 0) {
      if (supportPeople.length >= 10) return;
      onSupportPeopleChanged([...supportPeople, person]);
      return;
    }
    onSupportPeopleChanged([
      for (final item in supportPeople)
        if (item.id == person.id) person else item,
    ]);
  }

  void _removePerson(String id) {
    onSupportPeopleChanged(
      supportPeople.where((person) => person.id != id).toList(),
    );
  }

  void _toggleTask(PreparationTask task) {
    final updated = Set<PreparationTask>.of(completedTasks);
    if (!updated.add(task)) updated.remove(task);
    onCompletedTasksChanged(updated);
  }

  Future<void> _openPersonEditor(
    BuildContext context, {
    SupportPersonPlan? person,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.paper,
      builder: (sheetContext) => _SupportPersonEditor(
        isSpanish: isSpanish,
        person: person,
        onSave: (savedPerson) {
          _savePerson(savedPerson);
          Navigator.of(sheetContext).pop();
        },
        onRemove: person == null
            ? null
            : () {
                _removePerson(person.id);
                Navigator.of(sheetContext).pop();
              },
      ),
    );
  }

  Future<void> _openTreatmentEducation(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.paper,
      builder: (sheetContext) => _TreatmentEducationSheet(
        isSpanish: isSpanish,
        onDone: () => Navigator.of(sheetContext).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('functional-support-preparation-screen'),
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: (details) {
            if ((details.primaryVelocity ?? 0) > 250) onBack();
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 380;
              final compact = constraints.maxHeight < 760;
              final horizontalPadding = narrow ? 18.0 : 22.0;

              return Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      compact ? 5 : 9,
                      horizontalPadding,
                      0,
                    ),
                    child: _SupportHeader(
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
                    child: _SupportProgress(isSpanish: isSpanish),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      key: const ValueKey('support-content-scroll'),
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        compact ? 8 : 13,
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
                                    ? 'PREPÁRATE PARA TENER ÉXITO'
                                    : 'SET UP FOR SUCCESS',
                                style: const TextStyle(
                                  color: AppColors.mutedTeal,
                                  fontSize: 11,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isSpanish
                                    ? 'No tienes que hacer esto a solas.'
                                    : 'You don’t have to do this alone.',
                                style: Theme.of(context)
                                    .textTheme
                                    .displayLarge
                                    ?.copyWith(
                                      fontSize: narrow ? 28 : 32,
                                      height: 1.07,
                                    ),
                              ),
                              const SizedBox(height: 9),
                              Text(
                                isSpanish
                                    ? 'Elige el apoyo que deseas. Tú controlas a quién se contacta y qué se comparte.'
                                    : 'Choose the support you want. You stay in control of who is contacted and what is shared.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      fontSize: narrow ? 14 : 15,
                                      height: 1.38,
                                    ),
                              ),
                              SizedBox(height: compact ? 15 : 20),
                              _SectionHeading(
                                title: isSpanish
                                    ? 'TU CÍRCULO DE APOYO'
                                    : 'YOUR SUPPORT CIRCLE',
                                trailing: _supporterCountLabel(),
                                trailingKey:
                                    const ValueKey('support-person-count'),
                              ),
                              const SizedBox(height: 10),
                              if (supportPeople.isEmpty)
                                _EmptySupportCard(isSpanish: isSpanish)
                              else
                                for (final person in supportPeople) ...[
                                  _SupportPersonCard(
                                    person: person,
                                    isSpanish: isSpanish,
                                    channelLabel: _channelLabel(person.channel),
                                    relationshipLabel:
                                        _relationshipLabel(person),
                                    checkInLabel: _checkInLabel(person),
                                    onEnabledChanged: (value) =>
                                        _togglePerson(person, value),
                                    onEdit: () => _openPersonEditor(
                                      context,
                                      person: person,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              _AddSupporterCard(
                                isSpanish: isSpanish,
                                onTap: supportPeople.length >= 10
                                    ? null
                                    : () => _openPersonEditor(context),
                              ),
                              SizedBox(height: compact ? 18 : 23),
                              _SectionHeading(
                                title: isSpanish
                                    ? 'PREPARA TU ESPACIO'
                                    : 'PREPARE YOUR SPACE',
                                trailing:
                                    '${completedTasks.length} ${isSpanish ? 'DE' : 'OF'} 3',
                                trailingKey:
                                    const ValueKey('preparation-task-count'),
                              ),
                              const SizedBox(height: 10),
                              _PreparationChecklist(
                                completedTasks: completedTasks,
                                taskLabel: _taskLabel,
                                onToggle: _toggleTask,
                              ),
                              SizedBox(height: compact ? 18 : 23),
                              Text(
                                isSpanish
                                    ? 'APOYO PARA EL TRATAMIENTO'
                                    : 'TREATMENT SUPPORT',
                                style: const TextStyle(
                                  color: AppColors.mutedTeal,
                                  fontSize: 10.5,
                                  letterSpacing: 1.8,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _TreatmentSupportCard(
                                isSpanish: isSpanish,
                                enabled: treatmentSupport,
                                careTeamReminder: careTeamReminder,
                                onEnabledChanged: onTreatmentSupportChanged,
                                onCareTeamReminderChanged:
                                    onCareTeamReminderChanged,
                                onLearn: () => _openTreatmentEducation(context),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 15,
                                    backgroundColor: AppColors.mint,
                                    child: Icon(
                                      Icons.check_rounded,
                                      size: 18,
                                      color: AppColors.deepTeal,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      isSpanish
                                          ? 'Nada se comparte ni se envía sin tu acción.'
                                          : 'Nothing is shared or sent without your action.',
                                      style: const TextStyle(
                                        color: AppColors.tealSecondary,
                                        fontSize: 13,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  _SupportBottomAction(
                    isSpanish: isSpanish,
                    supporterCount: _activeSupporters,
                    taskCount: completedTasks.length,
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

class _SupportHeader extends StatelessWidget {
  const _SupportHeader({required this.isSpanish, required this.onBack});

  final bool isSpanish;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          IconButton.outlined(
            key: const ValueKey('support-back'),
            tooltip: isSpanish ? 'Atrás' : 'Back',
            onPressed: onBack,
            style: IconButton.styleFrom(
              foregroundColor: AppColors.deepTeal,
              side: const BorderSide(color: AppColors.border),
            ),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isSpanish ? 'Apoyo y preparación' : 'Support & preparation',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.deepTeal,
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              isSpanish ? '4 DE 5' : '4 OF 5',
              style: const TextStyle(
                color: AppColors.tealSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportProgress extends StatelessWidget {
  const _SupportProgress({required this.isSpanish});

  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              isSpanish ? 'PLAN PARA DEJARLO' : 'QUIT PLAN',
              style: const TextStyle(
                color: AppColors.mutedTeal,
                fontSize: 10,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            const Text(
              '80%',
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
            key: ValueKey('support-progress'),
            value: 0.8,
            minHeight: 6,
            backgroundColor: Color(0xFFDCE7E1),
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.coral),
          ),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.trailing,
    required this.trailingKey,
  });

  final String title;
  final String trailing;
  final Key trailingKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.mutedTeal,
              fontSize: 10.5,
              letterSpacing: 1.8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          key: trailingKey,
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.mint,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            trailing,
            style: const TextStyle(
              color: AppColors.deepTeal,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _SupportPersonCard extends StatelessWidget {
  const _SupportPersonCard({
    required this.person,
    required this.isSpanish,
    required this.channelLabel,
    required this.relationshipLabel,
    required this.checkInLabel,
    required this.onEnabledChanged,
    required this.onEdit,
  });

  final SupportPersonPlan person;
  final bool isSpanish;
  final String channelLabel;
  final String relationshipLabel;
  final String checkInLabel;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      key: ValueKey('support-person-${person.id}'),
      duration: const Duration(milliseconds: 150),
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: person.enabled ? AppColors.paper : const Color(0xFFF0F2ED),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: AppColors.mint,
                child: Text(
                  person.name.trim().isEmpty
                      ? '?'
                      : person.name.trim()[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.deepTeal,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.deepTeal,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$relationshipLabel · $channelLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.mutedTeal,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                key: ValueKey('support-person-toggle-${person.id}'),
                value: person.enabled,
                onChanged: onEnabledChanged,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.deepTeal,
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              const CircleAvatar(
                radius: 15,
                backgroundColor: AppColors.mint,
                child: Icon(
                  Icons.schedule_rounded,
                  color: AppColors.deepTeal,
                  size: 17,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  checkInLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.deepTeal,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                key: ValueKey('support-person-edit-${person.id}'),
                tooltip: isSpanish ? 'Editar' : 'Edit',
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.deepTeal,
                  size: 21,
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              isSpanish
                  ? 'No se envía nada hasta que lo revises y confirmes.'
                  : 'Nothing is sent until you review and confirm it.',
              style: const TextStyle(
                color: AppColors.mutedTeal,
                fontSize: 10.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySupportCard extends StatelessWidget {
  const _EmptySupportCard({required this.isSpanish});

  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('support-empty-state'),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        isSpanish
            ? 'Todavía no agregaste a nadie. Puedes guardar este plan sin contactar a una persona.'
            : 'No one has been added yet. You can save this plan without contacting anyone.',
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.tealSecondary, height: 1.35),
      ),
    );
  }
}

class _AddSupporterCard extends StatelessWidget {
  const _AddSupporterCard({required this.isSpanish, required this.onTap});

  final bool isSpanish;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      key: const ValueKey('support-add-person'),
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(58),
        foregroundColor: AppColors.deepTeal,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 14),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 19,
            backgroundColor: AppColors.mint,
            child: Icon(Icons.add_rounded, color: AppColors.deepTeal),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              onTap == null
                  ? (isSpanish
                      ? 'Límite de 10 personas alcanzado'
                      : '10-person limit reached')
                  : (isSpanish
                      ? 'Agregar otra persona de apoyo'
                      : 'Add another support person'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _PreparationChecklist extends StatelessWidget {
  const _PreparationChecklist({
    required this.completedTasks,
    required this.taskLabel,
    required this.onToggle,
  });

  final Set<PreparationTask> completedTasks;
  final String Function(PreparationTask) taskLabel;
  final ValueChanged<PreparationTask> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var index = 0;
              index < PreparationTask.values.length;
              index++) ...[
            _PreparationTaskTile(
              task: PreparationTask.values[index],
              label: taskLabel(PreparationTask.values[index]),
              selected: completedTasks.contains(PreparationTask.values[index]),
              onTap: () => onToggle(PreparationTask.values[index]),
            ),
            if (index < PreparationTask.values.length - 1)
              const Divider(height: 1, indent: 14, endIndent: 14),
          ],
        ],
      ),
    );
  }
}

class _PreparationTaskTile extends StatelessWidget {
  const _PreparationTaskTile({
    required this.task,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final PreparationTask task;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: selected,
      button: true,
      child: InkWell(
        key: ValueKey('preparation-task-${task.name}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          child: Row(
            children: [
              AnimatedContainer(
                key: selected
                    ? ValueKey('preparation-task-selected-${task.name}')
                    : null,
                duration: const Duration(milliseconds: 150),
                width: 31,
                height: 31,
                decoration: BoxDecoration(
                  color: selected ? AppColors.deepTeal : AppColors.paper,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.deepTeal : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        color: AppColors.lime,
                        size: 20,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.deepTeal,
                    fontSize: 13.5,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
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

class _TreatmentSupportCard extends StatelessWidget {
  const _TreatmentSupportCard({
    required this.isSpanish,
    required this.enabled,
    required this.careTeamReminder,
    required this.onEnabledChanged,
    required this.onCareTeamReminderChanged,
    required this.onLearn,
  });

  final bool isSpanish;
  final bool enabled;
  final bool careTeamReminder;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<bool> onCareTeamReminderChanged;
  final VoidCallback onLearn;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: enabled ? AppColors.mint : AppColors.paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: enabled ? AppColors.mintStrong : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 23,
                backgroundColor: AppColors.paper,
                child: Icon(
                  Icons.medication_outlined,
                  color: AppColors.coral,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSpanish
                          ? 'Explorar medicamentos para dejar de fumar'
                          : 'Explore quit-smoking medicines',
                      style: const TextStyle(
                        color: AppColors.deepTeal,
                        fontSize: 15,
                        height: 1.18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isSpanish
                          ? 'Un profesional puede ayudarte a elegir una opción segura.'
                          : 'A clinician or pharmacist can help you choose what is safe.',
                      style: const TextStyle(
                        color: AppColors.tealSecondary,
                        fontSize: 11.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                key: const ValueKey('support-treatment-toggle'),
                value: enabled,
                onChanged: onEnabledChanged,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.deepTeal,
              ),
            ],
          ),
          if (enabled) ...[
            const Divider(height: 20),
            InkWell(
              key: const ValueKey('support-care-team-reminder'),
              onTap: () => onCareTeamReminderChanged(!careTeamReminder),
              child: Row(
                children: [
                  Icon(
                    careTeamReminder
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: AppColors.deepTeal,
                    size: 23,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      isSpanish
                          ? 'Recordarme hablar de las opciones con mi equipo de atención'
                          : 'Remind me to discuss options with my care team',
                      style: const TextStyle(
                        color: AppColors.deepTeal,
                        fontSize: 12.5,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              isSpanish
                  ? 'Solo educación: esta aplicación no receta ni cambia medicamentos.'
                  : 'Education only — this app does not prescribe or change medicines.',
              style: const TextStyle(
                color: AppColors.tealSecondary,
                fontSize: 10.5,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 7),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const ValueKey('support-treatment-learn'),
              onPressed: onLearn,
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(
                isSpanish
                    ? 'Conocer las opciones de tratamiento'
                    : 'Learn about treatment options',
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.deepTeal,
                padding: EdgeInsets.zero,
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportBottomAction extends StatelessWidget {
  const _SupportBottomAction({
    required this.isSpanish,
    required this.supporterCount,
    required this.taskCount,
    required this.onContinue,
    required this.horizontalPadding,
    required this.compact,
  });

  final bool isSpanish;
  final int supporterCount;
  final int taskCount;
  final VoidCallback onContinue;
  final double horizontalPadding;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        compact ? 9 : 11,
        horizontalPadding,
        compact ? 8 : 11,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(top: BorderSide(color: Color(0xFFDCE5DF))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton(
            key: const ValueKey('support-save'),
            onPressed: onContinue,
            style: FilledButton.styleFrom(
              minimumSize: Size.fromHeight(compact ? 52 : 58),
              backgroundColor: AppColors.deepTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    isSpanish
                        ? 'Guardar mi plan de apoyo'
                        : 'Save my support plan',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.arrow_forward_rounded, color: AppColors.lime),
              ],
            ),
          ),
          const SizedBox(height: 7),
          Text(
            isSpanish
                ? '$supporterCount ${supporterCount == 1 ? 'persona de apoyo' : 'personas de apoyo'} · $taskCount tareas completadas'
                : '$supporterCount ${supporterCount == 1 ? 'supporter' : 'supporters'} · $taskCount preparation tasks complete',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.mutedTeal,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportPersonEditor extends StatefulWidget {
  const _SupportPersonEditor({
    required this.isSpanish,
    required this.person,
    required this.onSave,
    required this.onRemove,
  });

  final bool isSpanish;
  final SupportPersonPlan? person;
  final ValueChanged<SupportPersonPlan> onSave;
  final VoidCallback? onRemove;

  @override
  State<_SupportPersonEditor> createState() => _SupportPersonEditorState();
}

class _SupportPersonEditorState extends State<_SupportPersonEditor> {
  late final TextEditingController _nameController;
  late final TextEditingController _relationshipController;
  late SupportChannel _channel;
  bool _attemptedSave = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.person?.name ?? '');
    _relationshipController = TextEditingController(
      text: widget.person?.relationship ?? '',
    );
    _channel = widget.person?.channel ?? SupportChannel.text;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _attemptedSave = true);
      return;
    }
    final relationship = _relationshipController.text.trim();
    final isSpanish = widget.isSpanish;
    widget.onSave(
      SupportPersonPlan(
        id: widget.person?.id ??
            'person-${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        relationship: relationship.isEmpty
            ? (isSpanish ? 'Persona de apoyo' : 'Support person')
            : relationship,
        channel: _channel,
        checkIn: widget.person?.checkIn ??
            (isSpanish
                ? 'Contactarme la noche antes de mi fecha para dejarlo'
                : 'Check in the evening before my quit date'),
        enabled: widget.person?.enabled ?? true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(22, 0, 22, keyboardInset + 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.person == null
                    ? (widget.isSpanish
                        ? 'Agregar una persona de apoyo'
                        : 'Add a support person')
                    : (widget.isSpanish
                        ? 'Editar persona de apoyo'
                        : 'Edit support person'),
                style: const TextStyle(
                  color: AppColors.deepTeal,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.isSpanish
                    ? 'No se enviará ningún mensaje hasta que lo revises y confirmes.'
                    : 'No message will be sent until you review and confirm it.',
                style: const TextStyle(
                  color: AppColors.tealSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const ValueKey('support-person-name-field'),
                controller: _nameController,
                autofocus: widget.person == null,
                maxLength: 50,
                decoration: InputDecoration(
                  labelText: widget.isSpanish ? 'Nombre' : 'Name',
                  errorText:
                      _attemptedSave && _nameController.text.trim().isEmpty
                          ? (widget.isSpanish
                              ? 'Ingresa un nombre'
                              : 'Enter a name')
                          : null,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) {
                  if (_attemptedSave) setState(() {});
                },
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('support-person-relationship-field'),
                controller: _relationshipController,
                maxLength: 40,
                decoration: InputDecoration(
                  labelText: widget.isSpanish
                      ? 'Relación (opcional)'
                      : 'Relationship (optional)',
                  hintText: widget.isSpanish
                      ? 'Amigo, familiar...'
                      : 'Friend, family...',
                  border: const OutlineInputBorder(),
                ),
              ),
              Text(
                widget.isSpanish ? 'FORMA DE CONTACTO' : 'CONTACT METHOD',
                style: const TextStyle(
                  color: AppColors.mutedTeal,
                  fontSize: 10.5,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<SupportChannel>(
                key: const ValueKey('support-person-channel'),
                segments: [
                  ButtonSegment(
                    value: SupportChannel.text,
                    icon: const Icon(Icons.message_outlined),
                    label: Text(widget.isSpanish ? 'Texto' : 'Text'),
                  ),
                  ButtonSegment(
                    value: SupportChannel.call,
                    icon: const Icon(Icons.call_outlined),
                    label: Text(widget.isSpanish ? 'Llamada' : 'Call'),
                  ),
                ],
                selected: {_channel},
                onSelectionChanged: (value) {
                  setState(() => _channel = value.first);
                },
              ),
              const SizedBox(height: 18),
              FilledButton(
                key: const ValueKey('support-person-save'),
                onPressed: _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: AppColors.deepTeal,
                ),
                child:
                    Text(widget.isSpanish ? 'Guardar persona' : 'Save person'),
              ),
              if (widget.onRemove != null) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  key: const ValueKey('support-person-remove'),
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text(
                    widget.isSpanish
                        ? 'Eliminar persona de apoyo'
                        : 'Remove support person',
                  ),
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    foregroundColor: AppColors.coral,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TreatmentEducationSheet extends StatelessWidget {
  const _TreatmentEducationSheet({
    required this.isSpanish,
    required this.onDone,
  });

  final bool isSpanish;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 25,
              backgroundColor: AppColors.coralLight,
              child: Icon(
                Icons.medication_outlined,
                color: AppColors.coral,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isSpanish
                  ? 'Opciones de tratamiento para dejar de fumar'
                  : 'Quit-smoking treatment options',
              style: const TextStyle(
                color: AppColors.deepTeal,
                fontSize: 23,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isSpanish
                  ? 'Los productos de reemplazo de nicotina y algunos medicamentos recetados pueden reducir los síntomas de abstinencia. Un médico o farmacéutico puede ayudarte a elegir una opción adecuada según tu salud y otros medicamentos.'
                  : 'Nicotine-replacement products and some prescription medicines can reduce withdrawal symptoms. A clinician or pharmacist can help you choose an appropriate option based on your health and other medicines.',
              style: const TextStyle(
                color: AppColors.tealSecondary,
                fontSize: 15,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                isSpanish
                    ? 'Esta información es educativa. BreatheFree no receta, recomienda una dosis ni cambia tus medicamentos.'
                    : 'This information is educational. BreatheFree does not prescribe, recommend a dose, or change your medicines.',
                style: const TextStyle(
                  color: AppColors.deepTeal,
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              key: const ValueKey('support-treatment-done'),
              onPressed: onDone,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: AppColors.deepTeal,
              ),
              child: Text(isSpanish ? 'Listo' : 'Done'),
            ),
          ],
        ),
      ),
    );
  }
}
