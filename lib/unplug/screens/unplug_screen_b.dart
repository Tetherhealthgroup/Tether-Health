import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../models/platform_ceiling.dart';
import '../models/unplug_module_state.dart';
import '../widgets/unplug_kit.dart';
import '../widgets/unplug_scope.dart';

/// Screen B — authorization and the app groups the person labels themselves.
///
/// The picker itself is a system component on both platforms and cannot be
/// drawn by Flutter: iOS presents `FamilyActivityPicker`, Android presents its
/// own launcher list. What this screen owns is everything around it — the
/// authorization state, and the labels that are the only names iOS will ever
/// give the module for the apps behind the tokens (addendum §1).
class UnplugScreenB extends StatefulWidget {
  const UnplugScreenB({required this.nav, super.key});

  final UnplugNavigation nav;

  @override
  State<UnplugScreenB> createState() => _UnplugScreenBState();
}

class _UnplugScreenBState extends State<UnplugScreenB> {
  final _labelController = TextEditingController();
  int _appCount = 3;

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _addGroup(UnplugModuleState state) {
    final label = _labelController.text.trim();
    if (label.isEmpty) return;
    state.addGroup(label, _appCount);
    _labelController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final state = UnplugScope.of(context);
    final groups = state.groups;

    return UnplugPage(
      nav: widget.nav,
      children: [
        UnplugSection(
          title: 'Authorization',
          trailing: UnplugPill(
            label: state.authorization.label,
            background: switch (state.authorization) {
              AuthorizationState.approved => AppColors.mint,
              AuthorizationState.notRequested => AppColors.mintStrong,
              AuthorizationState.pending => AppColors.mintStrong,
              AuthorizationState.denied ||
              AuthorizationState.blockedNoFamilySharing =>
                AppColors.coralLight,
            },
            foreground: switch (state.authorization) {
              AuthorizationState.denied ||
              AuthorizationState.blockedNoFamilySharing =>
                const Color(0xFF8C3A26),
              _ => AppColors.deepTeal,
            },
          ),
          child: UnplugCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.platform == TrackedPlatform.ios
                      ? 'requestAuthorization(.individual) presents Apple’s '
                          'Screen Time prompt. The child variant needs an '
                          'iCloud Family and the parent’s Screen Time '
                          'passcode — screen J walks that path.'
                      : 'Usage access and the overlay permission are two '
                          'separate grants, and either can be revoked later '
                          'without telling the app.',
                  style: const TextStyle(
                    color: AppColors.tealSecondary,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: state.authorization.isUsable
                            ? null
                            : state.requestAuthorization,
                        child: const Text('Request authorization'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            state.authorization == AuthorizationState.denied
                                ? null
                                : state.revokeAuthorization,
                        child: const Text('Simulate revoke'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (state.authorization ==
            AuthorizationState.blockedNoFamilySharing)
          const UnplugNote(
            tone: NoteTone.warning,
            text: 'This device is not in an iCloud Family, so a child profile '
                'cannot be shielded on iOS at all. Screen J is the only route '
                'out of this state.',
          ),
        if (state.authorization == AuthorizationState.denied)
          const UnplugNote(
            tone: NoteTone.warning,
            text: 'Nothing is being measured while authorization is denied. '
                'Screen I is what tells the person that, rather than letting '
                'them assume the module is still working.',
          ),
        UnplugSection(
          title: 'Your groups',
          trailing: Text(
            '${state.shieldedAppCount} apps shielded',
            style: const TextStyle(
              color: AppColors.mutedTeal,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: Column(
            children: [
              for (var index = 0; index < groups.length; index++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: UnplugCard(
                    padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                groups[index].label,
                                style: const TextStyle(
                                  color: AppColors.deepTeal,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${groups[index].appCount} apps · '
                                '${groups[index].shielded ? 'shielded' : 'watched only'}',
                                style: const TextStyle(
                                  color: AppColors.mutedTeal,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: groups[index].shielded,
                          onChanged: (_) => state.toggleGroupShield(index),
                        ),
                        IconButton(
                          tooltip: 'Remove ${groups[index].label}',
                          onPressed: () => state.removeGroup(index),
                          icon: const Icon(Icons.close_rounded, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
              UnplugCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Addendum §3.2: a child profile gets no free-text field
                    // anywhere, so the name becomes a choice from a fixed list.
                    if (state.childLockdownActive)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final preset in childSafeGroupLabels)
                            ChoiceChip(
                              label: Text(preset),
                              selected: _labelController.text == preset,
                              showCheckmark: false,
                              backgroundColor: AppColors.paper,
                              selectedColor: AppColors.deepTeal,
                              side: const BorderSide(color: AppColors.border),
                              labelStyle: TextStyle(
                                color: _labelController.text == preset
                                    ? Colors.white
                                    : AppColors.deepTeal,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                              onSelected: (_) =>
                                  setState(() => _labelController.text = preset),
                            ),
                        ],
                      )
                    else
                      TextField(
                        controller: _labelController,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Group name',
                          hintText: 'Video apps',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _addGroup(state),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text(
                          'Apps',
                          style: TextStyle(
                            color: AppColors.deepTeal,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: _appCount.toDouble(),
                            min: 1,
                            max: 12,
                            divisions: 11,
                            label: '$_appCount',
                            onChanged: (value) =>
                                setState(() => _appCount = value.round()),
                          ),
                        ),
                        SizedBox(
                          width: 24,
                          child: Text(
                            '$_appCount',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: AppColors.deepTeal,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonal(
                        onPressed: () => _addGroup(state),
                        child: const Text('Add group'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (state.childLockdownActive)
          const UnplugNote(
            text: 'This is a child profile, so group names are chosen from a '
                'list rather than typed. No screen in the module accepts free '
                'text while it is active.',
          ),
        UnplugNote(
          text: state.platform == TrackedPlatform.ios
              ? 'These labels are the only names the module has for these apps. '
                  'Nothing here identifies an app to Tether, and nothing here '
                  'leaves the device except the group names the person typed.'
              : 'Android could name these apps, and the baseline report on '
                  'screen E will show that detail. The groups still exist so '
                  'the same person keeps the same report if they switch phones.',
        ),
      ],
    );
  }
}
