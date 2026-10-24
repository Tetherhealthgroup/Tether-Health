import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../heartwise_controller.dart';
import '../models/cholesterol_panel.dart';

/// Views recorded cholesterol panels and adds new ones.
///
/// Panels are "lab or clinician provided" — the screen shows the source
/// note and never grades values.
class CholesterolPanelScreen extends StatefulWidget {
  const CholesterolPanelScreen({
    required this.controller,
    this.onClose,
    super.key,
  });

  final HeartwiseController controller;
  final VoidCallback? onClose;

  @override
  State<CholesterolPanelScreen> createState() =>
      _CholesterolPanelScreenState();
}

class _CholesterolPanelScreenState extends State<CholesterolPanelScreen> {
  final _ldlController = TextEditingController();
  final _hdlController = TextEditingController();
  final _triglyceridesController = TextEditingController();
  final _totalController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _ldlController.dispose();
    _hdlController.dispose();
    _triglyceridesController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  void _save() {
    final error = CholesterolPanel.validate(
      ldlText: _ldlController.text,
      hdlText: _hdlController.text,
      triglyceridesText: _triglyceridesController.text,
      totalText: _totalController.text,
    );
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    final id = widget.controller.addCholesterolPanel(
      ldlMgDl: _parse(_ldlController.text),
      hdlMgDl: _parse(_hdlController.text),
      triglyceridesMgDl: _parse(_triglyceridesController.text),
      totalMgDl: _parse(_totalController.text),
    );
    if (id == null) {
      setState(() => _error = widget.controller.errorMessage);
      return;
    }
    for (final controller in [
      _ldlController,
      _hdlController,
      _triglyceridesController,
      _totalController,
    ]) {
      controller.clear();
    }
    setState(() => _error = null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Panel saved.')),
    );
  }

  static double? _parse(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Cholesterol panel'),
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.deepTeal,
        leading: widget.onClose == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: widget.onClose,
                tooltip: 'Back',
              ),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final panels = widget.controller.cholesterolPanels;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                if (panels.isEmpty)
                  const Card(
                    color: AppColors.paper,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No panels yet. Add one from your lab results whenever you have them.',
                        style: TextStyle(color: AppColors.tealSecondary),
                      ),
                    ),
                  )
                else ...[
                  _PanelCard(panel: panels.last, title: 'Latest panel'),
                  const SizedBox(height: 8),
                  for (final panel in panels.reversed.skip(1))
                    _PanelCard(panel: panel, title: 'Earlier panel'),
                  const SizedBox(height: 8),
                ],
                const Card(
                  color: AppColors.mint,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Panels come from your lab results or clinician — enter them as written. Values are information, never a grade.',
                      style: TextStyle(color: AppColors.tealSecondary),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Add a panel',
                  style: TextStyle(
                    color: AppColors.deepTeal,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                _NumberField(
                  controller: _ldlController,
                  label: 'LDL (mg/dL)',
                ),
                const SizedBox(height: 12),
                _NumberField(
                  controller: _hdlController,
                  label: 'HDL (mg/dL)',
                ),
                const SizedBox(height: 12),
                _NumberField(
                  controller: _triglyceridesController,
                  label: 'Triglycerides (mg/dL)',
                ),
                const SizedBox(height: 12),
                _NumberField(
                  controller: _totalController,
                  label: 'Total cholesterol (mg/dL)',
                ),
                const SizedBox(height: 8),
                const Text(
                  'Missing values stay blank — they are never treated as zero.',
                  style: TextStyle(
                    color: AppColors.mutedTeal,
                    fontSize: 12,
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Semantics(
                    label: 'Error. $_error',
                    excludeSemantics: true,
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Semantics(
                  label: 'Save cholesterol panel',
                  button: true,
                  excludeSemantics: true,
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.deepTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Save panel'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
  });

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.panel, required this.title});

  final CholesterolPanel panel;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.paper,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.deepTeal,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            _value('LDL', panel.ldlMgDl),
            _value('HDL', panel.hdlMgDl),
            _value('Triglycerides', panel.triglyceridesMgDl),
            _value('Total', panel.totalMgDl),
            const SizedBox(height: 8),
            Text(
              panel.source,
              style: const TextStyle(
                color: AppColors.mutedTeal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Values are displayed as data only — never graded.
  Widget _value(String label, double? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '$label: ${value == null ? '—' : value.toString()} mg/dL',
        style: const TextStyle(color: AppColors.tealSecondary),
      ),
    );
  }
}
