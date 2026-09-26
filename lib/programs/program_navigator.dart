import 'dart:async';

import 'package:flutter/material.dart';

import '../auth/account_controller.dart';
import '../theme/app_colors.dart';
import '../widgets/profile_avatar.dart';
import 'clearair/clearair_controller.dart';
import 'clearair/screens/clearair_home_screen.dart';
import 'clearair/screens/red_zone_screen.dart';
import 'clearair/screens/zone_check_screen.dart';
import 'heartwise/heartwise_controller.dart';
import 'heartwise/screens/cholesterol_panel_screen.dart';
import 'heartwise/screens/heartwise_home_screen.dart';
import 'heartwise/screens/log_bp_screen.dart';
import 'program.dart';
import 'secure_program_store.dart';
import 'steady/screens/log_reading_screen.dart';
import 'steady/screens/meal_energy_reset_screen.dart';
import 'steady/screens/steady_home_screen.dart';
import 'steady/steady_controller.dart';

class ProgramSelectionScreen extends StatelessWidget {
  const ProgramSelectionScreen({
    required this.account,
    required this.onSelect,
    super.key,
  });

  final AccountController account;
  final ValueChanged<ProgramId?> onSelect;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Tether Health programs')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              ProfileAvatar(
                identity: ProfileIdentity(
                  signedIn: account.isSignedIn,
                  displayName: account.profile?.displayName,
                  email: account.email,
                  avatarUrl: account.profile?.avatarUrl,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  account.profile?.displayName ?? account.email ?? 'Guest',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _ProgramTile(
            title: 'BreatheFree',
            subtitle: 'Smoking-cessation support',
            icon: Icons.air_rounded,
            onTap: () => onSelect(null),
          ),
          for (final spec in programSpecs.values)
            _ProgramTile(
              title: spec.name,
              subtitle: spec.tagline,
              icon: switch (spec.id) {
                ProgramId.heartwise => Icons.favorite_outline,
                ProgramId.steady => Icons.monitor_heart_outlined,
                ProgramId.clearAir => Icons.air_rounded,
              },
              onTap: () => onSelect(spec.id),
            ),
        ],
      ),
    );
  }
}

class _ProgramTile extends StatelessWidget {
  const _ProgramTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Icon(icon, color: AppColors.deepTeal),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
}

class ProgramNavigator extends StatefulWidget {
  const ProgramNavigator({
    required this.programId,
    required this.account,
    required this.store,
    required this.onChooseProgram,
    super.key,
  });

  final ProgramId programId;
  final AccountController account;
  final SecureProgramStore store;
  final VoidCallback onChooseProgram;

  @override
  State<ProgramNavigator> createState() => _ProgramNavigatorState();
}

class _ProgramNavigatorState extends State<ProgramNavigator> {
  late final HeartwiseController _heartwise;
  late final SteadyController _steady;
  late final ClearAirController _clearAir;
  bool _loading = true;
  bool _offline = false;
  int _revision = 0;
  Timer? _saveTimer;

  String get _scope => widget.account.accountId ?? 'guest';

  @override
  void initState() {
    super.initState();
    _heartwise = HeartwiseController();
    _steady = SteadyController();
    _clearAir = ClearAirController();
    _controller.addListener(_scheduleSave);
    unawaited(_load());
  }

  ProgramController get _controller => switch (widget.programId) {
        ProgramId.heartwise => _heartwise,
        ProgramId.steady => _steady,
        ProgramId.clearAir => _clearAir,
      };

  Map<String, Object?> get _payload => switch (widget.programId) {
        ProgramId.heartwise => _heartwise.toJson(),
        ProgramId.steady => _steady.toJson(),
        ProgramId.clearAir => _clearAir.toJson(),
      };

  Future<void> _load() async {
    try {
      final document = await widget.store.load(
        accountScope: _scope,
        programId: widget.programId,
        accessToken: widget.account.accessToken,
      );
      if (document != null) {
        _revision = document.revision;
        switch (widget.programId) {
          case ProgramId.heartwise:
            _heartwise.restore(document.payload);
          case ProgramId.steady:
            _steady.restore(document.payload);
          case ProgramId.clearAir:
            _clearAir.restore(document.payload);
        }
      }
    } catch (_) {
      _offline = true;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scheduleSave() {
    if (_loading) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 350), _save);
  }

  Future<void> _save() async {
    final synced = await widget.store.save(
      accountScope: _scope,
      programId: widget.programId,
      payload: _payload,
      revision: ++_revision,
      accessToken: widget.account.accessToken,
    );
    if (mounted && _offline == synced) {
      setState(() => _offline = !synced);
    }
  }

  @override
  void dispose() {
    final savePending = _saveTimer?.isActive ?? false;
    _saveTimer?.cancel();
    if (savePending) unawaited(_save());
    _controller.removeListener(_scheduleSave);
    _heartwise.dispose();
    _steady.dispose();
    _clearAir.dispose();
    super.dispose();
  }

  Future<void> _push(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Center(
          child: Semantics(
            label: 'Loading program data',
            child: const CircularProgressIndicator(),
          ),
        ),
      );
    }
    final home = switch (widget.programId) {
      ProgramId.heartwise => HeartwiseHomeScreen(
          controller: _heartwise,
          onLogBp: () => _push(LogBpScreen(
            controller: _heartwise,
            onSaved: () => Navigator.pop(context),
          )),
          onOpenCholesterol: () => _push(CholesterolPanelScreen(
            controller: _heartwise,
          )),
        ),
      ProgramId.steady => SteadyHomeScreen(
          controller: _steady,
          onLogReading: () => _push(LogReadingScreen(
            controller: _steady,
            onSaved: () => Navigator.pop(context),
          )),
          onOpenReset: () => _push(MealEnergyResetScreen(
            onDone: () => Navigator.pop(context),
          )),
        ),
      ProgramId.clearAir => ClearAirHomeScreen(
          controller: _clearAir,
          onZoneCheck: () => _push(ZoneCheckScreen(
            controller: _clearAir,
            onCompleted: (_) => Navigator.pop(context),
          )),
          onOpenRedZone: () => _push(const RedZoneScreen()),
        ),
    };
    return Stack(
      children: [
        home,
        Positioned(
          right: 12,
          top: MediaQuery.paddingOf(context).top + 8,
          child: Row(
            children: [
              if (_offline)
                const Tooltip(
                  message: 'Saved securely on this device; sync will retry.',
                  child: Icon(Icons.cloud_off_outlined),
                ),
              IconButton(
                tooltip: 'Choose program',
                onPressed: widget.onChooseProgram,
                icon: const Icon(Icons.apps_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
