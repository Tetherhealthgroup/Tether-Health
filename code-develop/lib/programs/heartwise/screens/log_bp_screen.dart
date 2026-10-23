import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../heartwise_controller.dart';
import '../models/bp_reading.dart';

/// Form for logging a blood-pressure reading.
///
/// Systolic and diastolic are individually optional — a missing value stays
/// blank and is never treated as zero.
class LogBpScreen extends StatefulWidget {
  const LogBpScreen({
    required this.controller,
    required this.onSaved,
    this.onClose,
    super.key,
  });

  final HeartwiseController controller;
  final VoidCallback onSaved;
  final VoidCallback? onClose;

  @override
  State<LogBpScreen> createState() => _LogBpScreenState();
}

class _LogBpScreenState extends State<LogBpScreen> {
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _noteController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _save() {
    final error = BpReading.validate(
      systolicText: _systolicController.text,
      diastolicText: _diastolicController.text,
    );
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    final id = widget.controller.addBpReading(
      systolic: _parse(_systolicController.text),
      diastolic: _parse(_diastolicController.text),
      note: _noteController.text,
    );
    if (id == null) {
      setState(() => _error = widget.controller.errorMessage);
      return;
    }
    widget.onSaved();
  }

  static int? _parse(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Log blood pressure'),
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
            TextField(
              controller: _systolicController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Systolic (top number)',
                hintText: 'Leave blank if you only have the bottom number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _diastolicController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Diastolic (bottom number)',
                hintText: 'Leave blank if you only have the top number',
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
              'Missing values stay blank — they are never treated as zero.',
              style: TextStyle(color: AppColors.mutedTeal, fontSize: 12),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Semantics(
                label: 'Error. $_error',
                excludeSemantics: true,
                child: Text(
                  _error!,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Semantics(
              label: 'Save blood pressure reading',
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
