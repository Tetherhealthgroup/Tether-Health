import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Screen 24 — Medication Center.
///
/// The approved Screen 24 artwork is the visual source of truth. Typography is
/// calibrated to the same device-sized Flutter hierarchy used by the already
/// approved screens rather than applying a blanket SVG export-scale division.
enum MedicationTodayStatus { taken, notYet, missed }

enum _RecordedMedicine { nicotinePatch, nicotineGum, nicotineLozenge, other }

enum _RecordedTiming { morning, afternoon, evening, other }

enum _MedicationEducationTopic { nicotineReplacement, prescriptionMedicines }

class _MedicationEducationPointData {
  const _MedicationEducationPointData({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

class _MedicationPlanDraft {
  const _MedicationPlanDraft({
    required this.medicine,
    required this.timing,
    required this.note,
  });

  final _RecordedMedicine medicine;
  final _RecordedTiming timing;
  final String note;
}

class MedicationCenterScreen extends StatefulWidget {
  const MedicationCenterScreen({
    required this.isSpanish,
    required this.reminderPreviews,
    required this.todayStatus,
    required this.onReminderPreviewsChanged,
    required this.onTodayStatusChanged,
    required this.onBack,
    required this.onOpenLearn,
    required this.onOpenSupport,
    required this.onOpenHome,
    required this.onOpenProgress,
    super.key,
  });

  final bool isSpanish;
  final bool reminderPreviews;
  final MedicationTodayStatus todayStatus;
  final ValueChanged<bool> onReminderPreviewsChanged;
  final ValueChanged<MedicationTodayStatus> onTodayStatusChanged;
  final VoidCallback onBack;
  final VoidCallback onOpenLearn;
  final VoidCallback onOpenSupport;
  final VoidCallback onOpenHome;
  final VoidCallback onOpenProgress;

  @override
  State<MedicationCenterScreen> createState() => _MedicationCenterScreenState();
}

class _MedicationCenterScreenState extends State<MedicationCenterScreen> {
  _RecordedMedicine _recordedMedicine = _RecordedMedicine.nicotinePatch;
  _RecordedTiming _recordedTiming = _RecordedTiming.morning;
  String _recordedNote = '';
  DateTime? _takenRecordedAt;
  bool _restoredTakenRecordedAt = false;

  static const String _takenRecordedAtStorageKey =
      'medication-center-taken-recorded-at';

  bool get isSpanish => widget.isSpanish;

  String t(String english, String spanish) => isSpanish ? spanish : english;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_restoredTakenRecordedAt) return;
    _restoredTakenRecordedAt = true;

    final storedMilliseconds = PageStorage.maybeOf(context)?.readState(
      context,
      identifier: _takenRecordedAtStorageKey,
    );

    if (storedMilliseconds is int) {
      _takenRecordedAt =
          DateTime.fromMillisecondsSinceEpoch(storedMilliseconds);
    }
  }

  void _storeTakenRecordedAt(DateTime? value) {
    PageStorage.maybeOf(context)?.writeState(
      context,
      value?.millisecondsSinceEpoch,
      identifier: _takenRecordedAtStorageKey,
    );
  }

  String _formatRecordedTime(DateTime value) {
    final hour12 = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour < 12 ? 'AM' : 'PM';
    return '$hour12:$minute $period';
  }

  String get statusTitle => switch (widget.todayStatus) {
        MedicationTodayStatus.taken => _takenRecordedAt == null
            ? t('Recorded as taken', 'Registrado como tomado')
            : t(
                'Recorded taken at ${_formatRecordedTime(_takenRecordedAt!)}',
                'Registrado como tomado a las ${_formatRecordedTime(_takenRecordedAt!)}',
              ),
        MedicationTodayStatus.notYet =>
          t('Recorded not taken yet', 'Registrado como aún no tomado'),
        MedicationTodayStatus.missed =>
          t('Recorded as missed', 'Registrado como omitido'),
      };

  String get statusSubtitle => switch (widget.todayStatus) {
        MedicationTodayStatus.taken => t(
            'Next reminder: Tomorrow at 8:00 AM',
            'Próximo recordatorio: mañana a las 8:00 AM',
          ),
        MedicationTodayStatus.notYet => t(
            'Follow only your recorded plan.',
            'Sigue únicamente tu plan registrado.',
          ),
        MedicationTodayStatus.missed => t(
            'Review your recorded instructions or contact your care team.',
            'Revisa tus instrucciones registradas o contacta a tu equipo de atención.',
          ),
      };

  String _medicineLabel(_RecordedMedicine medicine) => switch (medicine) {
        _RecordedMedicine.nicotinePatch => t('Nicotine patch', 'Parche de nicotina'),
        _RecordedMedicine.nicotineGum => t('Nicotine gum', 'Chicle de nicotina'),
        _RecordedMedicine.nicotineLozenge =>
          t('Nicotine lozenge', 'Pastilla de nicotina'),
        _RecordedMedicine.other =>
          t('Other recorded medicine', 'Otro medicamento registrado'),
      };

  String _timingLabel(_RecordedTiming timing) => switch (timing) {
        _RecordedTiming.morning => t('Morning', 'Mañana'),
        _RecordedTiming.afternoon => t('Afternoon', 'Tarde'),
        _RecordedTiming.evening => t('Evening', 'Noche'),
        _RecordedTiming.other => t('Other timing', 'Otro horario'),
      };

  String get _planInstruction {
    final timing = _timingLabel(_recordedTiming);
    final note = _recordedNote.trim();
    if (note.isNotEmpty) return '$timing · $note';
    return t(
      '$timing · Follow the instructions in your recorded plan',
      '$timing · Sigue las instrucciones de tu plan registrado',
    );
  }

  Future<void> _openStatusSheet(BuildContext context) async {
    final selected = await showModalBottomSheet<MedicationTodayStatus>(
      context: context,
      backgroundColor: AppColors.paper,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 2, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t("Update today’s status", 'Actualizar el estado de hoy'),
                style: const TextStyle(
                  fontFamily: 'Arial',
                  color: AppColors.deepTeal,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                t(
                  'Record what happened. This does not change your medication instructions.',
                  'Registra lo que ocurrió. Esto no cambia las instrucciones de tu medicamento.',
                ),
                style: const TextStyle(
                  fontFamily: 'Arial',
                  color: AppColors.mutedTeal,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 14),
              _StatusOption(
                key: const ValueKey('medication-status-taken'),
                title: t('Taken', 'Tomado'),
                icon: Icons.check_rounded,
                selected: widget.todayStatus == MedicationTodayStatus.taken,
                onTap: () => Navigator.pop(context, MedicationTodayStatus.taken),
              ),
              const SizedBox(height: 8),
              _StatusOption(
                key: const ValueKey('medication-status-not-yet'),
                title: t('Not yet', 'Aún no'),
                icon: Icons.schedule_rounded,
                selected: widget.todayStatus == MedicationTodayStatus.notYet,
                onTap: () => Navigator.pop(context, MedicationTodayStatus.notYet),
              ),
              const SizedBox(height: 8),
              _StatusOption(
                key: const ValueKey('medication-status-missed'),
                title: t('Missed', 'Omitido'),
                icon: Icons.remove_rounded,
                selected: widget.todayStatus == MedicationTodayStatus.missed,
                onTap: () => Navigator.pop(context, MedicationTodayStatus.missed),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected == null) return;

    final recordedAt =
        selected == MedicationTodayStatus.taken ? DateTime.now() : null;

    if (mounted) {
      setState(() {
        _takenRecordedAt = recordedAt;
      });
      _storeTakenRecordedAt(recordedAt);
    }

    widget.onTodayStatusChanged(selected);
  }

  Future<void> _openPlanSheet(BuildContext context) async {
    var draftMedicine = _recordedMedicine;
    var draftTiming = _recordedTiming;
    final noteController = TextEditingController(text: _recordedNote);

    final result = await showModalBottomSheet<_MedicationPlanDraft>(
      context: context,
      backgroundColor: AppColors.paper,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          return AnimatedPadding(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 2, 22, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('Recorded medication plan', 'Plan de medicamentos registrado'),
                    style: const TextStyle(
                      fontFamily: 'Arial',
                      color: AppColors.deepTeal,
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    t(
                      'Record a plan you already use with your clinician or care team. BreatheFree does not prescribe or change a dose.',
                      'Registra un plan que ya usas con tu profesional clínico o equipo de atención. BreatheFree no receta ni cambia una dosis.',
                    ),
                    style: const TextStyle(
                      fontFamily: 'Arial',
                      color: AppColors.mutedTeal,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    t('Medicine in your recorded plan', 'Medicamento en tu plan registrado'),
                    style: const TextStyle(
                      fontFamily: 'Arial',
                      color: AppColors.deepTeal,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _RecordedMedicine.values.map((medicine) {
                      return ChoiceChip(
                        key: ValueKey('medication-plan-medicine-${medicine.name}'),
                        label: Text(_medicineLabel(medicine)),
                        selected: draftMedicine == medicine,
                        onSelected: (_) {
                          setSheetState(() => draftMedicine = medicine);
                        },
                        selectedColor: const Color(0xFFE1F0E8),
                        side: BorderSide(
                          color: draftMedicine == medicine
                              ? AppColors.deepTeal
                              : const Color(0xFFD6E2DC),
                        ),
                        labelStyle: const TextStyle(
                          fontFamily: 'Arial',
                          color: AppColors.deepTeal,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    t('When you record using it', 'Cuándo registras su uso'),
                    style: const TextStyle(
                      fontFamily: 'Arial',
                      color: AppColors.deepTeal,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _RecordedTiming.values.map((timing) {
                      return ChoiceChip(
                        key: ValueKey('medication-plan-timing-${timing.name}'),
                        label: Text(_timingLabel(timing)),
                        selected: draftTiming == timing,
                        onSelected: (_) {
                          setSheetState(() => draftTiming = timing);
                        },
                        selectedColor: const Color(0xFFE1F0E8),
                        side: BorderSide(
                          color: draftTiming == timing
                              ? AppColors.deepTeal
                              : const Color(0xFFD6E2DC),
                        ),
                        labelStyle: const TextStyle(
                          fontFamily: 'Arial',
                          color: AppColors.deepTeal,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    key: const ValueKey('medication-plan-note'),
                    controller: noteController,
                    maxLines: 2,
                    maxLength: 90,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: t(
                        'Your recorded-plan note (optional)',
                        'Nota de tu plan registrado (opcional)',
                      ),
                      hintText: t(
                        'Example: Follow the instructions from my care team',
                        'Ejemplo: Seguir las instrucciones de mi equipo de atención',
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF5F8F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFD6E2DC)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFD6E2DC)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.deepTeal,
                          width: 1.5,
                        ),
                      ),
                    ),
                    style: const TextStyle(
                      fontFamily: 'Arial',
                      color: AppColors.deepTeal,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4EF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.coral,
                          size: 19,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            t(
                              'This only records what you already use. For medicine or dose changes, contact your clinician, pharmacist, or care team.',
                              'Esto solo registra lo que ya usas. Para cambiar un medicamento o una dosis, contacta a tu profesional clínico, farmacéutico o equipo de atención.',
                            ),
                            style: const TextStyle(
                              fontFamily: 'Arial',
                              color: AppColors.mutedTeal,
                              fontSize: 11.5,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      key: const ValueKey('medication-plan-sheet-done'),
                      onPressed: () {
                        Navigator.pop(
                          sheetContext,
                          _MedicationPlanDraft(
                            medicine: draftMedicine,
                            timing: draftTiming,
                            note: noteController.text.trim(),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.deepTeal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        t('Done', 'Listo'),
                        style: const TextStyle(
                          fontFamily: 'Arial',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    noteController.dispose();
    if (result == null || !mounted) return;

    setState(() {
      _recordedMedicine = result.medicine;
      _recordedTiming = result.timing;
      _recordedNote = result.note;
    });
  }

  Future<void> _openEducationTopic(
    BuildContext context,
    _MedicationEducationTopic topic,
  ) async {
    final isNrt = topic == _MedicationEducationTopic.nicotineReplacement;
    final title = isNrt
        ? t('Nicotine replacement', 'Reemplazo de nicotina')
        : t('Prescription medicines', 'Medicamentos con receta');
    final subtitle = isNrt
        ? t(
            'Patch, gum, lozenge and other nicotine-replacement options.',
            'Parche, chicle, pastilla y otras opciones de reemplazo de nicotina.',
          )
        : t(
            'Varenicline and bupropion SR are prescription options used in quit-smoking treatment.',
            'La vareniclina y el bupropión SR son opciones con receta usadas en el tratamiento para dejar de fumar.',
          );

    final points = isNrt
        ? <_MedicationEducationPointData>[
            _MedicationEducationPointData(
              icon: Icons.category_outlined,
              title: t('What it includes', 'Qué incluye'),
              body: t(
                'Nicotine replacement includes products such as patches, gum and lozenges.',
                'El reemplazo de nicotina incluye productos como parches, chicle y pastillas.',
              ),
            ),
            _MedicationEducationPointData(
              icon: Icons.assignment_outlined,
              title: t('Follow your recorded plan', 'Sigue tu plan registrado'),
              body: t(
                'Use only the product and instructions already provided by your clinician or the product label. This app does not choose a product or change a dose.',
                'Usa únicamente el producto y las instrucciones ya indicadas por tu profesional clínico o la etiqueta del producto. Esta aplicación no elige un producto ni cambia una dosis.',
              ),
            ),
            _MedicationEducationPointData(
              icon: Icons.health_and_safety_outlined,
              title: t('Questions or precautions', 'Preguntas o precauciones'),
              body: t(
                'Ask a clinician or pharmacist about questions, side effects, pregnancy or breastfeeding, or use by someone under 18.',
                'Consulta a un profesional clínico o farmacéutico sobre preguntas, efectos secundarios, embarazo o lactancia, o el uso por una persona menor de 18 años.',
              ),
            ),
          ]
        : <_MedicationEducationPointData>[
            _MedicationEducationPointData(
              icon: Icons.medical_information_outlined,
              title: t('Prescription options', 'Opciones con receta'),
              body: t(
                'Varenicline and bupropion SR are medicines that require a prescription.',
                'La vareniclina y el bupropión SR son medicamentos que requieren receta.',
              ),
            ),
            _MedicationEducationPointData(
              icon: Icons.person_outline_rounded,
              title: t('A prescriber guides treatment', 'Un profesional guía el tratamiento'),
              body: t(
                'A licensed prescriber decides whether a prescription medicine is appropriate and provides the instructions for use.',
                'Un profesional autorizado decide si un medicamento con receta es apropiado y proporciona las instrucciones de uso.',
              ),
            ),
            _MedicationEducationPointData(
              icon: Icons.health_and_safety_outlined,
              title: t('Keep changes with your care team', 'Mantén los cambios con tu equipo de atención'),
              body: t(
                'Do not start, stop or change a prescription based on this app. Contact your prescriber for side effects or medication questions.',
                'No empieces, suspendas ni cambies una receta basándote en esta aplicación. Contacta a quien te recetó por efectos secundarios o preguntas sobre medicamentos.',
              ),
            ),
          ];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 2, 22, 24),
          child: Column(
            key: ValueKey(
              isNrt
                  ? 'medication-nrt-topic-sheet'
                  : 'medication-prescription-topic-sheet',
            ),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isNrt
                          ? const Color(0xFFE6F1EA)
                          : const Color(0xFFFFF0EB),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isNrt
                          ? Icons.medication_outlined
                          : Icons.medication_rounded,
                      color: isNrt ? AppColors.deepTeal : AppColors.coral,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: 'Arial',
                            color: AppColors.deepTeal,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            height: 1.08,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontFamily: 'Arial',
                            color: AppColors.mutedTeal,
                            fontSize: 13.5,
                            height: 1.32,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F5F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.deepTeal,
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t(
                          'Education only. Your clinician, prescriber or pharmacist should guide medication decisions.',
                          'Solo educación. Tu profesional clínico, quien receta o tu farmacéutico debe guiar las decisiones sobre medicamentos.',
                        ),
                        style: const TextStyle(
                          fontFamily: 'Arial',
                          color: AppColors.deepTeal,
                          fontSize: 12.5,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              for (var index = 0; index < points.length; index++) ...[
                _MedicationEducationPoint(
                  icon: points[index].icon,
                  title: points[index].title,
                  body: points[index].body,
                ),
                if (index != points.length - 1) const SizedBox(height: 10),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const ValueKey('medication-education-open-library'),
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    widget.onOpenLearn();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.deepTeal,
                    side: const BorderSide(color: AppColors.deepTeal),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.menu_book_outlined, size: 20),
                  label: Text(
                    t('Open full Learn library', 'Abrir toda la biblioteca Aprende'),
                    style: const TextStyle(
                      fontFamily: 'Arial',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  key: const ValueKey('medication-education-topic-close'),
                  onPressed: () => Navigator.pop(sheetContext),
                  child: Text(
                    t('Close', 'Cerrar'),
                    style: const TextStyle(
                      fontFamily: 'Arial',
                      color: AppColors.mutedTeal,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('functional-medication-center-screen'),
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _MedicationTopBar(
              isSpanish: isSpanish,
              onBack: widget.onBack,
              onAdd: () => _openPlanSheet(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                key: const ValueKey('medication-center-scroll'),
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ClinicalNotice(isSpanish: isSpanish),
                    const SizedBox(height: 14),
                    _RecordedPlanCard(
                      isSpanish: isSpanish,
                      planTitle: _medicineLabel(_recordedMedicine),
                      planInstruction: _planInstruction,
                      usePatchArtwork:
                          _recordedMedicine == _RecordedMedicine.nicotinePatch,
                      statusTitle: statusTitle,
                      statusSubtitle: statusSubtitle,
                      onUpdateStatus: () => _openStatusSheet(context),
                    ),
                    const SizedBox(height: 14),
                    _ReminderPreviewCard(
                      isSpanish: isSpanish,
                      value: widget.reminderPreviews,
                      onChanged: widget.onReminderPreviewsChanged,
                    ),
                    const SizedBox(height: 12),
                    _SectionHeader(
                      title: t(
                        'Learn about quit-smoking medicines',
                        'Aprende sobre medicamentos para dejar de fumar',
                      ),
                      trailing: t('Clinically reviewed', 'Revisado clínicamente'),
                    ),
                    const SizedBox(height: 6),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _EducationCard(
                              key: const ValueKey('medication-nrt-card'),
                              isSpanish: isSpanish,
                              icon: Icons.medication_outlined,
                              iconColor: AppColors.deepTeal,
                              iconBackground: const Color(0xFFE6F1EA),
                              title: t(
                                'Nicotine replacement',
                                'Reemplazo de nicotina',
                              ),
                              subtitle: t(
                                'Patch, gum, lozenge and more',
                                'Parche, chicle, pastilla y más',
                              ),
                              footer: t(
                                'Benefits · use · precautions',
                                'Beneficios · uso · precauciones',
                              ),
                              onTap: () => _openEducationTopic(
                                context,
                                _MedicationEducationTopic.nicotineReplacement,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _EducationCard(
                              key: const ValueKey(
                                'medication-prescription-card',
                              ),
                              isSpanish: isSpanish,
                              icon: Icons.medication_rounded,
                              iconColor: AppColors.coral,
                              iconBackground: const Color(0xFFFFF0EB),
                              title: t(
                                'Prescription options',
                                'Opciones con receta',
                              ),
                              subtitle: t(
                                'Varenicline · bupropion SR',
                                'Vareniclina · bupropión SR',
                              ),
                              footer: t(
                                'Requires a prescriber',
                                'Requiere quien recete',
                              ),
                              onTap: () => _openEducationTopic(
                                context,
                                _MedicationEducationTopic.prescriptionMedicines,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SafetyBanner(
                      isSpanish: isSpanish,
                      onTap: widget.onOpenSupport,
                    ),
                    const SizedBox(height: 13),
                    Text(
                      t('Plan help', 'Ayuda con el plan'),
                      style: const TextStyle(
                        fontFamily: 'Arial',
                        color: AppColors.deepTeal,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _PlanHelpCard(
                      isSpanish: isSpanish,
                      onReview: () => _openPlanSheet(context),
                      onGetHelp: widget.onOpenSupport,
                      onContact: widget.onOpenSupport,
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: const ValueKey('medication-add-update-plan'),
                        onPressed: () => _openPlanSheet(context),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
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
                                t(
                                  'Add or update recorded plan',
                                  'Agregar o actualizar el plan registrado',
                                ),
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Arial',
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  height: 1.05,
                                ),
                              ),
                            ),
                            const SizedBox(width: 9),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: AppColors.lime,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _OfflineNote(isSpanish: isSpanish),
                  ],
                ),
              ),
            ),
            _MedicationBottomNav(
              isSpanish: isSpanish,
              onHome: widget.onOpenHome,
              onProgress: widget.onOpenProgress,
              onLearn: widget.onOpenLearn,
              onSupport: widget.onOpenSupport,
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicationTopBar extends StatelessWidget {
  const _MedicationTopBar({
    required this.isSpanish,
    required this.onBack,
    required this.onAdd,
  });

  final bool isSpanish;
  final VoidCallback onBack;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: _HeaderTapTarget(
                key: const ValueKey('medication-back'),
                onTap: onBack,
                diameter: 25,
                backgroundColor: AppColors.paper,
                borderColor: AppColors.border,
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.deepTeal,
                  size: 13,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 54),
              child: Text(
                isSpanish ? 'Centro de medicamentos' : 'Medication center',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Arial',
                  color: AppColors.deepTeal,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: _HeaderTapTarget(
                key: const ValueKey('medication-add-plan-top'),
                onTap: onAdd,
                diameter: 30,
                backgroundColor: const Color(0xFFDDF1E8),
                borderColor: const Color(0xFFC4E1D4),
                child: const Icon(
                  Icons.add_rounded,
                  color: AppColors.deepTeal,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderTapTarget extends StatelessWidget {
  const _HeaderTapTarget({
    required this.onTap,
    required this.diameter,
    required this.backgroundColor,
    required this.borderColor,
    required this.child,
    super.key,
  });

  final VoidCallback onTap;
  final double diameter;
  final Color backgroundColor;
  final Color borderColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Center(
            child: Container(
              width: diameter,
              height: diameter,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: .8),
              ),
              alignment: Alignment.center,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _ClinicalNotice extends StatelessWidget {
  const _ClinicalNotice({required this.isSpanish});

  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF5F1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: AppColors.deepTeal,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text(
              'i',
              style: TextStyle(
                fontFamily: 'Arial',
                color: AppColors.lime,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSpanish
                      ? 'Educación y seguimiento—sin recetar'
                      : 'Education and tracking—not prescribing',
                  style: const TextStyle(
                    fontFamily: 'Arial',
                    color: AppColors.deepTeal,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isSpanish
                      ? 'La app nunca selecciona un medicamento ni cambia una dosis.'
                      : 'The app never selects a medicine or changes a dose.',
                  style: const TextStyle(
                    fontFamily: 'Arial',
                    color: AppColors.mutedTeal,
                    fontSize: 9,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 82,
            child: Text(
              isSpanish ? 'Contenido clínico v3.2' : 'Clinical content v3.2',
              maxLines: 2,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Arial',
                color: AppColors.mutedTeal,
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordedPlanCard extends StatelessWidget {
  const _RecordedPlanCard({
    required this.isSpanish,
    required this.planTitle,
    required this.planInstruction,
    required this.usePatchArtwork,
    required this.statusTitle,
    required this.statusSubtitle,
    required this.onUpdateStatus,
  });

  final bool isSpanish;
  final String planTitle;
  final String planInstruction;
  final bool usePatchArtwork;
  final String statusTitle;
  final String statusSubtitle;
  final VoidCallback onUpdateStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF103A35), Color(0xFF1C5149)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A123C37),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.only(right: 118),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSpanish ? 'TU PLAN REGISTRADO' : 'YOUR RECORDED PLAN',
                        style: const TextStyle(
                          fontFamily: 'Arial',
                          color: Color(0xFFBFD5CD),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        planTitle,
                        maxLines: 2,
                        style: const TextStyle(
                          fontFamily: 'Arial',
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        planInstruction,
                        maxLines: 2,
                        style: const TextStyle(
                          fontFamily: 'Arial',
                          color: Color(0xFFBFD5CD),
                          fontSize: 11.5,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _PlanBadge(
                            icon: Icons.circle,
                            iconColor: AppColors.coral,
                            text: isSpanish ? 'INGRESADO POR TI' : 'ENTERED BY YOU',
                          ),
                          _PlanBadge(
                            icon: Icons.add_rounded,
                            iconColor: AppColors.lime,
                            text: isSpanish ? 'PLAN ACTIVO' : 'PLAN ACTIVE',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: -6,
                top: -20,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A625A).withValues(alpha: .75),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF7AA298),
                        width: 1.2,
                      ),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: usePatchArtwork
                        ? const _PatchIcon(size: 60)
                        : const Icon(
                            Icons.medication_outlined,
                            color: AppColors.deepTeal,
                            size: 48,
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
            decoration: BoxDecoration(
              color: const Color(0xFF255A53),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: AppColors.lime,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: AppColors.deepTeal,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isSpanish ? 'ESTADO DE HOY' : "TODAY’S STATUS",
                            style: const TextStyle(
                              fontFamily: 'Arial',
                              color: Color(0xFFBFD5CD),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: .65,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            statusTitle,
                            key: const ValueKey('medication-status-title'),
                            maxLines: 2,
                            style: const TextStyle(
                              fontFamily: 'Arial',
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              height: 1.08,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            statusSubtitle,
                            maxLines: 2,
                            style: const TextStyle(
                              fontFamily: 'Arial',
                              color: Color(0xFFBFD5CD),
                              fontSize: 9.5,
                              height: 1.15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 126,
                      child: FilledButton(
                        key: const ValueKey('medication-update-status'),
                        onPressed: onUpdateStatus,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(126, 38),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          backgroundColor: AppColors.lime,
                          foregroundColor: AppColors.deepTeal,
                          shape: const StadiumBorder(),
                        ),
                        child: Text(
                          isSpanish ? 'Actualizar estado de hoy' : "Update today’s status",
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Arial',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            height: 1.05,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  isSpanish
                      ? 'Este es tu registro; no confirma cómo se usó el medicamento.'
                      : 'This is your report; it does not confirm how the medicine was used.',
                  style: const TextStyle(
                    fontFamily: 'Arial',
                    color: Color(0xFFBFD5CD),
                    fontSize: 9,
                    height: 1.15,
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

class _PlanBadge extends StatelessWidget {
  const _PlanBadge({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  final IconData icon;
  final Color iconColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF70958C)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 9),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Arial',
              color: Colors.white,
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _PatchIcon extends StatelessWidget {
  const _PatchIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.lime,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Container(
        width: size * .48,
        height: size * .24,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.deepTeal, width: 2.3),
          borderRadius: BorderRadius.circular(size),
        ),
        child: Center(
          child: Container(
            width: 2,
            color: AppColors.deepTeal,
          ),
        ),
      ),
    );
  }
}

class _ReminderPreviewCard extends StatelessWidget {
  const _ReminderPreviewCard({
    required this.isSpanish,
    required this.value,
    required this.onChanged,
  });

  final bool isSpanish;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F123C37),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFFE6F1EA),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.deepTeal,
              size: 18,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSpanish ? 'Vistas previas privadas' : 'Private reminder previews',
                  style: const TextStyle(
                    fontFamily: 'Arial',
                    color: AppColors.deepTeal,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isSpanish
                      ? 'La pantalla bloqueada muestra “Tienes un recordatorio de BreatheFree”.'
                      : 'Lock screen shows “You have a BreatheFree reminder.”',
                  style: const TextStyle(
                    fontFamily: 'Arial',
                    color: AppColors.mutedTeal,
                    fontSize: 9.5,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            height: 34,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: .82,
                  child: Switch(
                    key: const ValueKey('medication-reminder-switch'),
                    value: value,
                    onChanged: onChanged,
                    activeThumbColor: AppColors.lime,
                    activeTrackColor: AppColors.deepTeal,
                    inactiveThumbColor: AppColors.paper,
                    inactiveTrackColor: AppColors.border,
                  ),
                ),
                if (value)
                  const Positioned(
                    left: 3,
                    child: IgnorePointer(
                      child: Text(
                        'ON',
                        style: TextStyle(
                          fontFamily: 'Arial',
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Arial',
              color: AppColors.deepTeal,
              fontSize: 19,
              fontWeight: FontWeight.w700,
              height: 1.05,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          trailing,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontFamily: 'Arial',
            color: AppColors.mutedTeal,
            fontSize: 9.5,
          ),
        ),
      ],
    );
  }
}

class _MedicationEducationPoint extends StatelessWidget {
  const _MedicationEducationPoint({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD9E4DE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFFE6F1EA),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.deepTeal, size: 19),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Arial',
                    color: AppColors.deepTeal,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    fontFamily: 'Arial',
                    color: AppColors.mutedTeal,
                    fontSize: 12.5,
                    height: 1.32,
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

class _EducationCard extends StatelessWidget {
  const _EducationCard({
    required this.isSpanish,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.footer,
    required this.onTap,
    super.key,
  });

  final bool isSpanish;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final String footer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.paper,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 11, 11, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F123C37),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 60),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 31,
                      height: 31,
                      decoration: BoxDecoration(
                        color: iconBackground,
                        shape: BoxShape.circle,
                      ),
                      child: _MedicineGlyph(
                        color: iconColor,
                        vertical: icon == Icons.medication_rounded,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 3,
                            style: const TextStyle(
                              fontFamily: 'Arial',
                              color: AppColors.deepTeal,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              height: 1.08,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            subtitle,
                            maxLines: 3,
                            style: const TextStyle(
                              fontFamily: 'Arial',
                              color: AppColors.mutedTeal,
                              fontSize: 9.5,
                              height: 1.18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 9),
                child: Divider(height: 1, color: Color(0xFFE1E9E4)),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      footer,
                      maxLines: 2,
                      style: const TextStyle(
                        fontFamily: 'Arial',
                        color: AppColors.mutedTeal,
                        fontSize: 9.5,
                        height: 1.15,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.deepTeal,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MedicineGlyph extends StatelessWidget {
  const _MedicineGlyph({required this.color, required this.vertical});

  final Color color;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: vertical ? 9 : 17,
        height: vertical ? 19 : 8,
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1.7),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Center(
          child: Container(
            width: vertical ? 7 : 1.5,
            height: vertical ? 1.5 : 6,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _SafetyBanner extends StatelessWidget {
  const _SafetyBanner({required this.isSpanish, required this.onTap});

  final bool isSpanish;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFE7E0),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        key: const ValueKey('medication-pregnancy-support'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFFFB9A8)),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.coral,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.priority_high_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSpanish
                          ? '¿Embarazo, lactancia o menor de 18 años?'
                          : 'Pregnant, breastfeeding or under 18?',
                      style: const TextStyle(
                        fontFamily: 'Arial',
                        color: AppColors.deepTeal,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isSpanish
                          ? 'Habla con un médico antes de usar medicamentos para dejar de fumar.'
                          : 'Talk with a doctor before using quit-smoking medicines.',
                      style: const TextStyle(
                        fontFamily: 'Arial',
                        color: AppColors.mutedTeal,
                        fontSize: 9.5,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 76,
                child: Text(
                  isSpanish ? 'Contactar al equipo ›' : 'Contact care team ›',
                  maxLines: 2,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontFamily: 'Arial',
                    color: AppColors.coral,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
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

class _PlanHelpCard extends StatelessWidget {
  const _PlanHelpCard({
    required this.isSpanish,
    required this.onReview,
    required this.onGetHelp,
    required this.onContact,
  });

  final bool isSpanish;
  final VoidCallback onReview;
  final VoidCallback onGetHelp;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F123C37),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _HelpRow(
            key: const ValueKey('medication-plan-review'),
            icon: Icons.add_rounded,
            iconColor: AppColors.deepTeal,
            iconBackground: const Color(0xFFE6F1EA),
            title: isSpanish ? '¿Omitiste o no estás seguro de algo?' : 'Missed or unsure about an item?',
            subtitle: isSpanish
                ? 'Revisa las instrucciones aprobadas o contacta a un profesional clínico o farmacéutico.'
                : 'Review approved instructions or contact a clinician or pharmacist.',
            action: isSpanish ? 'Revisar ›' : 'Review ›',
            actionColor: AppColors.deepTeal,
            onTap: onReview,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Divider(height: 1, color: Color(0xFFE1E9E4)),
          ),
          _HelpRow(
            key: const ValueKey('medication-side-effect-help'),
            icon: Icons.priority_high_rounded,
            iconColor: AppColors.coral,
            iconBackground: const Color(0xFFFFF0EB),
            title: isSpanish ? 'Efecto secundario o síntoma preocupante' : 'Side effect or concerning symptom',
            subtitle: isSpanish
                ? 'Abre la ruta de seguridad aprobada; la app no diagnostica.'
                : 'Open the approved safety route; the app does not diagnose.',
            action: isSpanish ? 'Obtener ayuda ›' : 'Get help ›',
            actionColor: AppColors.coral,
            onTap: onGetHelp,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Divider(height: 1, color: Color(0xFFE1E9E4)),
          ),
          InkWell(
            key: const ValueKey('medication-refill-contact'),
            onTap: onContact,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isSpanish ? '¿Pregunta sobre resurtido?' : 'Refill question?',
                      style: const TextStyle(
                        fontFamily: 'Arial',
                        color: AppColors.mutedTeal,
                        fontSize: 9.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      isSpanish
                          ? 'Contactar farmacia o equipo de atención ›'
                          : 'Contact pharmacy or care team ›',
                      maxLines: 2,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontFamily: 'Arial',
                        color: AppColors.deepTeal,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpRow extends StatelessWidget {
  const _HelpRow({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.actionColor,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final String action;
  final Color actionColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Arial',
                      color: AppColors.deepTeal,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Arial',
                      color: AppColors.mutedTeal,
                      fontSize: 9.2,
                      height: 1.18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 78),
              child: Text(
                action,
                maxLines: 2,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: 'Arial',
                  color: actionColor,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineNote extends StatelessWidget {
  const _OfflineNote({required this.isSpanish});

  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF5F1),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            color: AppColors.mutedTeal,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isSpanish
                  ? 'El plan sigue disponible sin conexión · Última sincronización 9:12 AM'
                  : 'Plan remains available offline · Last synced 9:12 AM',
              style: const TextStyle(
                fontFamily: 'Arial',
                color: AppColors.mutedTeal,
                fontSize: 9,
                height: 1.15,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 82,
            child: Text(
              isSpanish ? 'Aprobado ago 2026' : 'Approved Aug 2026',
              maxLines: 2,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Arial',
                color: AppColors.mutedTeal,
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicationBottomNav extends StatelessWidget {
  const _MedicationBottomNav({
    required this.isSpanish,
    required this.onHome,
    required this.onProgress,
    required this.onLearn,
    required this.onSupport,
  });

  final bool isSpanish;
  final VoidCallback onHome;
  final VoidCallback onProgress;
  final VoidCallback onLearn;
  final VoidCallback onSupport;

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: const BoxDecoration(
          color: AppColors.paper,
          border: Border(top: BorderSide(color: Color(0xFFE1E9E4))),
        ),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BottomNavItem(
              key: const ValueKey('medication-nav-home'),
              icon: Icons.home_outlined,
              label: isSpanish ? 'Inicio' : 'Home',
              onTap: onHome,
            ),
            const _BottomNavItem(
              icon: Icons.description_outlined,
              label: 'Plan',
              selected: true,
              onTap: null,
            ),
            _BottomNavItem(
              key: const ValueKey('medication-nav-progress'),
              icon: Icons.bar_chart_rounded,
              label: isSpanish ? 'Progreso' : 'Progress',
              onTap: onProgress,
            ),
            _BottomNavItem(
              key: const ValueKey('medication-nav-learn'),
              icon: Icons.menu_book_outlined,
              label: isSpanish ? 'Aprender' : 'Learn',
              onTap: onLearn,
            ),
            _BottomNavItem(
              key: const ValueKey('medication-nav-support'),
              icon: Icons.person_outline_rounded,
              label: isSpanish ? 'Apoyo' : 'Support',
              onTap: onSupport,
            ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.deepTeal : AppColors.mutedTeal;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 34,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFE6F1EA) : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Arial',
                color: color,
                fontSize: 9,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  const _StatusOption({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFE6F1EA) : AppColors.cream,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? AppColors.deepTeal : AppColors.border,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.deepTeal, size: 21),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Arial',
                    color: AppColors.deepTeal,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.deepTeal,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
