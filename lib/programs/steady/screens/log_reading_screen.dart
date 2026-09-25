import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../models/glucose_reading.dart';
import '../steady_controller.dart';

/// Form for logging a glucose reading.
///
/// HARD RULE: there are no calorie fields anywhere on this screen — no
/// calorie counting, no food-calorie inputs. The value itself is optional:
/// a missing reading stays missing, never zero.
class LogReadingScreen extends StatefulWidget {
  const LogReadingScreen({
    required this.controller,
    required this.onSaved,
    this.onClose,
    super.key,
  });

  final SteadyController controller;
  final VoidCallback onSaved;
  final VoidCallback? onClose;

  @override
  State<LogReadingScreen> createState() => _LogReadingScreenState();
}

class _LogReadingScreenState extends State<LogReadingScreen> {
  final _valueController = TextEditingController();
  final _noteController = TextEditingController();
  GlucoseContext _context = GlucoseContext.fasting;
  String? _error;

  @override
  void dispose() {
    _valueController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _save() {
    final error = GlucoseReading.validateValue(_valueController.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    final raw = _valueController.text.trim();
    final id = widget.controller.addReading(
      valueMgDl: raw.isEmpty ? null : int.parse(raw),
      context: _context,
      note: _noteController.text,
    );
    if (id == null) {
      setState(() => _error = widget.controller.errorMessage);
      return;
    }
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Log a reading'),
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            const Text(
              'When was this reading taken?',
              style: TextStyle(
                color: AppColors.deepTeal,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            RadioGroup<GlucoseContext>(
              groupValue: _context,
              onChanged: (value) {
                if (value != null) setState(() => _context = value);
              },
              child: Column(
                children: [
                  for (final context in GlucoseContext.values)
                    RadioListTile<GlucoseContext>(
                      title: Text(context.label),
                      value: context,
                      activeColor: AppColors.deepTeal,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _valueController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Reading (mg/dL)',
                hintText: 'Leave blank if you did not take a reading',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'A missing reading stays missing — it is never treated as zero.',
              style: TextStyle(color: AppColors.mutedTeal, fontSize: 12),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Semantics(
                label: 'Error. $_error',
                excludeSemantics: true,
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Semantics(
              label: 'Save glucose reading',
              button: true,
              excludeSemantics: true,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.deepTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Save reading'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
